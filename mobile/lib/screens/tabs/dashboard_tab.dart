import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';

/// The Dashboard tab.
///
/// Currently covers the balance snapshot and the four stat cards from
/// `DashboardPlanner.tsx`. The planner, insights, and event calendar land in
/// later milestones.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _BalanceSnapshotCard(finance: finance, currency: currency),
        const SizedBox(height: 16),
        _StatGrid(finance: finance, currency: currency),
        const SizedBox(height: 16),
        _RecentTransactions(finance: finance, currency: currency),
      ],
    );
  }
}

/// Lets the user type the balance they actually have. Everything else on the
/// page is derived from this plus recorded expenses.
class _BalanceSnapshotCard extends StatefulWidget {
  const _BalanceSnapshotCard({required this.finance, required this.currency});

  final FinanceProvider finance;
  final CurrencyProvider currency;

  @override
  State<_BalanceSnapshotCard> createState() => _BalanceSnapshotCardState();
}

class _BalanceSnapshotCardState extends State<_BalanceSnapshotCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final balance = widget.finance.manualBalance;
    _controller = TextEditingController(
      text: balance == null
          ? ''
          : widget.currency.convertFromUsd(balance).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      widget.finance.setManualSnapshot();
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    // The user types in their active currency; storage is always USD.
    widget.finance
        .setManualSnapshot(balance: widget.currency.convertToUsd(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  label: Text(widget.currency.currency.code),
                  onPressed: () => widget.currency.cycleCurrency(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${widget.currency.currency.symbol} ',
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
  const _StatGrid({required this.finance, required this.currency});

  final FinanceProvider finance;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    final stats = <({String label, double value})>[
      (label: 'Available', value: finance.availableBalance),
      (label: 'Spent today', value: finance.spentToday),
      (label: 'Total spent', value: finance.totalSpent),
      (label: 'Total income', value: finance.totalIncome),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    child: Text(
                      currency.formatFromUsd(stat.value),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.finance, required this.currency});

  final FinanceProvider finance;
  final CurrencyProvider currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = finance.transactions.take(10).toList();

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

/// Temporary helper so the wiring can be verified end to end before the real
/// Add Entry sheet lands. Remove once that ships.
void addSampleExpense(BuildContext context) {
  context.read<FinanceProvider>().addTransaction(
        name: 'Coffee',
        amount: 4.50,
        type: TransactionType.expense,
        category: 'Food',
        date: todayIso(),
      );
}
