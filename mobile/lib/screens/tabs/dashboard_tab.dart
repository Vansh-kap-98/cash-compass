import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/widgets/app_card.dart';
import '../../app/widgets/app_icon_tile.dart';
import '../../app/widgets/app_list_row.dart';
import '../../app/widgets/category_icon.dart';
import '../../l10n/l10n.dart';
import '../../l10n/presenters.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';
import '../../widgets/daily_planner_card.dart';
import '../../widgets/insight_cards.dart';
import '../../widgets/location_guidance_card.dart';

/// The Dashboard tab.
///
/// Ports `DashboardPlanner.tsx` plus the insight, subscription, and event
/// surfaces around it: balance snapshot, stat grid, budget range, smart cards,
/// spending pattern, daily planner, location guidance, suggestions, insight
/// box, subscriptions, event calendar, recent transactions, and day records.
///
/// Note the deliberate absence of `context.watch` at this level: each card
/// subscribes to only what it displays. Watching the whole provider here would
/// rebuild the balance TextField and the transaction list every time any
/// unrelated value changed.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    // ListView's constructor is not const, but every child is — so each card is
    // allocated once and skipped on rebuild.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: const [
        // The snapshot and the four figures it feeds are one unit, so they sit
        // closer to each other (12) than to the cards below (24). The rest of
        // the page keeps an even 16. That uneven rhythm is the hierarchy: it
        // marks where "what you have" ends and "what we make of it" begins,
        // which thirteen cards at a uniform 16 could not say.
        _BalanceSnapshotCard(),
        SizedBox(height: 12),
        _StatGrid(),
        SizedBox(height: 24),
        BudgetRangeCard(),
        SizedBox(height: 16),
        SmartCardsWidget(),
        SizedBox(height: 16),
        SpendingPatternCard(),
        DailyPlannerCard(),
        SizedBox(height: 16),
        LocationGuidanceCard(),
        SizedBox(height: 16),
        SuggestionsCard(),
        SizedBox(height: 16),
        InsightBoxCard(),
        SizedBox(height: 16),
        SubscriptionsCard(),
        SizedBox(height: 16),
        EventCalendarCard(),
        SizedBox(height: 16),
        _RecentTransactions(),
        SizedBox(height: 16),
        DayRecordsCard(),
      ],
    );
  }
}

/// Lets the user type the balance they actually have. Everything else on the
/// page is derived from this plus recorded expenses.
class _BalanceSnapshotCard extends StatefulWidget {
  const _BalanceSnapshotCard();

  @override
  State<_BalanceSnapshotCard> createState() => _BalanceSnapshotCardState();
}

