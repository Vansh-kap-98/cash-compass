import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';

/// Charts, replacing the Recharts donut and grouped bars in
/// `FinancialCharts.tsx`.
///
/// Colours come from the active theme rather than a fixed palette, so all five
/// themes stay coherent.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();

    final top = finance.expensesByCategory().take(5).toList();
    final total = top.fold(0.0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top categories', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (top.isEmpty || total <= 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No expenses yet.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else ...[
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: [
                      for (var i = 0; i < top.length; i++)
                        PieChartSectionData(
                          value: top[i].value,
                          color: _sliceColor(theme, i),
                          radius: 34,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < top.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _sliceColor(theme, i),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          top[i].key,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${(top[i].value / total * 100).round()}%  '
                        '${currency.formatFromUsd(top[i].value)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Derives a readable series of slice colours from the theme.
Color _sliceColor(ThemeData theme, int index) {
  final base = [
    theme.colorScheme.primary,
    theme.colorScheme.secondary,
    theme.colorScheme.error,
    theme.colorScheme.tertiary,
    theme.colorScheme.outline,
  ];
  final color = base[index % base.length];
  // Nudge lightness so repeated colours stay distinguishable if the palette
  // ever wraps.
  final steps = index ~/ base.length;
  if (steps == 0) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + 0.12 * steps).clamp(0.0, 1.0))
      .toColor();
}

/// Six months of income against expenses.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();

    final months = _lastSixMonths(finance.transactions);
    final maxValue = months.fold<double>(
      0,
      (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs expenses', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Last six months', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (maxValue <= 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Not enough history yet.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= months.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                months[i].label,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          currency.formatFromUsd(rod.toY),
                          theme.textTheme.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < months.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: months[i].income,
                              color: theme.colorScheme.primary,
                              width: 8,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            BarChartRodData(
                              toY: months[i].expense,
                              color: theme.colorScheme.error,
                              width: 8,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                  color: theme.colorScheme.primary,
                  label: 'Income',
                ),
                const SizedBox(width: 16),
                _LegendDot(
                  color: theme.colorScheme.error,
                  label: 'Expenses',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MonthTotals {
  const _MonthTotals(this.label, this.income, this.expense);
  final String label;
  final double income;
  final double expense;
}

const _monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Buckets the last six calendar months, oldest first.
List<_MonthTotals> _lastSixMonths(List<FinanceTransaction> transactions) {
  final now = DateTime.now();
  final buckets = <String, ({double income, double expense})>{};
  final order = <String>[];
  final labels = <String, String>{};

  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    // Zero-padded to match the ISO `yyyy-MM` prefix the loop below slices out
    // of each transaction's date.
    final key = '${m.year.toString().padLeft(4, '0')}-'
        '${m.month.toString().padLeft(2, '0')}';
    order.add(key);
    labels[key] = _monthLabels[m.month - 1];
    buckets[key] = (income: 0, expense: 0);
  }

  for (final t in transactions) {
    // Key off the ISO date's `yyyy-MM` prefix instead of parsing it — this
    // walks every transaction and the parse dominated the pass.
    if (t.date.length < 7) continue;
    final key = t.date.substring(0, 7);
    final bucket = buckets[key];
    if (bucket == null) continue;
    buckets[key] = t.isExpense
        ? (income: bucket.income, expense: bucket.expense + t.amount)
        : (income: bucket.income + t.amount, expense: bucket.expense);
  }

  return [
    for (final key in order)
      _MonthTotals(labels[key]!, buckets[key]!.income, buckets[key]!.expense),
  ];
}
