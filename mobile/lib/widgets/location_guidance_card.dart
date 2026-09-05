import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../app/widgets/app_card.dart';
import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
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
    final l10n = context.l10n;
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.locationGuidanceTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.locationGuidanceSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: profile.key,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fieldRegion),
            items: [
              for (final p in geoProfiles)
                DropdownMenuItem(
                  value: p.key,
                  child: Text(geoProfileLabel(l10n, p.key)),
                ),
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
                        Text(
                          stapleLabel(l10n, v.kind),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          l10n.stapleCost(
                            currency.formatFromUsd(v.cost),
                            currency.formatFromUsd(v.healthyLimit),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Affordable recedes to an outline; over-budget inverts
                  // to a filled black chip. Fill, not hue — the two used to
                  // differ by colour alone and now resolve to the same grey.
                  Chip(
                    label: Text(stapleBadge(l10n, v)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        v.affordable ? AppColors.surface : AppColors.ink,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: v.affordable ? AppColors.ink : AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: AppColors.outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rule-based tips for today.
class SuggestionsCard extends StatelessWidget {
  const SuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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

    return AppCard(
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
              Text(l10n.suggestionsTodayTitle,
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
                    child: Text(
                      dailyTipMessage(l10n, tip),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Historical per-day spending totals.
class DayRecordsCard extends StatelessWidget {
  const DayRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final records =
        context.watch<FinanceProvider>().dailyRecordsByDay.take(20).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dayRecordsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(
              l10n.dayRecordsEmpty,
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
    );
  }
}
