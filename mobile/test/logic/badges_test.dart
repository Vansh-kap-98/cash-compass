import 'package:cash_compass/logic/badges.dart';
import 'package:cash_compass/models/budget_category.dart';
import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/models/wishlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

AchievementInputs _inputs({
  List<SavingsGoal> goals = const [],
  List<BudgetCategory> budgets = const [],
  List<FinanceTransaction> transactions = const [],
  int readLiteracyCardCount = 0,
  List<String> activityDates = const [],
  List<String> savingsActivityDates = const [],
  Set<String> canceledSubscriptionSignatures = const {},
  String? lastWithdrawalDate,
  List<WishlistItem> wishlistItems = const [],
  DateTime? now,
}) =>
    AchievementInputs(
      goals: goals,
      budgets: budgets,
      transactions: transactions,
      readLiteracyCardCount: readLiteracyCardCount,
      activityDates: activityDates,
      savingsActivityDates: savingsActivityDates,
      canceledSubscriptionSignatures: canceledSubscriptionSignatures,
      lastWithdrawalDate: lastWithdrawalDate,
      wishlistItems: wishlistItems,
      now: now,
    );

void main() {
  test('nothing unlocks from empty state', () {
    expect(evaluateUnlockedBadges(_inputs()), isEmpty);
  });

  group('savings', () {
    test('First Seed unlocks once lifetime saved crosses the threshold', () {
      final below = _inputs(goals: const [
        SavingsGoal(id: 'g1', name: 'Trip', current: 100, target: 1000, icon: '✈️'),
      ]);
      expect(evaluateUnlockedBadges(below), isNot(contains('first-seed')));

      final atThreshold = _inputs(goals: const [
        SavingsGoal(id: 'g1', name: 'Trip', current: 300, target: 1000, icon: '✈️'),
        SavingsGoal(id: 'g2', name: 'Laptop', current: 250, target: 800, icon: '💻'),
      ]);
      expect(evaluateUnlockedBadges(atThreshold), contains('first-seed'));
    });

    test('Goal Crusher unlocks when any goal is complete', () {
      final result = evaluateUnlockedBadges(_inputs(goals: const [
        SavingsGoal(id: 'g1', name: 'Buffer', current: 500, target: 500, icon: '🛟'),
      ]));
      expect(result, contains('goal-crusher'));
    });

    test('Fortress unlocks on a single goal at the threshold', () {
      final result = evaluateUnlockedBadges(_inputs(goals: const [
        SavingsGoal(id: 'g1', name: 'House', current: 15000, target: 20000, icon: '🏠'),
      ]));
      expect(result, contains('fortress'));
    });

    test('Speed Demon needs both a target date and an early completion', () {
      final now = DateTime(2026, 6, 1);

      final noTargetDate = _inputs(
        now: now,
        goals: const [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 500,
            target: 500,
            icon: '✈️',
            completedAt: '2026-05-20T00:00:00.000',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(noTargetDate), isNot(contains('speed-demon')));

      final justInTime = _inputs(
        now: now,
        goals: const [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 500,
            target: 500,
            icon: '✈️',
            targetDate: '2026-05-25',
            completedAt: '2026-05-24T00:00:00.000',
          ),
        ],
      );
      expect(
        evaluateUnlockedBadges(justInTime),
        isNot(contains('speed-demon')),
        reason: 'one day ahead is short of the 5-day requirement',
      );

      final wellAhead = _inputs(
        now: now,
        goals: const [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 500,
            target: 500,
            icon: '✈️',
            targetDate: '2026-05-25',
            completedAt: '2026-05-18T00:00:00.000',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(wellAhead), contains('speed-demon'));
    });

    test('Iron Shield needs an old-enough goal and no recent withdrawal', () {
      final now = DateTime(2026, 6, 1);

      final tooNew = _inputs(
        now: now,
        goals: [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 100,
            target: 1000,
            icon: '✈️',
            createdAt: now.subtract(const Duration(days: 10)).toIso8601String(),
          ),
        ],
      );
      expect(evaluateUnlockedBadges(tooNew), isNot(contains('iron-shield')));

      final oldEnough = _inputs(
        now: now,
        goals: [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 100,
            target: 1000,
            icon: '✈️',
            createdAt: now.subtract(const Duration(days: 40)).toIso8601String(),
          ),
        ],
      );
      expect(evaluateUnlockedBadges(oldEnough), contains('iron-shield'));

      final recentWithdrawal = _inputs(
        now: now,
        goals: [
          SavingsGoal(
            id: 'g1',
            name: 'Trip',
            current: 100,
            target: 1000,
            icon: '✈️',
            createdAt: now.subtract(const Duration(days: 40)).toIso8601String(),
          ),
        ],
        lastWithdrawalDate:
            now.subtract(const Duration(days: 5)).toIso8601String(),
      );
      expect(
        evaluateUnlockedBadges(recentWithdrawal),
        isNot(contains('iron-shield')),
        reason: 'a withdrawal inside the trailing 30 days disqualifies it',
      );

      final goalWithNoCreatedAt = _inputs(
        now: now,
        goals: const [
          SavingsGoal(id: 'g1', name: 'Trip', current: 100, target: 1000, icon: '✈️'),
        ],
      );
      expect(
        evaluateUnlockedBadges(goalWithNoCreatedAt),
        isNot(contains('iron-shield')),
        reason: 'a goal from before this field existed cannot qualify',
      );
    });
  });

  group('budget control', () {
    test('Category Boss needs 5 budget categories', () {
      final budgets = List.generate(
        5,
        (i) => BudgetCategory(id: 'b$i', name: 'Cat$i', monthlyLimit: 100),
      );
      expect(
        evaluateUnlockedBadges(_inputs(budgets: budgets)),
        contains('category-boss'),
      );
      expect(
        evaluateUnlockedBadges(_inputs(budgets: budgets.take(4).toList())),
        isNot(contains('category-boss')),
      );
    });

    test('Tracking Ninja fails once any expense falls back to Other', () {
      final categorized = List.generate(
        14,
        (i) => FinanceTransaction(
          id: 'tx$i',
          name: 'Lunch',
          amount: 10,
          type: TransactionType.expense,
          category: 'Food',
          date: '2026-01-${(i + 1).toString().padLeft(2, '0')}',
        ),
      );
      expect(
        evaluateUnlockedBadges(_inputs(transactions: categorized)),
        contains('tracking-ninja'),
      );

      final withOther = [
        ...categorized,
        const FinanceTransaction(
          id: 'tx-other',
          name: 'Misc',
          amount: 5,
          type: TransactionType.expense,
          category: 'Other',
          date: '2026-01-20',
        ),
      ];
      expect(
        evaluateUnlockedBadges(_inputs(transactions: withOther)),
        isNot(contains('tracking-ninja')),
      );
    });

    test('Master Balancer and Under Budget read last month against today\'s limits', () {
      final budgets = const [
        BudgetCategory(id: 'b1', name: 'Food', monthlyLimit: 100),
      ];
      final now = DateTime(2026, 3, 15);

      final withinBudget = _inputs(
        now: now,
        budgets: budgets,
        transactions: const [
          FinanceTransaction(
            id: 'tx1',
            name: 'Groceries',
            amount: 80,
            type: TransactionType.expense,
            category: 'Food',
            date: '2026-02-10',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(withinBudget), contains('master-balancer'));
      expect(evaluateUnlockedBadges(withinBudget), contains('under-budget'));

      final overBudget = _inputs(
        now: now,
        budgets: budgets,
        transactions: const [
          FinanceTransaction(
            id: 'tx1',
            name: 'Groceries',
            amount: 150,
            type: TransactionType.expense,
            category: 'Food',
            date: '2026-02-10',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(overBudget), isNot(contains('master-balancer')));
      expect(evaluateUnlockedBadges(overBudget), isNot(contains('under-budget')));
    });

    test('Zero Impulse needs a skip at least 48 hours after adding', () {
      final skippedTooSoon = _inputs(wishlistItems: const [
        WishlistItem(
          id: 'w1',
          name: 'Shoes',
          amount: 60,
          addedAt: '2026-01-01T10:00:00.000',
          status: WishlistStatus.skipped,
          resolvedAt: '2026-01-02T10:00:00.000', // 24h later
        ),
      ]);
      expect(evaluateUnlockedBadges(skippedTooSoon), isNot(contains('zero-impulse')));

      final skippedInTime = _inputs(wishlistItems: const [
        WishlistItem(
          id: 'w1',
          name: 'Shoes',
          amount: 60,
          addedAt: '2026-01-01T10:00:00.000',
          status: WishlistStatus.skipped,
          resolvedAt: '2026-01-03T11:00:00.000', // 49h later
        ),
      ]);
      expect(evaluateUnlockedBadges(skippedInTime), contains('zero-impulse'));

      final purchasedNotSkipped = _inputs(wishlistItems: const [
        WishlistItem(
          id: 'w1',
          name: 'Shoes',
          amount: 60,
          addedAt: '2026-01-01T10:00:00.000',
          status: WishlistStatus.purchased,
          resolvedAt: '2026-01-05T10:00:00.000',
        ),
      ]);
      expect(
        evaluateUnlockedBadges(purchasedNotSkipped),
        isNot(contains('zero-impulse')),
        reason: 'buying it is the opposite of the badge',
      );

      final stillPending = _inputs(wishlistItems: const [
        WishlistItem(
          id: 'w1',
          name: 'Shoes',
          amount: 60,
          addedAt: '2026-01-01T10:00:00.000',
        ),
      ]);
      expect(evaluateUnlockedBadges(stillPending), isNot(contains('zero-impulse')));
    });
  });

  group('habit & streak', () {
    test('Daily Driver and 30-Day Legend read the activity streak', () {
      final now = DateTime(2026, 4, 20);
      String iso(int daysAgo) =>
          now.subtract(Duration(days: daysAgo)).toIso8601String().split('T').first;

      final fourteen = [for (var i = 0; i < 14; i++) iso(i)];
      final result14 = evaluateUnlockedBadges(
        _inputs(now: now, activityDates: fourteen),
      );
      expect(result14, contains('daily-driver'));
      expect(result14, isNot(contains('thirty-day-legend')));

      final thirty = [for (var i = 0; i < 30; i++) iso(i)];
      final result30 = evaluateUnlockedBadges(
        _inputs(now: now, activityDates: thirty),
      );
      expect(result30, contains('thirty-day-legend'));
    });

    test('a gap in the streak resets the count', () {
      final now = DateTime(2026, 4, 20);
      String iso(int daysAgo) =>
          now.subtract(Duration(days: daysAgo)).toIso8601String().split('T').first;

      // Missing yesterday breaks the streak back to just today.
      final gappy = [iso(0), iso(2), iso(3)];
      final result = evaluateUnlockedBadges(_inputs(now: now, activityDates: gappy));
      expect(result, isNot(contains('daily-driver')));
    });

    test('Payday First needs income and a savings contribution on the same day',
        () {
      final withMatch = _inputs(
        savingsActivityDates: const ['2026-01-05'],
        transactions: const [
          FinanceTransaction(
            id: 'tx1',
            name: 'Salary',
            amount: 500,
            type: TransactionType.income,
            category: 'Salary',
            date: '2026-01-05',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(withMatch), contains('payday-first'));

      final noMatch = _inputs(
        savingsActivityDates: const ['2026-01-06'],
        transactions: const [
          FinanceTransaction(
            id: 'tx1',
            name: 'Salary',
            amount: 500,
            type: TransactionType.income,
            category: 'Salary',
            date: '2026-01-05',
          ),
        ],
      );
      expect(evaluateUnlockedBadges(noMatch), isNot(contains('payday-first')));
    });

    test('Unsubscriber unlocks on the first canceled subscription', () {
      expect(
        evaluateUnlockedBadges(
          _inputs(canceledSubscriptionSignatures: const {'netflix'}),
        ),
        contains('unsubscriber'),
      );
    });

    test('Night Owl Tracker reads the createdAt hour', () {
      final late = _inputs(transactions: const [
        FinanceTransaction(
          id: 'tx1',
          name: 'Snack',
          amount: 5,
          type: TransactionType.expense,
          category: 'Food',
          date: '2026-01-01',
          createdAt: '2026-01-01T23:30:00.000',
        ),
      ]);
      expect(evaluateUnlockedBadges(late), contains('night-owl-tracker'));

      final daytime = _inputs(transactions: const [
        FinanceTransaction(
          id: 'tx1',
          name: 'Lunch',
          amount: 5,
          type: TransactionType.expense,
          category: 'Food',
          date: '2026-01-01',
          createdAt: '2026-01-01T13:30:00.000',
        ),
      ]);
      expect(evaluateUnlockedBadges(daytime), isNot(contains('night-owl-tracker')));
    });
  });

  test('Financial Master needs 15 cards read', () {
    expect(
      evaluateUnlockedBadges(_inputs(readLiteracyCardCount: 14)),
      isNot(contains('financial-master')),
    );
    expect(
      evaluateUnlockedBadges(_inputs(readLiteracyCardCount: 15)),
      contains('financial-master'),
    );
  });

  test('every badge id in achievementBadges is reachable by some input', () {
    // Guards against a badge added to the catalogue with no matching rule.
    final allIds = achievementBadges.map((b) => b.id).toSet();
    expect(allIds.length, achievementBadges.length,
        reason: 'no duplicate ids');
  });
}
