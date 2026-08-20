import 'package:cash_compass/logic/budget_math.dart';
import 'package:cash_compass/logic/insights.dart';
import 'package:cash_compass/logic/subscriptions.dart';
import 'package:cash_compass/models/budget_category.dart';
import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Measures the derived computations the dashboard runs while building.
///
/// Nothing here is cached today: each card calls its own logic function on
/// every rebuild, and most cards `watch` FinanceProvider, so adding a single
/// transaction re-runs all of it.
void main() {
  List<FinanceTransaction> make(int n) {
    final today = DateTime.now();
    return [
      for (var i = 0; i < n; i++)
        FinanceTransaction(
          id: 'bench-$i',
          name: ['Lunch', 'Netflix', 'Bus', 'Groceries'][i % 4],
          amount: 5.0 + (i % 40),
          type: i % 6 == 0 ? TransactionType.income : TransactionType.expense,
          category: ['Food', 'Transport', 'Housing', 'Entertainment'][i % 4],
          date: _iso(today.subtract(Duration(days: i % 120))),
          createdAt: today.subtract(Duration(days: i % 120)).toIso8601String(),
          isUnplanned: i % 11 == 0,
          reasonTags: i % 11 == 0 ? const [ReasonTag.social] : const [],
        ),
    ];
  }

  const goals = [
    SavingsGoal(
      id: 'g1',
      name: 'Trip to Goa',
      current: 300,
      target: 1000,
      icon: '*',
    ),
  ];
  const budgets = [
    BudgetCategory(id: 'b1', name: 'Food', monthlyLimit: 200),
  ];

  /// Everything one dashboard build currently triggers across its cards.
  void oneDashboardBuild(List<FinanceTransaction> txs) {
    averageSpentPerDay(dailyRecords(txs)); // stat grid
    dailyRecords(txs); // day records card
    dailySuggestions(
      // suggestions card (re-derives the average)
      selectedDayRemaining: 20,
      selectedDayPlanned: 10,
      dailyBudget: 50,
      averagePerDay: averageSpentPerDay(dailyRecords(txs)),
    );
    smartCard(transactions: txs, goals: goals, dailyLimit: 50);
    behaviorInsight(txs);
    smartSuggestions(transactions: txs, budgets: budgets);
    detectSubscriptions(txs); // recurring charges card
    detectSubscriptions(txs); // waste auditor widget repeats it
    goalInsights(txs);
  }

  for (final n in [200, 1000, 5000]) {
    test('derived cost with $n transactions', () {
      final txs = make(n);
      oneDashboardBuild(txs); // warm up

      void time(String label, void Function() body, {int reps = 20}) {
        final sw = Stopwatch()..start();
        for (var i = 0; i < reps; i++) {
          body();
        }
        sw.stop();
        final per = sw.elapsedMicroseconds / reps;
        // ignore: avoid_print
        print('  $label: ${(per / 1000).toStringAsFixed(2)}ms');
      }

      // ignore: avoid_print
      print('\n=== $n transactions ===');
      time('detectSubscriptions', () => detectSubscriptions(txs));
      time('dailyRecords', () => dailyRecords(txs));
      time('smartSuggestions',
          () => smartSuggestions(transactions: txs, budgets: budgets));
      time('behaviorInsight', () => behaviorInsight(txs));
      time('goalInsights', () => goalInsights(txs));
      time('ONE DASHBOARD BUILD', () => oneDashboardBuild(txs), reps: 10);

      expect(txs, hasLength(n));
    });
  }
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
