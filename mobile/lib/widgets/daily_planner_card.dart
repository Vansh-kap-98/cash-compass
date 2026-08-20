import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/budget_math.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';
import '../state/planner_provider.dart';

/// Budgeting window + derived daily allowance.
///
/// Replaces the web app's dd/mm/yyyy text fields with native date pickers —
/// the custom string parser it needed (handling `/ - .` separators and 2-digit
/// years) exists only because HTML has no good date input on desktop.
class BudgetRangeCard extends StatelessWidget {
  const BudgetRangeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planner = context.watch<PlannerProvider>();
    final currency = context.watch<CurrencyProvider>();
    final remaining =
        context.select<FinanceProvider, double>((f) => f.availableBalance);

    final days = daysInRange(planner.rangeStart, planner.rangeEnd);
    final perDay = dailyBudget(
      remainingBalance: remaining,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );

    Future<void> pick({required bool isStart}) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: isStart ? planner.rangeStart : planner.rangeEnd,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      planner.setRange(
        start: isStart ? picked : null,
        end: isStart ? null : picked,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budgeting window', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start',
                    value: isoDate(planner.rangeStart),
                    onTap: () => pick(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End',
                    value: isoDate(planner.rangeEnd),
                    onTap: () => pick(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily budget', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      currency.formatFromUsd(perDay),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  'over $days day${days == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
    );
  }
}

/// Named plans for a chosen day, compared against the daily allowance.
class DailyPlannerCard extends StatefulWidget {
  const DailyPlannerCard({super.key});

  @override
  State<DailyPlannerCard> createState() => _DailyPlannerCardState();
}

class _DailyPlannerCardState extends State<DailyPlannerCard> {
  final _titleController = TextEditingController();
  final _estimateController = TextEditingController();
  DateTime _planDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  void _add() {
    final planner = context.read<PlannerProvider>();
    final currency = context.read<CurrencyProvider>();
    final typed = double.tryParse(_estimateController.text.trim());

    if (_titleController.text.trim().isEmpty ||
        typed == null ||
        typed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a plan name and a valid amount.')),
      );
      return;
    }

    planner.addPlan(
      title: _titleController.text,
      estimate: currency.convertToUsd(typed),
      date: isoDate(_planDate),
    );
    _titleController.clear();
    _estimateController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final planner = context.watch<PlannerProvider>();
    final finance = context.watch<FinanceProvider>();

    final dateIso = isoDate(_planDate);
    final perDay = dailyBudget(
      remainingBalance: finance.availableBalance,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );
    final daySpent = finance.transactions
        .where((t) => t.isExpense && t.date == dateIso)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayPlanned = planner.plannedFor(dateIso);
    final remainingAfterPlans = perDay - daySpent - dayPlanned;
    final dayPlans = planner.plansFor(dateIso);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily plan builder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Plan a day, then compare it against your daily budget.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Plan name',
                hintText: 'Groceries and transit',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _estimateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Estimate (${currency.currency.code})',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Plan date',
                    value: dateIso,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _planDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _planDate = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _add,
                child: const Text('Add plan'),
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Spent that day',
              value: currency.formatFromUsd(daySpent),
            ),
            _SummaryRow(
              label: 'Planned',
              value: currency.formatFromUsd(dayPlanned),
            ),
            _SummaryRow(
              label: 'Daily budget',
              value: currency.formatFromUsd(perDay),
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Remaining after plans',
              value: currency.formatFromUsd(remainingAfterPlans),
              emphasise: true,
              positive: remainingAfterPlans >= 0,
            ),
            if (dayPlans.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final p in dayPlans)
                ListTile(
                  key: ValueKey(p.id),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(p.title),
                  subtitle: Text(currency.formatFromUsd(p.estimate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Delete plan',
                    onPressed: () => planner.removePlan(p.id),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'No plans for this day yet.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasise = false,
    this.positive = true,
  });

  final String label;
  final String value;
  final bool emphasise;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasise
        ? theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: positive ? null : theme.colorScheme.error,
          )
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // The label yields space to the amount. Currency-formatted values
          // are much longer in some locales — Indian grouping turns 8350 into
          // "₹8,350.00" — and a fixed-width label overflowed the row.
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}
