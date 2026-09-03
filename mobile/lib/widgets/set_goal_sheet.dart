import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';
import 'sheet_scaffold.dart';

/// Savings-goal periods offered as presets, with their day counts.
///
/// The chip labels are localised in [goalPeriodLabel] rather than held here —
/// "6 Months" is display text, and this enum is also what the calculation reads.
enum GoalPeriod {
  oneMonth(30),
  threeMonths(90),
  sixMonths(180),
  oneYear(365),
  twoYears(730),
  custom(90);

  const GoalPeriod(this.days);

  final int days;
}

String goalPeriodLabel(AppLocalizations l10n, GoalPeriod p) => switch (p) {
      GoalPeriod.oneMonth => l10n.periodOneMonth,
      GoalPeriod.threeMonths => l10n.periodThreeMonths,
      GoalPeriod.sixMonths => l10n.periodSixMonths,
      GoalPeriod.oneYear => l10n.periodOneYear,
      GoalPeriod.twoYears => l10n.periodTwoYears,
      GoalPeriod.custom => l10n.periodCustom,
    };

/// Create a savings goal.
///
/// Port of the Set Goal dialog in `QuickActions.tsx`.
class SetGoalSheet extends StatefulWidget {
  const SetGoalSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const SetGoalSheet(),
      );

  @override
  State<SetGoalSheet> createState() => _SetGoalSheetState();
}

class _SetGoalSheetState extends State<SetGoalSheet> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController(text: '🎯');
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  final _customDaysController = TextEditingController(text: '90');

  GoalPeriod _period = GoalPeriod.sixMonths;
  String? _error;

  int get _days {
    if (_period != GoalPeriod.custom) return _period.days;
    final parsed = int.tryParse(_customDaysController.text.trim());
    if (parsed == null || parsed < 7) return 90;
    return parsed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final saved = double.tryParse(_savedController.text.trim()) ?? 0;

    if (name.isEmpty || target == null || !target.isFinite || target <= 0) {
      final message = l10n.goalInvalid;
      setState(() => _error = message);
      // Mirrored as a snack bar so the error is visible without scrolling to
      // the bottom of the form.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final currency = context.read<CurrencyProvider>();
    context.read<FinanceProvider>().addGoal(
          name: name,
          target: currency.convertToUsd(target),
          initialAmount: currency.convertToUsd(saved),
          icon: _iconController.text.trim().isEmpty
              ? '🎯'
              : _iconController.text.trim(),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.goalCreated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final goals = context.watch<FinanceProvider>().goals;

    final target = double.tryParse(_targetController.text.trim()) ?? 0;
    final saved = double.tryParse(_savedController.text.trim()) ?? 0;
    // Displayed in the active currency, so no conversion here — the values the
    // user typed are already in that currency.
    final perDay = target <= 0 || _days <= 0
        ? 0.0
        : ((target - saved) / _days).clamp(0.0, double.infinity);

    return SheetScaffold(
      title: l10n.goalSheetTitle,
      subtitle: l10n.goalSheetSubtitle,
      onSubmit: _save,
      submitLabel: l10n.goalSheetSubmit,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: TextField(
                controller: _iconController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(labelText: l10n.goalFieldIcon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.goalFieldName,
                  hintText: l10n.goalFieldNameHint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.goalFieldTarget(currency.currency.code),
                  hintText: '5000',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _savedController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.goalFieldSaved,
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.goalTimeframe, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in GoalPeriod.values)
              ChoiceChip(
                label: Text(goalPeriodLabel(l10n, p)),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        if (_period == GoalPeriod.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _customDaysController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration:
                      InputDecoration(labelText: l10n.goalFieldDays),
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.goalMinimumDays, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
        if (target > 0) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.goalReachIn(_days),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.goalPerDay(currency.formatAmount(perDay)),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.goalPerWeekMonth(
                      currency.formatAmount(perDay * 7),
                      currency.formatAmount(perDay * 30),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (goals.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l10n.goalCurrentGoals, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // A long goal name plus two formatted amounts overflows
                      // a narrow sheet, especially in locales with wider
                      // number grouping.
                      Expanded(
                        child: Text(
                          '${g.icon} ${g.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currency.formatFromUsd(g.current)} / '
                        '${currency.formatFromUsd(g.target)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: g.progress,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
