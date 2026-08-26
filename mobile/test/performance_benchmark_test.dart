import 'dart:convert';

import 'package:cash_compass/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Measures the cost of the hot paths before optimisation, so the numbers in
/// the perf work are evidence rather than guesswork.
///
/// Run with: flutter test test/performance_benchmark_test.dart
void main() {
  List<FinanceTransaction> makeTransactions(int n) {
    final start = DateTime(2024, 1, 1);
    return List.generate(n, (i) {
      final d = start.add(Duration(days: i % 730));
      return FinanceTransaction(
        id: 'tx-$i',
        name: 'Entry $i',
        amount: 4.5 + (i % 50),
        type: i % 5 == 0 ? TransactionType.income : TransactionType.expense,
        category: ['Food', 'Transport', 'Housing', 'Shopping'][i % 4],
        date: '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}',
        createdAt: d.toIso8601String(),
      );
    });
  }

  /// Mirrors what one DashboardTab build currently costs: four independent
  /// full scans of the transaction list, one per stat card.
  int fourFullScans(List<FinanceTransaction> txs, String today) {
    final totalSpent =
        txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final totalIncome =
        txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final spentToday = txs
        .where((t) => t.isExpense && t.date == today)
        .fold(0.0, (s, t) => s + t.amount);
    // availableBalance internally recomputes totalSpent a second time.
    final available =
        txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    return [totalSpent, totalIncome, spentToday, available].length;
  }

  void report(String label, int micros, {int? per}) {
    final ms = micros / 1000;
    final suffix =
        per == null ? '' : ' (${(micros / per).toStringAsFixed(1)}µs each)';
    // ignore: avoid_print
    print('  $label: ${ms.toStringAsFixed(2)}ms$suffix');
  }

  for (final n in [500, 2000, 5000]) {
    test('benchmark with $n transactions', () {
      final txs = makeTransactions(n);
      const today = '2024-06-01';

      // Warm up so we are not timing first-call JIT.
      fourFullScans(txs, today);
      jsonEncode(txs.map((t) => t.toJson()).toList());

      // ignore: avoid_print
      print('\n=== $n transactions ===');

      final sw = Stopwatch()..start();
      for (var i = 0; i < 60; i++) {
        fourFullScans(txs, today);
      }
      sw.stop();
      report('60 rebuilds of the stat row', sw.elapsedMicroseconds, per: 60);

      sw
        ..reset()
        ..start();
      final encoded = jsonEncode({
        'startingBalance': 0.0,
        'transactions': txs.map((t) => t.toJson()).toList(),
        'goals': const [],
        'budgets': const [],
      });
      sw.stop();
      report('jsonEncode full state (per mutation)', sw.elapsedMicroseconds);
      // ignore: avoid_print
      print('  encoded size: ${(encoded.length / 1024).toStringAsFixed(1)} KB');

      sw
        ..reset()
        ..start();
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final parsed = (decoded['transactions'] as List)
          .map((e) => FinanceTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
      sw.stop();
      report('jsonDecode + parse (startup)', sw.elapsedMicroseconds);
      expect(parsed.length, n);
    });
  }
}
