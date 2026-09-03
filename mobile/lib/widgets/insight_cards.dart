import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../logic/budget_math.dart';
import '../logic/events.dart';
import '../logic/insights.dart';
import '../services/prefs.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';
import '../state/planner_provider.dart';

/// Rule-based smart suggestions.
class InsightBoxCard extends StatelessWidget {
  const InsightBoxCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final suggestions = finance.suggestions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.smartSuggestionsTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final s in suggestions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestionTitle(l10n, s),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestionBody(l10n, s, currency.formatFromUsd),
                      style: theme.textTheme.bodySmall,
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

/// Watches today's small discretionary spending.
class SmartCardsWidget extends StatelessWidget {
  const SmartCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();
    final planner = context.watch<PlannerProvider>();

    final limit = dailyBudget(
      remainingBalance: finance.availableBalance,
      rangeStart: planner.rangeStart,
      rangeEnd: planner.rangeEnd,
    );
    final card = smartCard(
      transactions: finance.transactions,
      goals: finance.goals,
      dailyLimit: limit,
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
                  card.watching
                      ? Icons.verified_outlined
                      : Icons.warning_amber_outlined,
                  size: 18,
                  color: card.watching
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(l10n.smartCardsTitle,
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (card.watching)
              Text(
                l10n.smartCardsWatching,
                style: theme.textTheme.bodySmall,
              )
            else ...[
              Text(
                l10n.smartCardsSpent(
                  currency.formatFromUsd(card.todayAmount),
                  (card.shareOfLimit * 100).round(),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.smartCardsAnnualised(
                  currency.formatFromUsd(card.annualised),
                ),
                style: theme.textTheme.bodySmall,
              ),
              if (card.divertGoalName != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.smartCardsDivert(card.divertGoalName!),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Surfaces detected weekday/reason clusters in unplanned spending.
class SpendingPatternCard extends StatelessWidget {
  const SpendingPatternCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final insight = context.watch<FinanceProvider>().behaviorPattern;

    // Deliberately renders nothing until there is a real pattern — a card
    // saying "no pattern yet" is noise.
    if (insight == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.spendingPatternTitle,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    behaviorInsightMessage(l10n, insight),
                    style: theme.textTheme.bodySmall,
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

/// Recurring charges detected from history.
class SubscriptionsCard extends StatelessWidget {
  const SubscriptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final subs = context.watch<FinanceProvider>().subscriptions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recurringChargesTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.recurringChargesSubtitle,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (subs.isEmpty)
              Text(
                l10n.recurringChargesEmpty,
                style: theme.textTheme.bodySmall,
              )
            else
              for (final s in subs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: theme.textTheme.bodyMedium),
                            Text(
                              l10n.subscriptionCharges(
                                s.chargeCount,
                                s.lastCharged,
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currency.formatFromUsd(s.averageAmount)),
                          Text(
                            l10n.perYear(
                              currency.formatFromUsd(s.annualCost),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
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

/// Regional financial calendar with an event-window forecast.
class EventCalendarCard extends StatefulWidget {
  const EventCalendarCard({super.key});

  @override
  State<EventCalendarCard> createState() => _EventCalendarCardState();
}

class _EventCalendarCardState extends State<EventCalendarCard> {
  Region _region = Region.india;
  bool _loadedRegion = false;

  @override
  void initState() {
    super.initState();
    _restoreRegion();
  }

  Future<void> _restoreRegion() async {
    final stored = await Prefs().getString(PrefsKeys.region);
    if (!mounted) return;
    setState(() {
      _region = RegionLabel.fromId(stored);
      _loadedRegion = true;
    });
  }

  Future<void> _setRegion(Region region) async {
    setState(() => _region = region);
    await Prefs().setString(PrefsKeys.region, region.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final finance = context.watch<FinanceProvider>();

    if (!_loadedRegion) return const SizedBox.shrink();

    final events = eventsFor(_region);
    final active = activeEvent(events);
    final forecast =
        forecastFor(transactions: finance.transactions, event: active);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.financialCalendarTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.financialCalendarSubtitle,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<Region>(
              segments: [
                ButtonSegment(
                  value: Region.india,
                  label: Text(l10n.regionIndia),
                ),
                ButtonSegment(
                  value: Region.russia,
                  label: Text(l10n.regionRussia),
                ),
              ],
              selected: {_region},
              onSelectionChanged: (s) => _setRegion(s.first),
            ),
            if (active != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.eventComingSoon(eventName(l10n, active.kind)),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.eventForecast(
                        currency.formatFromUsd(forecast.projected),
                        currency.formatFromUsd(forecast.increase),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!forecast.basedOnHistory) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.eventNoHistory,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventName(l10n, e.kind),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${eventTypeLabel(l10n, e.type)} · '
                            '${isoDate(e.start)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      daysUntil(e.start) == 0
                          ? l10n.eventToday
                          : l10n.eventDaysShort(daysUntil(e.start)),
                      style: theme.textTheme.bodySmall,
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
