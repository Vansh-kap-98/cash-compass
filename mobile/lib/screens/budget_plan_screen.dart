import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_theme.dart';
import '../app/widgets/app_card.dart';
import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../models/budget_plan.dart';
import '../state/budget_plan_provider.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';

/// Plan and split a trip, outing, or event.
///
/// Port of the Plan Budget panel in `QuickActions.tsx`, redesigned as a
/// full-screen route: the original was a mouse-draggable floating window that
/// minimised to a vertical tab on the screen edge, which has no touch analogue.
class BudgetPlanScreen extends StatefulWidget {
  const BudgetPlanScreen({super.key});

  static Future<void> open(BuildContext context) {
    context.read<BudgetPlanProvider>().startOrResumeDraft();
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BudgetPlanScreen()),
    );
  }

  @override
  State<BudgetPlanScreen> createState() => _BudgetPlanScreenState();
}

class _BudgetPlanScreenState extends State<BudgetPlanScreen> {
  final _titleController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = context.read<BudgetPlanProvider>().draft;
    _titleController.text = draft?.title ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _itemNameController.dispose();
    _itemCostController.dispose();
    super.dispose();
  }

  BudgetPlanProvider get _store => context.read<BudgetPlanProvider>();

  void _addItem(BudgetPlan draft) {
    final name = _itemNameController.text.trim();
    final typed = double.tryParse(_itemCostController.text.trim());
    if (name.isEmpty || typed == null || typed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.budgetItemInvalid)),
      );
      return;
    }

    final currency = context.read<CurrencyProvider>();
    _store.updateDraft(
      draft.copyWith(
        items: [
          ...draft.items,
          BudgetLineItem(
            id: 'bi-${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            estimate: currency.convertToUsd(typed),
          ),
        ],
      ),
    );
    _itemNameController.clear();
    _itemCostController.clear();
  }

  Future<void> _finalise() async {
    final l10n = context.l10n;
    final error = _store.finalizeDraft();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(budgetPlanErrorMessage(l10n, error))),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.budgetFinalised)),
    );
  }

  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.budgetDiscardDialogTitle),
        content: Text(l10n.budgetDiscardDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.actionDiscard),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      _store.discardDraft();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final store = context.watch<BudgetPlanProvider>();
    final draft = store.draft;

    if (draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetPlannerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.budgetDiscardTooltip,
            onPressed: _confirmDiscard,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SegmentedButton<BudgetPlanType>(
            segments: [
              ButtonSegment(
                value: BudgetPlanType.trip,
                label: Text(l10n.budgetTypeTrip),
                icon: const Icon(Icons.flight_takeoff),
              ),
              ButtonSegment(
                value: BudgetPlanType.outing,
                label: Text(l10n.budgetTypeOuting),
                icon: const Icon(Icons.restaurant),
              ),
              ButtonSegment(
                value: BudgetPlanType.event,
                label: Text(l10n.budgetTypeEvent),
                icon: const Icon(Icons.group),
              ),
            ],
            selected: {draft.planType},
            onSelectionChanged: (s) =>
                _store.updateDraft(draft.copyWith(planType: s.first)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.budgetFieldTitle,
              hintText: l10n.budgetFieldTitleHint,
            ),
            onChanged: (v) => _store.updateDraft(draft.copyWith(title: v)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: l10n.budgetFieldFrom,
                  value: draft.dateFrom,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(draft.dateFrom) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _store.updateDraft(
                        draft.copyWith(dateFrom: isoDate(picked)),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: l10n.budgetFieldTo,
                  value: draft.dateTo ?? '—',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(draft.dateTo ?? '') ??
                          DateTime.tryParse(draft.dateFrom) ??
                          DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _store.updateDraft(
                        draft.copyWith(dateTo: isoDate(picked)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.budgetSplittingBetween,
                  style: theme.textTheme.bodyMedium),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: draft.people <= 1
                    ? null
                    : () => _store
                        .updateDraft(draft.copyWith(people: draft.people - 1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${draft.people}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: () => _store
                    .updateDraft(draft.copyWith(people: draft.people + 1)),
              ),
            ],
          ),
          const Divider(height: 28),
          Text(l10n.budgetItems, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemNameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.budgetFieldItem),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _itemCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.budgetFieldCost(currency.currency.code),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                icon: const Icon(Icons.add),
                tooltip: l10n.budgetAddItemTooltip,
                onPressed: () => _addItem(draft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (draft.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.budgetItemsEmpty,
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            for (final item in draft.items)
              ListTile(
                key: ValueKey(item.id),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(item.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.formatFromUsd(item.estimate)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.actionRemove,
                      onPressed: () => _store.updateDraft(
                        draft.copyWith(
                          items: draft.items
                              .where((i) => i.id != item.id)
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.budgetTotal, style: theme.textTheme.bodyMedium),
                    Text(
                      currency.formatFromUsd(draft.total),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (draft.people > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.budgetPerPerson(draft.people),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(currency.formatFromUsd(draft.perPerson)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _finalise,
            child: Text(l10n.budgetFinalise),
          ),
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
      // Matches the input border this ripples over.
      borderRadius: Theme.of(context).radii.controlBorder,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
    );
  }
}

/// Receipts for finalised plans, shown on the Goals tab.
class BudgetReceiptsCard extends StatelessWidget {
  const BudgetReceiptsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final store = context.watch<BudgetPlanProvider>();

    if (store.plans.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.budgetReceiptsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final plan in store.plans.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          plan.dateTo == null
                              ? l10n.budgetReceiptSummary(
                                  budgetPlanTypeLabel(l10n, plan.planType),
                                  plan.dateFrom,
                                  plan.items.length,
                                )
                              : l10n.budgetReceiptSummaryRange(
                                  budgetPlanTypeLabel(l10n, plan.planType),
                                  plan.dateFrom,
                                  plan.dateTo!,
                                  plan.items.length,
                                ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.formatFromUsd(plan.total)),
                      if (plan.people > 1)
                        Text(
                          l10n.budgetEach(
                            currency.formatFromUsd(plan.perPerson),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.budgetDeleteTooltip,
                    onPressed: () =>
                        context.read<BudgetPlanProvider>().deletePlan(plan.id),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