class _BalanceSnapshotCardState extends State<_BalanceSnapshotCard> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Keeps the field in step with the stored value.
  ///
  /// Setting the text only in `initState` left it stale whenever the balance
  /// changed from elsewhere — most visibly when switching currency, which
  /// relabelled the field without reconverting the number shown in it.
  /// Skipped while focused so it never fights typing.
  void _syncFromStore(double? balanceUsd, CurrencyProvider currency) {
    if (_focus.hasFocus) return;
    final next = balanceUsd == null
        ? ''
        : currency.convertFromUsd(balanceUsd).toStringAsFixed(2);
    if (_controller.text != next) _controller.text = next;
  }

  void _save() {
    final finance = context.read<FinanceProvider>();
    final currency = context.read<CurrencyProvider>();

    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      finance.setManualSnapshot();
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    // The user types in their active currency; storage is always USD.
    finance.setManualSnapshot(balance: currency.convertToUsd(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currencyStore = context.watch<CurrencyProvider>();
    final currency = currencyStore.currency;
    // Rebuilds when the stored balance changes — including a seed, a reset, or
    // a currency switch — so the field can resync.
    final balanceUsd =
        context.select<FinanceProvider, double?>((f) => f.manualBalance);
    _syncFromStore(balanceUsd, currencyStore);

    // The hero card, inverted to ink. This is the figure the whole page is
    // derived from, and the reference sheet gives that role a solid black
    // panel. Everything inside is re-themed for the dark ground by AppCard, so
    // the field, its label and the chip all invert with it.
    return AppCard.ink(
      padding: const EdgeInsets.all(20),
      // Built through a Builder so `Theme.of` resolves *below* the card's
      // inverted theme. Reading it from the enclosing build — as the first
      // version did — hands back the light theme, and a title styled
      // `titleMedium` then paints black type on the black panel: present,
      // laid out, and completely invisible.
      child: Builder(
        builder: (context) {
          final inkTheme = Theme.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // The chip is a fixed three-letter control, so the title is
                  // the side that has to yield.
                  Expanded(
                    child: Text(
                      l10n.dashTotalBalance,
                      style: inkTheme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(currency.code),
                    onPressed: () =>
                        context.read<CurrencyProvider>().cycleCurrency(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focus,
                style: inkTheme.textTheme.headlineSmall,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${currency.symbol} ',
                  hintText: '0.00',
                ),
                onSubmitted: (_) => _save(),
                onTapOutside: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _save();
                },
              ),
              const SizedBox(height: 10),
              Text(
                l10n.dashSnapshotHint,
                style: inkTheme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    // The first three read cached aggregates. The daily average needs a group-
    // by-day pass, which is O(n) once per build rather than per card.
    //
    // `emphasis` is carried per row rather than compared against the label,
    // which stopped identifying the right tile once the labels were translated.
    final stats = <({String label, double value, bool emphasis})>[
      (
        label: l10n.dashStatAvailable,
        value: finance.availableBalance,
        emphasis: true,
      ),
      (
        label: l10n.dashStatSpentToday,
        value: finance.spentToday,
        emphasis: false,
      ),
      (
        label: l10n.dashStatTotalSpent,
        value: finance.totalSpent,
        emphasis: false,
      ),
      (
        label: l10n.dashStatAveragePerDay,
        value: finance.averagePerDay,
        emphasis: false,
      ),
    ];

    // A grid cell is a fixed box, so its height has to follow the text inside
    // it. Dividing the ratio by the active text scale makes the tiles grow
    // taller as type grows rather than clipping it — a constant 1.7 overflowed
    // by 4dp at the default size once the monochrome scale set larger explicit
    // sizes, and by 18dp at 1.3x.
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7 / textScale.clamp(1.0, 2.0),
      children: [
        for (final stat in stats)
          _StatCard(
            label: stat.label,
            value: currency.formatFromUsd(stat.value),
            // Four equal tiles said all four figures matter equally. They do
            // not: `availableBalance` is the one every other surface on the
            // page reads, so it carries the accent and the others recede.
            emphasis: stat.emphasis,
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;

  /// Marks the one figure on the grid the rest of the page derives from.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A filled ground, per the design rules for this project: emphasis comes
    // from fill, elevation or spacing, never from a coloured edge.
    return AppCard(
      tone: emphasis ? AppCardTone.quiet : AppCardTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        // The cell is a fixed box; without this the column demands its
        // natural height and reports an overflow instead of settling into
        // what it was given.
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: emphasis
                    ? scheme.onTertiaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: emphasis ? scheme.tertiary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Selecting on `revision` rather than on the list itself: the store mutates
    // `transactions` in place, so a list-valued selector would compare equal to
    // itself and never rebuild. Reading the list with `read` after the selector
    // has registered the dependency gives the current contents.
    context.select<FinanceProvider, int>((f) => f.revision);
    final recent =
        context.read<FinanceProvider>().transactions.take(10).toList();
    final currency = context.watch<CurrencyProvider>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashRecentActivity, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Text(
              l10n.dashNoEntries,
              style: theme.textTheme.bodySmall,
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              // Rules between rows, not under the last one — which is what a
              // per-row divider leaves behind.
              if (i > 0) const AppRowDivider(indent: 52),
              AppListRow(
                key: ValueKey(recent[i].id),
                leading: AppIconTile.icon(categoryIcon(recent[i].category)),
                title: recent[i].name,
                subtitle: '${categoryLabel(l10n, recent[i].category)}'
                    ' · ${recent[i].date}',
                // Both directions are ink. The leading '-' or '+' already says
                // which way the money went, and colouring every expense red
                // would tint most of this list — money leaving an account is
                // the normal case, not a fault.
                trailing: '${recent[i].isExpense ? '−' : '+'}'
                    '${currency.formatFromUsd(recent[i].amount)}',
              ),
            ],
        ],
      ),
    );
  }
}
