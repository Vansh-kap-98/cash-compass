import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final suggestions = finance.suggestions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart suggestions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final s in suggestions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(s.body, style: theme.textTheme.bodySmall),
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
                Text('Smart cards', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (card.watching)
              Text(
                'Smart cards are on watch. Discretionary spending is '
                'comfortable today.',
                style: theme.textTheme.bodySmall,
              )
            else ...[
              Text(
                'You have spent ${currency.formatFromUsd(card.todayAmount)} on '
                'small extras today — '
                '${(card.shareOfLimit * 100).round()}% of your daily limit.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'At this rate that is '
                '${currency.formatFromUsd(card.annualised)} a year.',
                style: theme.textTheme.bodySmall,
              ),
              if (card.divertGoalName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Diverting it to "${card.divertGoalName}" would get you there '
                  'sooner.',
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
                  Text('Spending pattern', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(insight.message, style: theme.textTheme.bodySmall),
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
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final subs = context.watch<FinanceProvider>().subscriptions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recurring charges', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Detected from a monthly cadence in your history.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (subs.isEmpty)
              Text(
                'Nothing detected yet. Recurring charges appear after a couple '
                'of monthly repeats.',
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
                              '${s.chargeCount} charges · last ${s.lastCharged}',
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
                            '${currency.formatFromUsd(s.annualCost)}/yr',
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
            Text('Financial calendar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Events that can change your spending velocity.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<Region>(
              segments: const [
                ButtonSegment(value: Region.india, label: Text('India')),
                ButtonSegment(value: Region.russia, label: Text('Russia')),
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
                      '${active.name} is coming soon',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spending usually rises during this window. Projected '
                      '${currency.formatFromUsd(forecast.projected)} per active '
                      'day — about '
                      '${currency.formatFromUsd(forecast.increase)} above your '
                      'usual.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!forecast.basedOnHistory) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Estimated from your overall average — no history for '
                        'this window yet.',
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
                          Text(e.name, style: theme.textTheme.bodyMedium),
                          Text(
                            '${e.type} · ${isoDate(e.start)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      daysUntil(e.start) == 0
                          ? 'Today'
                          : '${daysUntil(e.start)}d',
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
