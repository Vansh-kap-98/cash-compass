import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_progress_ring.dart';
import '../../app/widgets/goal_icon.dart';
import '../../l10n/l10n.dart';
import '../../l10n/presenters.dart';
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
      label: context.l10n.dashStatSpentToday,
      value: currency.formatFromUsd(finance.spentToday),
    );
  }
}

class _BudgetHealth extends StatelessWidget {
  const _BudgetHealth();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        l10n.widgetNoCategoryBudgets,
        style: theme.textTheme.bodySmall,
      );
    }

    return _ScrollingBody(
      children: [
        // Name and percentage on one line with a track beneath, as the
        // reference sheet lays out its budget list. The bar says at a glance
        // what the figure only says on reading — same numbers, same source.
        for (final b in finance.budgets)
          Builder(
            builder: (context) {
              final used = byCategory[b.name.toLowerCase()] ?? 0;
              final share =
                  b.monthlyLimit <= 0 ? null : used / b.monthlyLimit;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoryLabel(l10n, b.name),
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          share == null
                              ? '—'
                              : '${(share * 100).round()}%',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        // A budget with no limit has no proportion to draw, so
                        // the track shows empty rather than guessing at one.
                        value: share == null ? 0 : share.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.subtleFill,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();
    final top = finance.expensesByCategory().take(5).toList();

    if (top.isEmpty) {
      return Text(l10n.chartNoExpenses, style: theme.textTheme.bodySmall);
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
                    categoryLabel(l10n, e.key),
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
      return Text(context.l10n.widgetNoGoals, style: theme.textTheme.bodySmall);
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
                    Icon(goalIcon(g.icon), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        g.name,
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
          context.l10n.widgetSetBalanceFirst,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Row(
      children: [
        // The shared ring rather than a CircularProgressIndicator stacked
        // behind a Text: Material's indicator cannot centre a label, so the
        // cap and the figure were competing for the same optical centre.
        AppProgressRing(progress: completion, size: 62),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.l10n.widgetSafeToSpendLabel,
                  style: theme.textTheme.bodySmall),
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
    final l10n = context.l10n;
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
                Text(l10n.widgetSubStash, style: theme.textTheme.bodySmall),
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
                    l10n.widgetBoostsGoal(finance.goals.first.name),
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
                    l10n.widgetBoostAmount(
                      currency.formatAmount(5, decimalDigits: 0),
                    ),
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
    final l10n = context.l10n;
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    // These are stored category keys, not labels — `add` writes one straight
    // onto the transaction, so they stay English here and are translated only
    // where they are shown.
    var categories =
        finance.expensesByCategory().take(3).map((e) => e.key).toList();
    if (categories.isEmpty) categories = ['Food', 'Transport', 'Shopping'];

    void add(String category) {
      final typed = double.tryParse(_controller.text.trim());
      if (typed == null || typed <= 0) {
        // The web app returned silently here, so tapping a category with an
        // empty box did nothing at all and looked broken.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.widgetEnterAmountFirst)),
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
        SnackBar(
          content: Text(
            l10n.widgetAddedToCategory(categoryLabel(l10n, category)),
          ),
        ),
      );
    }

    return _ScrollingBody(
      children: [
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.widgetAmountHint,
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
                label: Text(categoryLabel(l10n, c)),
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final subs = context.watch<FinanceProvider>().subscriptions;

    if (subs.isEmpty) {
      return Text(
        l10n.widgetNoRecurring,
        style: theme.textTheme.bodySmall,
      );
    }

    final annual = subs.fold(0.0, (sum, s) => sum + s.annualCost);

    return _ScrollingBody(
      children: [
        Text(
          l10n.widgetWasteAnnual(currency.formatFromUsd(annual), subs.length),
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
                  l10n.perMonth(currency.formatFromUsd(s.averageAmount)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final store = context.watch<BudgetPlanProvider>();

    final shared = store.plans.where((p) => p.people > 1).toList();
    if (shared.isEmpty) {
      return Text(
        l10n.widgetNoSplitPlans,
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
                            ? l10n.labelSettled
                            : l10n.widgetOwed(
                                currency.formatFromUsd(plan.owedToYou),
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: plan.settledWith.contains('all')
                              ? AppColors.inkSecondary
                              : AppColors.ink,
                          fontWeight: plan.settledWith.contains('all')
                              ? FontWeight.w400
                              : FontWeight.w700,
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
                    plan.settledWith.contains('all')
                        ? l10n.actionUndo
                        : l10n.actionSettle,
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
          label: Text(context.l10n.widgetChooseImage),
        ),
      );
    }
    return GestureDetector(
      onTap: _pick,
      child: ClipRRect(
        // Thumbnail, so the small step -- matching the receipt thumbnails.
        borderRadius: Theme.of(context).radii.smallBorder,
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

  // Material's sentiment set is the same five-step ramp the emoji gave, drawn
  // as line faces instead of colour ones.
  static const _stages = [
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_dissatisfied_outlined,
    Icons.sentiment_neutral_outlined,
    Icons.sentiment_satisfied_outlined,
    Icons.sentiment_very_satisfied_outlined,
  ];

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
            Icon(_stages[stage], size: 40),
            const SizedBox(height: 6),
            Text(
              goals.isEmpty
                  ? context.l10n.widgetAddGoalToTrack
                  : context.l10n.widgetSavingsProgress(capped.round()),
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

  static List<String> _fortunes(AppLocalizations l10n) => [
        l10n.fortunePennySaved,
        l10n.fortuneSmallSteps,
        l10n.fortuneGoalsPatience,
        l10n.fortuneSmartSpending,
        l10n.fortuneInvestYourself,
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Rotates by day-of-year. The web app derived the index from the first
    // letter of the weekday name, which made one of the five unreachable.
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final fortunes = _fortunes(context.l10n);
    final fortune = fortunes[dayOfYear % fortunes.length];

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
  // Five distinct line glyphs rather than five colour animals. Distinctness is
  // the whole point of the widget — tapping cycles them — so these are chosen
  // to differ in silhouette, not just in subject.
  static const _faces = [
    Icons.smart_toy_outlined,
    Icons.pets,
    Icons.cruelty_free_outlined,
    Icons.rocket_launch_outlined,
    Icons.emoji_nature_outlined,
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // The web app's mascot advertised "Click for a surprise!" and had no
    // handler at all. Tapping now actually does something.
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => _index = (_index + 1) % _faces.length),
        child: _FitBody(
          child: Icon(_faces[_index], size: 44),
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
                painter: const _HexagonPainter(),
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
///
/// Flat-shaded rather than gradient-filled. The gradient was the one glossy
/// surface left in the app, and a single gloss among flat cards reads as an
/// oversight rather than as an accent. The cut is suggested by two flat facets
/// in different greys — the way a printed diagram would show it — which keeps
/// the shape legible without simulating a light source.
class _HexagonPainter extends CustomPainter {
  const _HexagonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.90, h * 0.40)
      ..lineTo(w * 0.90, h * 0.70)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.10, h * 0.70)
      ..lineTo(w * 0.10, h * 0.40)
      ..close();

    canvas.drawPath(body, Paint()..color = AppColors.ink);

    // The upper-left facet, one flat step lighter. Drawn over the body rather
    // than beside it so the silhouette stays a single clean hexagon.
    final facet = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.50, h * 0.90)
      ..lineTo(w * 0.10, h * 0.70)
      ..lineTo(w * 0.10, h * 0.40)
      ..close();

    canvas.drawPath(facet, Paint()..color = const Color(0xFF5C5C5C));
  }

  @override
  bool shouldRepaint(_HexagonPainter old) => false;
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
