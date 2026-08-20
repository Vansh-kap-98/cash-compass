import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/budget_math.dart';
import '../../models/transaction.dart';
import '../../models/workspace_widget.dart';
import '../../services/image_store.dart';
import '../../state/budget_plan_provider.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';
import '../../state/planner_provider.dart';
import '../../state/workspace_provider.dart';

/// Builds the body for a workspace widget.
///
/// The Flutter equivalent of the React switch: adding a type means adding one
/// case here plus one enum value.
Widget buildWidgetBody(BuildContext context, WorkspaceWidget widget) {
  return switch (widget.type) {
    WorkspaceWidgetType.todaySnapshot => const _TodaySnapshot(),
    WorkspaceWidgetType.budgetHealth => const _BudgetHealth(),
    WorkspaceWidgetType.topCategories => const _TopCategories(),
    WorkspaceWidgetType.goalProgress => const _GoalProgress(),
    WorkspaceWidgetType.safeToSpend => const _SafeToSpend(),
    WorkspaceWidgetType.subStashJar => const _SubStashJar(),
    WorkspaceWidgetType.burnRateLine => const _BurnRateLine(),
    WorkspaceWidgetType.quickEntryPad => const _QuickEntryPad(),
    WorkspaceWidgetType.wasteAuditor => const _WasteAuditor(),
    WorkspaceWidgetType.roommateSync => const _RoommateSync(),
    WorkspaceWidgetType.media => _MediaWidget(widget: widget),
    WorkspaceWidgetType.mangaStatus => const _MangaStatus(),
    WorkspaceWidgetType.asciiFortune => const _AsciiFortune(),
    WorkspaceWidgetType.chibiMascot => const _ChibiMascot(),
    WorkspaceWidgetType.growthGem => const _GrowthGem(),
  };
}

/// A body whose rows scroll rather than overflow.
///
/// Card heights are fixed but content is not: three goals need more room than
/// one, translations run longer than English, and the Settings text slider
/// scales everything by up to 1.2 before the OS accessibility scale applies on
/// top. Rather than guessing a row budget that holds in every combination,
/// these bodies scroll — nothing is ever unreachable or clipped mid-row.
class _ScrollingBody extends StatelessWidget {
  const _ScrollingBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      children: children,
    );
  }
}

/// Shrinks its child to fit the space available instead of overflowing.
///
/// Used for the decorative widgets, whose glyph and gauge sizes are fixed
/// pixel values that would otherwise spill out of a small card.
class _FitBody extends StatelessWidget {
  const _FitBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: child,
    );
  }
}

// --------------------------------------------------------------- data cards

class _TodaySnapshot extends StatelessWidget {
  const _TodaySnapshot();

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();
    return _Metric(
      label: 'Spent today',
      value: currency.formatFromUsd(finance.spentToday),
    );
  }
}

class _BudgetHealth extends StatelessWidget {
  const _BudgetHealth();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();

    // Budgets are monthly limits, so this must compare against *this month's*
    // spend. Using the all-time total made the percentage climb without bound —
    // a year in, a healthy budget read as 1400%.
    final byCategory = <String, double>{
      for (final e in finance.expensesByCategory(month: DateTime.now()))
        // Lower-cased because `upsertBudget` matches names case-insensitively,
        // so a budget saved as "food" must still find "Food" transactions.
        e.key.toLowerCase(): e.value,
    };

    if (finance.budgets.isEmpty) {
      return Text(
        'No category budgets set yet.',
        style: theme.textTheme.bodySmall,
      );
    }

