import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        _BalanceSnapshotCard(),
        SizedBox(height: 16),
        _StatGrid(),
        SizedBox(height: 16),
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
    final theme = Theme.of(context);
    final currencyStore = context.watch<CurrencyProvider>();
    final currency = currencyStore.currency;
    // Rebuilds when the stored balance changes — including a seed, a reset, or
    // a currency switch — so the field can resync.
    final balanceUsd =
        context.select<FinanceProvider, double?>((f) => f.manualBalance);
    _syncFromStore(balanceUsd, currencyStore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total balance', style: theme.textTheme.labelLarge),
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
            const SizedBox(height: 8),
            Text(
              'This snapshot drives the whole dashboard.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    // The first three read cached aggregates. The daily average needs a group-
    // by-day pass, which is O(n) once per build rather than per card.
    final stats = <({String label, double value})>[
      (label: 'Available', value: finance.availableBalance),
      (label: 'Spent today', value: finance.spentToday),
      (label: 'Total spent', value: finance.totalSpent),
      (label: 'Average / day', value: finance.averagePerDay),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        for (final stat in stats)
          _StatCard(
            label: stat.label,
            value: currency.formatFromUsd(stat.value),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Selecting on `revision` rather than on the list itself: the store mutates
    // `transactions` in place, so a list-valued selector would compare equal to
    // itself and never rebuild. Reading the list with `read` after the selector
    // has registered the dependency gives the current contents.
    context.select<FinanceProvider, int>((f) => f.revision);
    final recent =
        context.read<FinanceProvider>().transactions.take(10).toList();
    final currency = context.watch<CurrencyProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Text(
                'No entries yet. Add one with the + button.',
                style: theme.textTheme.bodySmall,
              )
            else
              for (final t in recent)
                ListTile(
                  key: ValueKey(t.id),
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    t.icon ?? '💸',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(t.name),
                  subtitle: Text('${t.category} · ${t.date}'),
                  trailing: Text(
                    '${t.isExpense ? '−' : '+'}'
                    '${currency.formatFromUsd(t.amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.isExpense
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
