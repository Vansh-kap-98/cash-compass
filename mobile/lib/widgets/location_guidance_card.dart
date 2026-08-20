import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/budget_math.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';
import '../state/planner_provider.dart';

/// Compares typical local staple costs against what is left for today.
///
/// Port of the Location Budget Guidance card in `DashboardPlanner.tsx`.
class LocationGuidanceCard extends StatelessWidget {
  const LocationGuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final planner = context.watch<PlannerProvider>();
    final finance = context.watch<FinanceProvider>();

    final profile = geoProfileFor(planner.geoProfileKey);
    final today = todayIso();
    final perDay = dailyBudget(
      remainingBalance: finance.availableBalance,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );
    final remainingToday =
        perDay - finance.spentToday - planner.plannedFor(today);
    final verdicts =
        stapleVerdicts(profile: profile, selectedDayRemaining: remainingToday);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location guidance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Typical local costs against what is left for today.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: profile.key,
              decoration: const InputDecoration(labelText: 'Region'),
              items: [
                for (final p in geoProfiles)
                  DropdownMenuItem(value: p.key, child: Text(p.label)),
              ],
              onChanged: (key) {
                if (key != null) planner.setGeoProfile(key);
              },
            ),
            const SizedBox(height: 12),
            for (final v in verdicts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: theme.textTheme.bodyMedium),
                          Text(
                            'Typical ${currency.formatFromUsd(v.cost)} · '
                            'suggested max ${currency.formatFromUsd(v.healthyLimit)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(v.badge),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: v.affordable
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.errorContainer,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rule-based tips for today.
class SuggestionsCard extends StatelessWidget {
  const SuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planner = context.watch<PlannerProvider>();
    final finance = context.watch<FinanceProvider>();

    final today = todayIso();
    final perDay = dailyBudget(
      remainingBalance: finance.availableBalance,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );
    final planned = planner.plannedFor(today);
    final tips = dailySuggestions(
      selectedDayRemaining: perDay - finance.spentToday - planned,
      selectedDayPlanned: planned,
      dailyBudget: perDay,
      averagePerDay: finance.averagePerDay,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Suggestions for today',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: theme.textTheme.bodyMedium),
                    Expanded(
                      child: Text(tip, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Historical per-day spending totals.
class DayRecordsCard extends StatelessWidget {
  const DayRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final records =
        context.watch<FinanceProvider>().dailyRecordsByDay.take(20).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All day records', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (records.isEmpty)
              Text(
                'No records yet. Add entries to start building history.',
                style: theme.textTheme.bodySmall,
              )
            else
              for (final r in records)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.date, style: theme.textTheme.bodyMedium),
                      Text(
                        currency.formatFromUsd(r.expense),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
