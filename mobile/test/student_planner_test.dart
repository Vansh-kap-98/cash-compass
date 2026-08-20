import 'package:cash_compass/logic/student_planner.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/state/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

FinanceTransaction expense(String date, double amount) => FinanceTransaction(
      id: 'tx-$date-$amount',
      name: 'Thing',
      amount: amount,
      type: TransactionType.expense,
      category: 'Food',
      date: date,
    );

void main() {
  group('survival calculator', () {
    test('projects weekly and monthly income across the horizon', () {
      final r = survival(
        horizonDays: 30,
        streams: const [
          IncomeStream(
            id: 'a',
            name: 'Shifts',
            amount: 70,
            cadence: IncomeCadence.weekly,
          ),
          IncomeStream(
            id: 'b',
            name: 'Stipend',
            amount: 300,
            cadence: IncomeCadence.monthly,
          ),
          IncomeStream(
            id: 'c',
            name: 'Gift',
            amount: 50,
            cadence: IncomeCadence.oneTime,
          ),
        ],
        fixedCosts: const [],
        upcomingBills: 0,
        balance: 0,
        incomeToDate: 0,
        spentToday: 0,
      );

      // 70 * 30/7 = 300, plus 300 monthly, plus 50 one-time.
      expect(r.totalIncome, closeTo(650, 0.001));
      expect(r.dailySpendable, closeTo(650 / 30, 0.001));
    });

    test('subtracts fixed costs and upcoming bills', () {
      final r = survival(
        horizonDays: 10,
        streams: const [],
        fixedCosts: const [
          FixedCost(id: 'f', name: 'Rent', amount: 200),
        ],
        upcomingBills: 50,
        balance: 500,
        incomeToDate: 0,
        spentToday: 0,
      );
      expect(r.fixedCostsTotal, 200);
      expect(r.discretionaryPool, 250);
      expect(r.dailySpendable, 25);
    });

    test('zones follow the 25 / 12 thresholds', () {
      SurvivalZone zoneFor(double perDayBudget) => survival(
            horizonDays: 1,
            streams: const [],
            fixedCosts: const [],
            upcomingBills: 0,
            balance: perDayBudget,
            incomeToDate: 0,
            spentToday: 0,
          ).zone;

      expect(zoneFor(30), SurvivalZone.green);
      expect(zoneFor(25), SurvivalZone.green);
      expect(zoneFor(20), SurvivalZone.tight);
      expect(zoneFor(12), SurvivalZone.tight);
      expect(zoneFor(5), SurvivalZone.critical);
    });

    test('social plans reduce the daily figure by your share only', () {
      final after = dailyAfterSocial(
        discretionaryPool: 300,
        plans: const [
          SocialPlan(
            id: 's',
            title: 'Dinner',
            date: '2026-08-22',
            lowEstimate: 40,
            realisticEstimate: 100,
            stretchEstimate: 120,
            splitCount: 4,
          ),
        ],
        horizonDays: 10,
      );
      // Your share is 100/4 = 25, so (300 - 25) / 10.
      expect(after, closeTo(27.5, 0.001));
    });
  });

  group('loan runway', () {
    test('computes burn rate and runway from semester spending', () {
      // Semester starts 15 Jan; pick a date 10 weeks in.
      final now = DateTime(2026, 3, 26);
      final r = loanRunway(
        lumpSum: 4200,
        safetyBuffer: 200,
        transactions: [expense('2026-02-01', 700)],
        now: now,
      );

      expect(r.semesterExpenses, 700);
      expect(r.weeksElapsed, closeTo(10, 0.2));
      expect(r.burnRatePerWeek, closeTo(70, 2));
      expect(r.loanRemaining, closeTo(3300, 0.001));
    });

    test('runway falls back to the full term when nothing is spent', () {
      final r = loanRunway(
        lumpSum: 1000,
        safetyBuffer: 0,
        transactions: const [],
        now: DateTime(2026, 3, 1),
      );
      expect(r.burnRatePerWeek, 0);
      expect(r.runwayWeeks, r.weeksRemaining);
      expect(r.willRunOut, isFalse);
    });

    test('never reports a negative remaining balance', () {
      final r = loanRunway(
        lumpSum: 100,
        safetyBuffer: 50,
        transactions: [expense('2026-02-01', 500)],
        now: DateTime(2026, 3, 1),
      );
      expect(r.loanRemaining, 0);
    });
  });

  group('streaks', () {
    test('counts consecutive days ending today', () {
      final now = DateTime(2026, 8, 20);
      expect(
        currentStreak(
          ['2026-08-20', '2026-08-19', '2026-08-18'],
          now: now,
        ),
        3,
      );
    });

    test('stops at a gap', () {
      final now = DateTime(2026, 8, 20);
      expect(
        currentStreak(
          ['2026-08-20', '2026-08-18', '2026-08-17'],
          now: now,
        ),
        1,
      );
    });

    test('tolerates a streak that ended yesterday', () {
      final now = DateTime(2026, 8, 20);
      expect(currentStreak(['2026-08-19', '2026-08-18'], now: now), 2);
    });

    test('is zero once two days have lapsed', () {
      final now = DateTime(2026, 8, 20);
      expect(currentStreak(['2026-08-17'], now: now), 0);
    });

    test('ignores duplicates', () {
      final now = DateTime(2026, 8, 20);
      expect(currentStreak(['2026-08-20', '2026-08-20'], now: now), 1);
    });
  });

  group('sign-up validation', () {
    String? check({
      String name = 'Sam',
      String email = 'sam@example.com',
      String password = 'password1',
      String? confirm,
    }) =>
        AuthProvider.validateSignUp(
          name: name,
          email: email,
          password: password,
          confirm: confirm ?? password,
        );

    test('accepts a well-formed sign-up', () {
      expect(check(), isNull);
    });

    test('rejects a blank name', () {
      expect(check(name: '   '), contains('name'));
    });

    test('rejects a malformed email', () {
      expect(check(email: 'nope'), contains('valid email'));
      expect(check(email: 'a@b'), contains('valid email'));
    });

    test('requires at least eight characters', () {
      expect(check(password: 'short1'), contains('8 characters'));
    });

    test('requires the confirmation to match', () {
      expect(
        check(password: 'password1', confirm: 'password2'),
        contains('do not match'),
      );
    });
  });
}
