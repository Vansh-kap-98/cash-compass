import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/screens/tabs/dashboard_tab.dart';
import 'package:cash_compass/state/finance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Balance must be correct because of how it is derived, not because something
/// pushed it after a save.
///
/// Reported as "the balance doesn't update in real time". The propagation
/// machinery turned out to be fine — the store recomputes on every mutation,
/// bumps a revision, and notifies; the dashboard watches it. The real defect
/// was in the formula: `availableBalance` subtracted expenses but ignored
/// income, so recording a salary moved nothing on screen while recording a
/// coffee did.
///
/// The store is mutated directly here rather than driven through the UI. That
/// is deliberate: it isolates derivation from any single entry point, so the
/// guarantee holds for the Add Entry sheet, the Quick-Entry Pad, the
/// receipt-scan flow, and anything added later.
void main() {
  /// Every number currently on screen, so a change anywhere is visible.
  Set<String> renderedNumbers(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => s.contains(RegExp(r'\d')))
      .toSet();

  /// Renders the dashboard, applies [mutate], and reports the numbers on screen
  /// before and after — with no navigation and no manual refresh between them.
  Future<({Set<String> before, Set<String> after})> aroundMutation(
    WidgetTester tester,
    void Function(FinanceProvider finance) mutate,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final stores = TestStores.populated();
    await tester.pumpWidget(wrapForTest(const DashboardTab(), stores: stores));
    await tester.pump(const Duration(milliseconds: 600));

    final before = renderedNumbers(tester);
    mutate(stores.finance);
    // A single frame. If a number only appears after a longer settle, or after
    // leaving the screen and coming back, that is the bug this guards against.
    await tester.pump();
    final after = renderedNumbers(tester);

    // Let the debounced persist timer fire before the tree goes away; the
    // framework fails any test that disposes with a timer still pending.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox.shrink());

    return (before: before, after: after);
  }

  group('the dashboard reacts in the same frame', () {
    testWidgets('to a new expense', (tester) async {
      final r = await aroundMutation(
        tester,
        (finance) => finance.addTransaction(
          name: 'Reactivity probe',
          amount: 4242.42,
          type: TransactionType.expense,
          category: 'Food',
          date: isoDate(DateTime.now()),
        ),
      );

      expect(
        r.after,
        isNot(equals(r.before)),
        reason: 'an expense must change the dashboard without navigating away',
      );
    });

    testWidgets('to new income', (tester) async {
      final r = await aroundMutation(
        tester,
        (finance) => finance.addTransaction(
          name: 'Income probe',
          amount: 9999.99,
          type: TransactionType.income,
          category: 'Salary',
          date: isoDate(DateTime.now()),
        ),
      );

      expect(
        r.after,
        isNot(equals(r.before)),
        reason: 'income used to change nothing on screen — availableBalance '
            'subtracted expenses but ignored income entirely',
      );
    });
  });

  group('availableBalance is derived from the whole ledger', () {
    late FinanceProvider finance;

    setUp(() {
      finance = TestStores.empty().finance;
      finance.setManualSnapshot(balance: 1000);
    });

    void add(double amount, TransactionType type) => finance.addTransaction(
          name: 'x',
          amount: amount,
          type: type,
          category: type == TransactionType.expense ? 'Food' : 'Salary',
          date: isoDate(DateTime.now()),
        );

    test('starts at the snapshot', () {
      expect(finance.availableBalance, 1000);
    });

    test('an expense subtracts', () {
      add(200, TransactionType.expense);
      expect(finance.availableBalance, 800);
    });

    test('income adds', () {
      add(500, TransactionType.income);
      expect(
        finance.availableBalance,
        1500,
        reason: 'the snapshot is a point in time; later income adjusts it '
            'exactly as later spending does',
      );
    });

    test('both together', () {
      add(500, TransactionType.income);
      add(200, TransactionType.expense);
      expect(finance.availableBalance, 1300);
    });

    test('never goes negative', () {
      add(5000, TransactionType.expense);
      expect(finance.availableBalance, 0);
    });
  });

  group('the store propagates every mutation', () {
    test('aggregates move the instant a transaction lands', () {
      final finance = TestStores.empty().finance;

      finance.addTransaction(
        name: 'Lunch',
        amount: 12.50,
        type: TransactionType.expense,
        category: 'Food',
        date: isoDate(DateTime.now()),
      );
      expect(finance.totalSpent, 12.50);

      finance.addTransaction(
        name: 'Pay',
        amount: 100,
        type: TransactionType.income,
        category: 'Salary',
        date: isoDate(DateTime.now()),
      );
      expect(finance.totalIncome, 100);
      expect(finance.totalSpent, 12.50, reason: 'income must not touch spend');
    });

    test('memoised aggregates invalidate on mutation', () {
      final finance = TestStores.empty().finance;
      final firstRead = finance.dailyRecordsByDay;

      finance.addTransaction(
        name: 'Bus',
        amount: 2,
        type: TransactionType.expense,
        category: 'Transport',
        date: isoDate(DateTime.now()),
      );

      expect(
        finance.dailyRecordsByDay,
        isNot(same(firstRead)),
        reason: 'a memo keyed on revision must not survive a mutation',
      );
    });

    // NOTE: transactions can only be added — there is no edit or delete yet.
    // When those land they must go through the same `_persist()` path, and this
    // test should grow to cover them.
    test('every mutator notifies exactly once', () {
      final finance = TestStores.empty().finance;
      var notifications = 0;
      finance.addListener(() => notifications++);

      finance.addTransaction(
        name: 'A',
        amount: 1,
        type: TransactionType.expense,
        category: 'Food',
        date: isoDate(DateTime.now()),
      );
      finance.addGoal(name: 'G', target: 100);
      finance.upsertBudget('Food', 50);
      finance.setManualSnapshot(balance: 500);

      expect(
        notifications,
        4,
        reason: 'no entry point may mutate state without notifying — none of '
            'them touch the transaction list directly',
      );
    });
  });
}