    return _ScrollingBody(
      children: [
        for (final b in finance.budgets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    b.name,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  b.monthlyLimit <= 0
                      ? '—'
                      : '${((byCategory[b.name.toLowerCase()] ?? 0) / b.monthlyLimit * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();
    final top = finance.expensesByCategory().take(5).toList();

    if (top.isEmpty) {
      return Text('No expenses yet.', style: theme.textTheme.bodySmall);
    }

    return _ScrollingBody(
      children: [
        for (final e in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  currency.formatFromUsd(e.value),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goals = context.watch<FinanceProvider>().goals;

    if (goals.isEmpty) {
      return Text('No goals yet.', style: theme.textTheme.bodySmall);
    }

    return _ScrollingBody(
      children: [
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${g.icon} ${g.name}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(g.progress * 100).round()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: g.progress,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ring showing how much of today's allowance is still available.
class _SafeToSpend extends StatelessWidget {
  const _SafeToSpend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final planner = context.watch<PlannerProvider>();
    final currency = context.watch<CurrencyProvider>();

    final perDay = dailyBudget(
      remainingBalance: finance.availableBalance,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );
    final safe = math.max(0.0, perDay - finance.spentToday);
    final completion = perDay <= 0 ? 0.0 : (safe / perDay).clamp(0.0, 1.0);

    // Without a balance there is no allowance to be safe against. Showing a
    // 0% ring here reads as "you are broke" when the real answer is "tell me
    // your balance first".
    if (finance.manualBalance == null) {
      return Center(
        child: Text(
          'Set your balance on the Dashboard to see a daily allowance.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 62,
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: CircularProgressIndicator(
                  value: completion,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Text(
                '${(completion * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Safe to spend', style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  currency.formatFromUsd(safe),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Savings jar that fills toward the user's combined goal target.
class _SubStashJar extends StatelessWidget {
  const _SubStashJar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    final total = finance.goals.fold(0.0, (sum, g) => sum + g.current);
    // Fill against the user's own combined target rather than a hardcoded
    // 5,000 USD. With a single small goal the fixed target left the jar stuck
    // near empty forever, which told the user nothing.
    final target = finance.goals.fold(0.0, (sum, g) => sum + g.target);
    final fill = target <= 0 ? 0.0 : (total / target).clamp(0.0, 1.0);

    return _ScrollingBody(children: [
      Row(
      children: [
        Container(
          width: 40,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
              bottom: Radius.circular(16),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              heightFactor: fill == 0 ? 0.02 : fill,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            // The label, amount, and Boost button together exceed a small
            // card's 80px; min lets the column shrink to what it is given
            // instead of demanding its natural height.
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sub-stash', style: theme.textTheme.bodySmall),
              FittedBox(
                child: Text(
                  currency.formatFromUsd(total),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              if (finance.goals.isNotEmpty)
                Text(
                  'Boosts "${finance.goals.first.name}"',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: finance.goals.isEmpty
                    ? null
                    : () {
                        // Converted, unlike the web app's literal +5.
                        context.read<FinanceProvider>().contributeToGoal(
                              finance.goals.first.id,
                              currency.convertToUsd(5),
                            );
                      },
                child: Text(
                  'Boost ${currency.formatAmount(5, decimalDigits: 0)}',
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    ]);
  }
}

/// Expenses over the last seven days.
class _BurnRateLine extends StatelessWidget {
  const _BurnRateLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();

    final now = DateTime.now();
    // One pass over the list, not seven. The previous version ran a full scan
    // per day and rebuilt on every notify, so at a few thousand transactions
    // it was tens of thousands of comparisons per frame.
    final dayIndex = <String, int>{
      for (var i = 0; i < 7; i++)
        isoDate(DateTime(now.year, now.month, now.day - (6 - i))): i,
    };
    final totals = List<double>.filled(7, 0);
    for (final t in finance.transactions) {
      if (!t.isExpense) continue;
      final i = dayIndex[t.date];
      if (i != null) totals[i] += t.amount;
    }
    final series = [
      for (var i = 0; i < 7; i++) FlSpot(i.toDouble(), totals[i]),
    ];

    final maxY = series.fold(0.0, (m, s) => s.y > m ? s.y : m);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.25,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: series,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fast expense entry against the most-used categories.
class _QuickEntryPad extends StatefulWidget {
  const _QuickEntryPad();

  @override
  State<_QuickEntryPad> createState() => _QuickEntryPadState();
}

class _QuickEntryPadState extends State<_QuickEntryPad> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    var categories =
        finance.expensesByCategory().take(3).map((e) => e.key).toList();
    if (categories.isEmpty) categories = ['Food', 'Transport', 'Shopping'];

    void add(String category) {
      final typed = double.tryParse(_controller.text.trim());
      if (typed == null || typed <= 0) {
        // The web app returned silently here, so tapping a category with an
        // empty box did nothing at all and looked broken.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an amount above zero first.')),
        );
        return;
      }
      context.read<FinanceProvider>().addTransaction(
            name: category,
            amount: currency.convertToUsd(typed),
            type: TransactionType.expense,
            category: category,
            date: todayIso(),
          );
      _controller.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to $category.')),
      );
    }

    return _ScrollingBody(
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Amount',
            prefixText: '${currency.currency.symbol} ',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in categories)
              ActionChip(
                label: Text(c),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => add(c),
              ),
          ],
        ),
      ],
    );
  }
}

/// Recurring charges worth reviewing — real detections, not placeholders.
class _WasteAuditor extends StatelessWidget {
  const _WasteAuditor();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final subs = context.watch<FinanceProvider>().subscriptions;

    if (subs.isEmpty) {
      return Text(
        'No recurring charges detected yet.',
        style: theme.textTheme.bodySmall,
      );
    }

    final annual = subs.fold(0.0, (sum, s) => sum + s.annualCost);

    return _ScrollingBody(
      children: [
        Text(
          '${currency.formatFromUsd(annual)} a year across '
          '${subs.length} subscription${subs.length == 1 ? '' : 's'}.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        for (final s in subs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(s.name, style: theme.textTheme.bodySmall),
                ),
                Text(
                  '${currency.formatFromUsd(s.averageAmount)}/mo',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Who owes what on shared plans — driven by real split budgets.
class _RoommateSync extends StatelessWidget {
  const _RoommateSync();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final store = context.watch<BudgetPlanProvider>();

    final shared = store.plans.where((p) => p.people > 1).toList();
    if (shared.isEmpty) {
      return Text(
        'No split plans yet. Finalise a budget with more than one person.',
        style: theme.textTheme.bodySmall,
      );
    }

    return _ScrollingBody(
      children: [
        for (final plan in shared)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plan.title,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        plan.settledWith.contains('all')
                            ? 'Settled'
                            : 'Owed ${currency.formatFromUsd(plan.owedToYou)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: plan.settledWith.contains('all')
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context
                      .read<BudgetPlanProvider>()
                      .toggleSettled(plan.id, 'all'),
                  child: Text(
                    plan.settledWith.contains('all') ? 'Undo' : 'Settle',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ visual

class _MediaWidget extends StatefulWidget {
  const _MediaWidget({required this.widget});

  final WorkspaceWidget widget;

  @override
  State<_MediaWidget> createState() => _MediaWidgetState();
}

class _MediaWidgetState extends State<_MediaWidget> {
  String? _absolutePath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_MediaWidget old) {
    super.didUpdateWidget(old);
    if (old.widget.mediaPath != widget.widget.mediaPath) _resolve();
  }

  Future<void> _resolve() async {
    final path = await ImageStore.resolve(widget.widget.mediaPath);
    if (mounted) setState(() => _absolutePath = path);
  }

  Future<void> _pick() async {
    final fileName = await ImageStore.pickAndStore(widget.widget.id);
    if (fileName == null || !mounted) return;
    context.read<WorkspaceProvider>().setMedia(widget.widget.id, fileName);
    await _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final path = _absolutePath;
    if (path == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Choose image'),
        ),
      );
    }
    return GestureDetector(
      onTap: _pick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _MangaStatus extends StatelessWidget {
  const _MangaStatus();

  static const _stages = ['😔', '😐', '😊', '😄', '🤩'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goals = context.watch<FinanceProvider>().goals;

    final average = goals.isEmpty
        ? 0.0
        : goals.fold(0.0, (sum, g) => sum + g.progress * 100) / goals.length;
    final capped = average.clamp(0.0, 100.0);
    final stage = (capped / 25).floor().clamp(0, _stages.length - 1);

    return Center(
      child: _FitBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_stages[stage], style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(
              goals.isEmpty
                  ? 'Add a goal to start tracking'
                  : 'Savings progress ${capped.round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AsciiFortune extends StatelessWidget {
  const _AsciiFortune();

  static const _fortunes = [
    '💰 A penny saved is a penny earned',
    '📈 Small steps lead to big gains',
    '🎯 Goals achieved with patience',
    '💡 Smart spending = Happy future',
    '🚀 Invest in yourself today',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Rotates by day-of-year. The web app derived the index from the first
    // letter of the weekday name, which made one of the five unreachable.
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final fortune = _fortunes[dayOfYear % _fortunes.length];

    return Center(
      child: Text(
        fortune,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

class _ChibiMascot extends StatefulWidget {
  const _ChibiMascot();

  @override
  State<_ChibiMascot> createState() => _ChibiMascotState();
}

class _ChibiMascotState extends State<_ChibiMascot> {
  static const _faces = ['🤖', '🐱', '🦊', '🐼', '🐧'];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // The web app's mascot advertised "Click for a surprise!" and had no
    // handler at all. Tapping now actually does something.
    return Center(
      child: GestureDetector(
        onTap: () =>
            setState(() => _index = (_index + 1) % _faces.length),
        child: _FitBody(
          child: Text(
            _faces[_index],
            style: const TextStyle(fontSize: 44),
          ),
        ),
      ),
    );
  }
}

class _GrowthGem extends StatefulWidget {
  const _GrowthGem();

  @override
  State<_GrowthGem> createState() => _GrowthGemState();
}

class _GrowthGemState extends State<_GrowthGem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    final savings = finance.goals.fold(0.0, (sum, g) => sum + g.current);
    final size = math.min(80.0, 30 + savings / 10000 * 50);

    return Center(
      child: _FitBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: CustomPaint(
                size: Size(size, size),
                painter: _HexagonPainter(
                  start: theme.colorScheme.primary,
                  end: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currency.formatFromUsd(savings),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gem the web app drew as an inline SVG polygon — no three.js involved,
/// despite the 3D dependencies in its package.json.
class _HexagonPainter extends CustomPainter {
  const _HexagonPainter({required this.start, required this.end});

  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.90, h * 0.40)
      ..lineTo(w * 0.90, h * 0.70)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.10, h * 0.70)
      ..lineTo(w * 0.10, h * 0.40)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(colors: [start, end]).createShader(
        Rect.fromLTWH(0, 0, w, h),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexagonPainter old) =>
      old.start != start || old.end != end;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: _FitBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
