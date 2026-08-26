import 'package:cash_compass/screens/tabs/dashboard_tab.dart';
import 'package:cash_compass/state/currency_provider.dart';
import 'package:cash_compass/widgets/add_entry_sheet.dart';
import 'package:cash_compass/widgets/set_goal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Exercises the entry sheets end to end.
///
/// The conversion boundary is the single most load-bearing rule in the app:
/// the user types in whatever currency they have selected, and everything is
/// stored in USD. Get it wrong and every figure downstream is wrong.
void main() {
  /// The sheets scroll their content in a lazily-built `ListView`, so on a
  /// short test viewport the lower fields are never constructed and cannot be
  /// tapped or found. A tall viewport puts the whole form on screen, which is
  /// what these tests are actually about.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// A host screen that opens the sheet, so the real `showModalBottomSheet`
  /// path is exercised rather than the sheet being rendered in isolation.
  Widget host(Future<void> Function(BuildContext) open) {
    return Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    );
  }

  testWidgets('an amount typed in INR is stored as USD', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();
    // Fallback rate is 83.5 INR to the dollar, so 835 in should be 10 out.
    await stores.currency.setCurrency(AppCurrency.inr);

    await tester.pumpWidget(
      wrapForTest(host(AddEntrySheet.show), stores: stores),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Groceries');
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (INR)'),
      '835',
    );
    await tester.pump();

    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();

    expect(stores.finance.transactions, hasLength(1));
    final saved = stores.finance.transactions.first;
    expect(saved.name, 'Groceries');
    expect(
      saved.amount,
      closeTo(10.0, 0.01),
      reason: '835 INR at 83.5 to the dollar must persist as 10 USD',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an invalid entry is rejected with a message', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    await tester.pumpWidget(
      wrapForTest(host(AddEntrySheet.show), stores: stores),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // No name, no amount.
    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();

    expect(stores.finance.transactions, isEmpty);
    expect(
      find.text('Save Entry'),
      findsOneWidget,
      reason: 'an invalid entry must leave the sheet open, not close it',
    );

    // Surfaced as a snack bar, so it is visible without scrolling to the end
    // of the form — which is where the inline copy of the message lives.
    expect(
      find.widgetWithText(
          SnackBar, 'Please provide a name and a valid amount.'),
      findsOneWidget,
      reason: 'the user must be told why nothing was saved',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('recurrence is recorded on the saved entry', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    await tester.pumpWidget(
      wrapForTest(host(AddEntrySheet.show), stores: stores),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Netflix');
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (USD)'),
      '15.99',
    );
    await tester.tap(find.text('Monthly'));
    await tester.pump();

    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();

    expect(stores.finance.transactions, hasLength(1));
    expect(
      stores.finance.transactions.first.note,
      contains('Recurring: monthly'),
      reason: 'the subscription detector reads recurrence from the note',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the balance field reconverts when the currency changes',
      (tester) async {
    // Regression guard: the field was populated once in initState, so
    // switching currency relabelled it without reconverting the number — the
    // field said "₹100.00" while holding a USD figure.
    useTallViewport(tester);
    final stores = TestStores.empty();
    stores.finance.replaceAll(manualBalance: 100);

    await tester.pumpWidget(
      wrapForTest(const DashboardTab(), stores: stores),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.widgetWithText(TextField, '100.00'), findsOneWidget);

    await stores.currency.setCurrency(AppCurrency.inr);
    await tester.pump();

    expect(
      find.widgetWithText(TextField, '8350.00'),
      findsOneWidget,
      reason: '100 USD shown in INR must read 8350, not 100',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a goal target typed in INR is stored as USD', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();
    await stores.currency.setCurrency(AppCurrency.inr);

    await tester.pumpWidget(
      wrapForTest(host(SetGoalSheet.show), stores: stores),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Goal name'),
      'Trip',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Target (INR)'),
      '8350',
    );
    await tester.pump();

    await tester.tap(find.text('Create Goal'));
    await tester.pumpAndSettle();

    expect(stores.finance.goals, hasLength(1));
    expect(
      stores.finance.goals.first.target,
      closeTo(100.0, 0.01),
      reason: '8350 INR at 83.5 to the dollar must persist as 100 USD',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
