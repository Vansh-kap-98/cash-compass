import 'package:cash_compass/logic/budget_math.dart';
import 'package:cash_compass/logic/events.dart';
import 'package:cash_compass/logic/insights.dart';
import 'package:cash_compass/logic/subscriptions.dart';
import 'package:cash_compass/models/budget_category.dart';
import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

FinanceTransaction tx({
  String name = 'Thing',
  double amount = 10,
  TransactionType type = TransactionType.expense,
  String category = 'Food',
  required String date,
  String? createdAt,
  bool unplanned = false,
  List<ReasonTag> tags = const [],
}) =>
    FinanceTransaction(
      id: 'tx-$name-$date-$amount',
      name: name,
      amount: amount,
      type: type,
      category: category,
      date: date,
      createdAt: createdAt,
      isUnplanned: unplanned,
      reasonTags: tags,
    );

void main() {
  group('budget maths', () {
    test('daily budget uses the range when present', () {
      final budget = dailyBudget(
        remainingBalance: 700,
        rangeStart: DateTime(2026, 8, 1),
        rangeEnd: DateTime(2026, 8, 7),
      );
      // 7 inclusive days.
      expect(budget, closeTo(100, 0.001));
    });

    test('falls back to days left in the month', () {
      final budget = dailyBudget(
        remainingBalance: 310,
        now: DateTime(2026, 8, 22), // 10 days left in a 31-day month
      );
      expect(budget, closeTo(31, 0.001));
    });

    test('never returns a negative allowance', () {
      expect(dailyBudget(remainingBalance: -50), 0);
    });

    test('day ranges are inclusive and floored at one', () {
      expect(daysInRange(DateTime(2026, 1, 1), DateTime(2026, 1, 1)), 1);
      expect(daysInRange(DateTime(2026, 1, 1), DateTime(2026, 1, 10)), 10);
      // An inverted range must not produce zero or negative days.
      expect(daysInRange(DateTime(2026, 1, 10), DateTime(2026, 1, 1)), 1);
    });

    test('average uses recorded days, not elapsed days', () {
      final records = dailyRecords([
        tx(date: '2026-08-01', amount: 10),
        tx(date: '2026-08-01', amount: 20),
        tx(date: '2026-08-05', amount: 60),
      ]);
      expect(records.length, 2);
      expect(averageSpentPerDay(records), 45); // (30 + 60) / 2
    });

    test('staples flip to Trim Needed above 40% of what is left', () {
      final profile = geoProfileFor('us-city');
      // Lunch costs 16, so a 40 remaining -> limit 16 -> exactly affordable.
      final ok = stapleVerdicts(profile: profile, selectedDayRemaining: 40);
      expect(ok.first.affordable, isTrue);

      final tight = stapleVerdicts(profile: profile, selectedDayRemaining: 30);
      expect(tight.first.affordable, isFalse);
      expect(tight.first.badge, 'Trim Needed');
    });

    test('india-metro multiplier is applied to staple costs', () {
      final verdicts = stapleVerdicts(
        profile: geoProfileFor('india-metro'),
        selectedDayRemaining: 100,
      );
      // India Metro's own Lunch base cost is 6, not the US figure of 16.
      expect(verdicts.first.name, 'Lunch');
      expect(verdicts.first.cost, closeTo(6 * 0.48, 0.001));
    });

    test('suggestions always return at most three, over-budget first', () {
      final tips = dailySuggestions(
        selectedDayRemaining: -5,
        selectedDayPlanned: 200,
        dailyBudget: 50,
        averagePerDay: 90,
      );
      expect(tips.length, 3);
      expect(tips.first, contains('over'));
    });
  });

  group('behaviour insight', () {
    test('stays silent below two spontaneous entries', () {
      expect(
        behaviorInsight([
          tx(
            date: '2026-08-21',
            createdAt: '2026-08-21T20:00:00',
            unplanned: true,
            tags: [ReasonTag.impulse],
          ),
        ]),
        isNull,
      );
    });

    test('detects a repeated weekday + reason + night cluster', () {
      // 2026-08-21 and 2026-08-28 are both Fridays, both evening.
      final insight = behaviorInsight([
        tx(
          date: '2026-08-21',
          createdAt: '2026-08-21T20:00:00',
          unplanned: true,
          tags: [ReasonTag.social],
        ),
        tx(
          date: '2026-08-28',
          createdAt: '2026-08-28T21:30:00',
          unplanned: true,
          tags: [ReasonTag.social],
        ),
      ]);

      expect(insight, isNotNull);
      expect(insight!.weekday, 'Friday');
      expect(insight.isNight, isTrue);
      expect(insight.tag, ReasonTag.social);
      expect(insight.count, 2);
    });

    test('ignores planned spending', () {
      expect(
        behaviorInsight([
          tx(date: '2026-08-21', createdAt: '2026-08-21T20:00:00'),
          tx(date: '2026-08-28', createdAt: '2026-08-28T20:00:00'),
        ]),
        isNull,
      );
    });
  });

  group('smart suggestions', () {
    test('flags the largest category this month', () {
      final now = DateTime(2026, 8, 15);
      final s = smartSuggestions(
        transactions: [
          tx(date: '2026-08-02', category: 'Food', amount: 300),
          tx(date: '2026-08-03', category: 'Transport', amount: 50),
        ],
        budgets: const [],
        now: now,
      );
      expect(s.first.title, contains('Food'));
    });

    test('raises a budget alert at 80% of the limit', () {
      final s = smartSuggestions(
        transactions: [tx(date: '2026-08-02', category: 'Food', amount: 85)],
        budgets: const [
          BudgetCategory(id: 'b1', name: 'Food', monthlyLimit: 100),
        ],
        now: DateTime(2026, 8, 15),
      );
      expect(s.any((x) => x.title.contains('budget alert')), isTrue);
    });

    test('falls back to a neutral message with no data', () {
      final s = smartSuggestions(
        transactions: const [],
        budgets: const [],
        now: DateTime(2026, 8, 15),
      );
      expect(s.single.title, 'Track for 7 days');
    });
  });

  group('smart card', () {
    test('stays in watch mode under 40% of the limit', () {
      final card = smartCard(
        transactions: [tx(name: 'Coffee', date: '2026-08-20', amount: 3)],
        goals: const [],
        dailyLimit: 100,
        todayIsoDate: '2026-08-20',
      );
      expect(card.watching, isTrue);
    });

    test('alerts above 40% and annualises the spend', () {
      final card = smartCard(
        transactions: [tx(name: 'Latte run', date: '2026-08-20', amount: 50)],
        goals: const [
          SavingsGoal(
            id: 'g',
            name: 'Trip to Goa',
            current: 0,
            target: 1000,
            icon: '🎯',
          ),
        ],
        dailyLimit: 100,
        todayIsoDate: '2026-08-20',
      );
      expect(card.watching, isFalse);
      expect(card.annualised, 50 * 365);
      expect(card.divertGoalName, 'Trip to Goa');
    });
  });

  group('subscription detection', () {
    test('normalises merchant names', () {
      expect(merchantSignature('NETFLIX payment 08/2026'), 'netflix');
      expect(merchantSignature('Spotify Subscription'), 'spotify');
    });

    test('detects a monthly charge with steady amounts', () {
      final subs = detectSubscriptions([
        tx(name: 'Netflix', date: '2026-06-01', amount: 15.99),
        tx(name: 'Netflix', date: '2026-07-01', amount: 15.99),
        tx(name: 'Netflix', date: '2026-08-01', amount: 15.99),
      ]);
      expect(subs.length, 1);
      expect(subs.first.chargeCount, 3);
      expect(subs.first.annualCost, closeTo(15.99 * 12, 0.01));
    });

    test('rejects irregular cadence', () {
      final subs = detectSubscriptions([
        tx(name: 'Groceries', date: '2026-08-01', amount: 20),
        tx(name: 'Groceries', date: '2026-08-05', amount: 20),
      ]);
      expect(subs, isEmpty);
    });

    test('rejects amounts that vary more than 15%', () {
      final subs = detectSubscriptions([
        tx(name: 'Power bill', date: '2026-06-01', amount: 50),
        tx(name: 'Power bill', date: '2026-07-01', amount: 90),
      ]);
      expect(subs, isEmpty);
    });
  });

  group('event calendar', () {
    test('india events are ordered and dated', () {
      final events = eventsFor(Region.india, now: DateTime(2026, 6, 1));
      expect(events.length, 3);
      for (var i = 1; i < events.length; i++) {
        expect(events[i].start.isBefore(events[i - 1].start), isFalse);
      }
    });

    test('an event well in the past rolls into next year', () {
      // Diwali is Nov 7; from December it should move to the following year.
      final events = eventsFor(Region.india, now: DateTime(2026, 12, 1));
      final diwali = events.firstWhere((e) => e.id == 'in-diwali');
      expect(diwali.start.year, 2027);
    });

    test('a just-passed event stays visible inside the grace window', () {
      // Two days after Diwali starts, it must not jump a year ahead.
      final events = eventsFor(Region.india, now: DateTime(2026, 11, 9));
      final diwali = events.firstWhere((e) => e.id == 'in-diwali');
      expect(diwali.start.year, 2026);
    });

    test('forecast applies 1.12 without window history', () {
      final event = eventsFor(Region.india, now: DateTime(2026, 6, 1))
          .firstWhere((e) => e.id == 'in-diwali');
      final f = forecastFor(
        transactions: [tx(date: '2026-03-01', amount: 100)],
        event: event,
      );
      expect(f.basedOnHistory, isFalse);
      expect(f.projected, closeTo(112, 0.01));
    });

    test('forecast applies 1.16 when the window has history', () {
      final event = eventsFor(Region.india, now: DateTime(2026, 6, 1))
          .firstWhere((e) => e.id == 'in-diwali');
      final f = forecastFor(
        transactions: [tx(date: '2025-11-08', amount: 200)],
        event: event,
      );
      expect(f.basedOnHistory, isTrue);
      expect(f.projected, closeTo(232, 0.01));
    });
  });
}
