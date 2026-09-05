import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../app/widgets/app_card.dart';
import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../models/transaction.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';

/// Charts, replacing the Recharts donut and grouped bars in
/// `FinancialCharts.tsx`.
///
/// Series colours come from the explicit grey ramp below rather than from
/// `ColorScheme` roles. Under a monochrome palette those roles collapse onto
/// each other, so a chart is one of the few places that has to name its own
/// values — see [_sliceRamp].
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();

    final top = finance.expensesByCategory().take(5).toList();
    final total = top.fold(0.0, (sum, e) => sum + e.value);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.chartTopCategories, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (top.isEmpty || total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.chartNoExpenses,
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
                        color: _sliceColor(i),
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
                        color: _sliceColor(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryLabel(l10n, top[i].key),
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
    );
  }
}

/// The grey ramp the donut's slices are drawn from.
///
/// This used to pull five `ColorScheme` roles and rely on hue to separate them.
/// That cannot work here: the roles now resolve to two or three greys plus the
/// error red, so four of five slices would be the same colour and the fifth
/// would be the only red thing on the page — spending a reserved signal on
/// decoration.
///
/// So the ramp is explicit and lightness-only, which is the honest way to
/// separate categories without hue. The steps are ordered light-to-dark rather
/// than alternating: a monotonic ramp reads as a *scale* — biggest category
/// darkest — which is information the alternating order threw away, and every
/// adjacent pair is still far enough apart to tell apart.
///
/// The lightest step stops at #ADADAD — 2.2:1 against the white card behind
/// it. Continuing the ramp evenly to near-white would put the fifth slice at
/// about 1.5:1, which is the same "effectively invisible" failure the previous
/// palette had, just in grey instead of lavender.
const _sliceRamp = [
  AppColors.ink, // #000000
  Color(0xFF333333),
  Color(0xFF5C5C5C),
  Color(0xFF858585),
  Color(0xFFADADAD),
];

/// The two series on the income-vs-expenses chart.
///
/// Expenses are grey, not the error red. Spending money is not an error, and
/// the one reserved colour in this app has to keep meaning "this is wrong" or
/// it stops meaning anything — a bar chart that paints half its bars red every
/// month is exactly how that erodes. 3.5:1 between the two, so the pair is
/// separable without relying on the legend.
const _incomeBar = AppColors.ink;
const _expenseBar = Color(0xFF858585);

/// Colour for slice [index], lightening further if a chart ever exceeds the
/// ramp. The donut is capped at five, so the wrap is a guard, not a path.
Color _sliceColor(int index) {
  final color = _sliceRamp[index % _sliceRamp.length];
  final steps = index ~/ _sliceRamp.length;
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();

    final months = _lastSixMonths(finance.transactions);
    final maxValue = months.fold<double>(
      0,
      (m, e) => [m, e.income, e.expense].reduce((a, b) => a > b ? a : b),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.chartIncomeVsExpenses, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.chartLastSixMonths, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          if (maxValue <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.chartNotEnoughHistory,
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
                              shortMonthName(l10n, months[i].month),
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
                            color: _incomeBar,
                            width: 8,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: months[i].expense,
                            color: _expenseBar,
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
                color: _incomeBar,
                label: l10n.chartLegendIncome,
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: _expenseBar,
                label: l10n.chartLegendExpenses,
              ),
            ],
          ),
        ],
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
  const _MonthTotals(this.month, this.income, this.expense);

  /// 1-12. The axis label is resolved from this at paint time, so the chart
  /// re-reads in the active language without rebucketing.
  final int month;
  final double income;
  final double expense;
}

/// Buckets the last six calendar months, oldest first.
List<_MonthTotals> _lastSixMonths(List<FinanceTransaction> transactions) {
  final now = DateTime.now();
  final buckets = <String, ({double income, double expense})>{};
  final order = <String>[];
  final months = <String, int>{};

  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    // Zero-padded to match the ISO `yyyy-MM` prefix the loop below slices out
    // of each transaction's date.
    final key = '${m.year.toString().padLeft(4, '0')}-'
        '${m.month.toString().padLeft(2, '0')}';
    order.add(key);
    months[key] = m.month;
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
      _MonthTotals(months[key]!, buckets[key]!.income, buckets[key]!.expense),
  ];
}
