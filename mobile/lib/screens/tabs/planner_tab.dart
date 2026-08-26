import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/student_planner.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';
import '../../state/student_planner_provider.dart';

/// The Student Planner tab: survival calculator, social budgeting, loan
/// runway, and streaks.
///
/// Port of `StudentPlannerHub.tsx`, which was fully written on the web but
/// never wired into any screen.
class PlannerTab extends StatelessWidget {
  const PlannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: const [
        _SurvivalCard(),
        SizedBox(height: 16),
        _SocialCard(),
        SizedBox(height: 16),
        _RunwayCard(),
        SizedBox(height: 16),
        _StreakCard(),
      ],
    );
  }
}

// -------------------------------------------------------------- survival

class _SurvivalCard extends StatefulWidget {
  const _SurvivalCard();

  @override
  State<_SurvivalCard> createState() => _SurvivalCardState();
}

class _SurvivalCardState extends State<_SurvivalCard> {
  final _incomeName = TextEditingController();
  final _incomeAmount = TextEditingController();
  final _costName = TextEditingController();
  final _costAmount = TextEditingController();
  IncomeCadence _cadence = IncomeCadence.weekly;

  @override
  void dispose() {
    _incomeName.dispose();
    _incomeAmount.dispose();
    _costName.dispose();
    _costAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final planner = context.watch<StudentPlannerProvider>();

    final result = survival(
      horizonDays: planner.horizonDays,
      streams: planner.incomeStreams,
      fixedCosts: planner.fixedCosts,
      upcomingBills: planner.upcomingBills,
      balance: finance.totalBalance,
      incomeToDate: finance.manualIncomeToDate ?? finance.totalIncome,
      spentToday: finance.spentToday,
    );

    final zoneColour = switch (result.zone) {
      SurvivalZone.green => theme.colorScheme.primary,
      SurvivalZone.tight => theme.colorScheme.tertiary,
      SurvivalZone.critical => theme.colorScheme.error,
    };

    return _Section(
      title: 'Survival calculator',
      subtitle: 'Your daily spendable cash after essentials.',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily spendable', style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  currency.formatFromUsd(result.dailySpendable),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Chip(
              label: Text(result.zone.label),
              backgroundColor: zoneColour.withValues(alpha: 0.18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Planning horizon — ${planner.horizonDays} days',
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: planner.horizonDays.toDouble(),
          min: 7,
          max: 120,
          divisions: 113,
          label: '${planner.horizonDays}',
          onChanged: (v) => planner.setHorizon(v.round()),
        ),
        _LabelledField(
          label: 'Upcoming must-pay bills (${currency.currency.code})',
          initial: planner.upcomingBills == 0
              ? ''
              : currency.convertFromUsd(planner.upcomingBills).toString(),
          onSubmitted: (v) => planner.setUpcomingBills(
            currency.convertToUsd(double.tryParse(v) ?? 0),
          ),
        ),
        const Divider(height: 24),
        Text('Income streams', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _incomeName,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Source',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _incomeAmount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Amount',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<IncomeCadence>(
                initialValue: _cadence,
                decoration: const InputDecoration(isDense: true),
                items: [
                  for (final c in IncomeCadence.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (c) {
                  if (c != null) setState(() => _cadence = c);
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                planner.addIncome(
                  _incomeName.text,
                  currency.convertToUsd(
                    double.tryParse(_incomeAmount.text.trim()) ?? 0,
                  ),
                  _cadence,
                );
                _incomeName.clear();
                _incomeAmount.clear();
              },
              child: const Text('Add'),
            ),
          ],
        ),
        for (final s in planner.incomeStreams)
          ListTile(
            key: ValueKey(s.id),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(s.name),
            subtitle: Text(
              '${currency.formatFromUsd(s.amount)} · ${s.cadence.label}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => planner.removeIncome(s.id),
            ),
          ),
        const Divider(height: 24),
        Row(
          children: [
            Text('Fixed costs', style: theme.textTheme.labelLarge),
            const Spacer(),
            Text(
              currency.formatFromUsd(result.fixedCostsTotal),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _costName,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Bill',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _costAmount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Amount',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // A full-width button rather than an icon at the right edge: the
        // floating action button hovers over that corner and was covering it.
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () {
              planner.addFixedCost(
                _costName.text,
                currency.convertToUsd(
                  double.tryParse(_costAmount.text.trim()) ?? 0,
                ),
              );
              _costName.clear();
              _costAmount.clear();
            },
            child: const Text('Add fixed cost'),
          ),
        ),
        for (final c in planner.fixedCosts)
          ListTile(
            key: ValueKey(c.id),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(c.name),
            subtitle: Text(currency.formatFromUsd(c.amount)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => planner.removeFixedCost(c.id),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- social

class _SocialCard extends StatefulWidget {
  const _SocialCard();

  @override
  State<_SocialCard> createState() => _SocialCardState();
}

class _SocialCardState extends State<_SocialCard> {
  final _title = TextEditingController();
  final _low = TextEditingController();
  final _realistic = TextEditingController();
  final _stretch = TextEditingController();
  int _split = 1;
  DateTime _date = DateTime.now().add(const Duration(days: 2));

  @override
  void dispose() {
    _title.dispose();
    _low.dispose();
    _realistic.dispose();
    _stretch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final planner = context.watch<StudentPlannerProvider>();

    final result = survival(
      horizonDays: planner.horizonDays,
      streams: planner.incomeStreams,
      fixedCosts: planner.fixedCosts,
      upcomingBills: planner.upcomingBills,
      balance: finance.totalBalance,
      incomeToDate: finance.manualIncomeToDate ?? finance.totalIncome,
      spentToday: finance.spentToday,
    );
    final after = dailyAfterSocial(
      discretionaryPool: result.discretionaryPool,
      plans: planner.socialPlans,
      horizonDays: planner.horizonDays,
    );

    return _Section(
      title: 'Social budgeting',
      subtitle: 'See the impact of nights out before you commit.',
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Event',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _low,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Low',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _realistic,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Realistic',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _stretch,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Stretch',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Date',
                  ),
                  child: Text(isoDate(_date)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.remove),
              onPressed: _split <= 1 ? null : () => setState(() => _split -= 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$_split'),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _split += 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () {
              planner.addSocialPlan(
                title: _title.text,
                date: isoDate(_date),
                low: currency
                    .convertToUsd(double.tryParse(_low.text.trim()) ?? 0),
                realistic: currency
                    .convertToUsd(double.tryParse(_realistic.text.trim()) ?? 0),
                stretch: currency
                    .convertToUsd(double.tryParse(_stretch.text.trim()) ?? 0),
                splitCount: _split,
              );
              _title.clear();
              _low.clear();
              _realistic.clear();
              _stretch.clear();
              setState(() => _split = 1);
            },
            child: const Text('Add plan'),
          ),
        ),
        if (planner.socialPlans.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'If every realistic plan happens, your daily spendable becomes '
            '${currency.formatFromUsd(after)}.',
            style: theme.textTheme.bodySmall,
          ),
          for (final p in planner.socialPlans)
            ListTile(
              key: ValueKey(p.id),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(p.title),
              subtitle: Text(
                '${p.date} · your share '
                '${currency.formatFromUsd(p.yourShare)}'
                '${p.splitCount > 1 ? ' of ${p.splitCount}' : ''}\n'
                'Range ${currency.formatFromUsd(p.lowEstimate)}'
                ' – ${currency.formatFromUsd(p.stretchEstimate)}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => planner.removeSocialPlan(p.id),
              ),
            ),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- runway

class _RunwayCard extends StatelessWidget {
  const _RunwayCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final planner = context.watch<StudentPlannerProvider>();

    final result = loanRunway(
      lumpSum: planner.loanLumpSum,
      safetyBuffer: planner.loanSafetyBuffer,
      transactions: finance.transactions,
    );

    return _Section(
      title: 'Loan runway',
      subtitle: 'Make a lump sum last the whole semester.',
      children: [
        Row(
          children: [
            Expanded(
              child: _LabelledField(
                label: 'Lump sum',
                initial:
                    currency.convertFromUsd(planner.loanLumpSum).toString(),
                onSubmitted: (v) => planner.setLoan(
                  lumpSum: currency.convertToUsd(double.tryParse(v) ?? 0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabelledField(
                label: 'Safety buffer',
                initial: currency
                    .convertFromUsd(planner.loanSafetyBuffer)
                    .toString(),
                onSubmitted: (v) => planner.setLoan(
                  buffer: currency.convertToUsd(double.tryParse(v) ?? 0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Remaining runway: ${result.runwayWeeks.toStringAsFixed(1)} weeks',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: result.progress,
            minHeight: 8,
            color: result.willRunOut ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${result.weeksRemaining.toStringAsFixed(1)} semester weeks left.'
          '${result.willRunOut ? ' At this pace the money runs out first.' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Weekly burn',
                value: currency.formatFromUsd(result.burnRatePerWeek),
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Suggested cap',
                value: currency.formatFromUsd(result.recommendedWeeklyCap),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- streaks

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planner = context.watch<StudentPlannerProvider>();
    final streak = currentStreak(planner.streakDates);

    return _Section(
      title: 'Bloom streaks',
      subtitle: 'Stay within your plan three days running to earn a badge.',
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current streak', style: theme.textTheme.bodySmall),
                Text(
                  '$streak day${streak == 1 ? '' : 's'}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Spacer(),
            if (streak >= 3) const Chip(label: Text('3-day bloom streak 🌸')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: planner.toggleTodayOnTrack,
            child: Text(
              planner.isOnTrackToday
                  ? 'Marked on track today'
                  : 'Mark today on track',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No penalties. Missed days just restart softly.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- shared

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Text field that commits on submit or focus loss rather than per keystroke,
/// so typing never fights the reformatting.
class _LabelledField extends StatefulWidget {
  const _LabelledField({
    required this.label,
    required this.initial,
    required this.onSubmitted,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onSubmitted;

  @override
  State<_LabelledField> createState() => _LabelledFieldState();
}

class _LabelledFieldState extends State<_LabelledField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(isDense: true, labelText: widget.label),
      onSubmitted: widget.onSubmitted,
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        widget.onSubmitted(_controller.text.trim());
      },
    );
  }
}
