import 'package:flutter/foundation.dart';

import '../logic/student_planner.dart';
import '../models/budget_category.dart';
import '../models/budget_plan.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/workspace_widget.dart';
import '../state/budget_plan_provider.dart';
import '../state/finance_provider.dart';
import '../state/planner_provider.dart';
import '../state/student_planner_provider.dart';
import '../state/workspace_provider.dart';

/// Deterministic sample data for development and QA.
///
/// Debug builds only — [load] is a no-op in profile and release, so this can
/// never reach a user.
///
/// The dataset is chosen so that every rule-based feature actually fires.
/// Empty stores make most widgets render their empty state, which proves
/// nothing about whether they work.
abstract final class SampleData {
  /// Ids use a `seed-` prefix deliberately.
  ///
  /// [FinanceProvider] strips a hardcoded set of legacy demo ids (`tx-1`…`tx-7`,
  /// `goal-1`…`goal-3`, `budget-1`…`budget-5`) on every load, so a seeder using
  /// those prefixes would appear to work and then silently vanish on restart.
  static const _prefix = 'seed';

  static bool get isAvailable => kDebugMode;

  static Future<void> load({
    required FinanceProvider finance,
    required PlannerProvider planner,
    required WorkspaceProvider workspace,
    required BudgetPlanProvider budgetPlans,
    required StudentPlannerProvider students,
  }) async {
    if (!kDebugMode) return;

    final today = DateTime.now();
    String iso(DateTime d) => isoDate(d);

    // ---------------------------------------------------------- transactions
    final transactions = <FinanceTransaction>[];
    var n = 0;

    void add({
      required String name,
      required double amount,
      required String category,
      required DateTime date,
      TransactionType type = TransactionType.expense,
      bool unplanned = false,
      List<ReasonTag> tags = const [],
      String? note,
    }) {
      n++;
      transactions.add(
        FinanceTransaction(
          id: '$_prefix-tx-$n',
          name: name,
          amount: amount,
          type: type,
          category: category,
          date: iso(date),
          note: note,
          icon: categoryIcons[category],
          createdAt: date.toIso8601String(),
          isUnplanned: unplanned,
          reasonTags: tags,
        ),
      );
    }

    // Roughly three months of ordinary spending across every category, with a
    // deterministic but uneven spread so the charts and daily averages look
    // like real life rather than a flat line.
    const everyday = <(String, String, double)>[
      ('Lunch', 'Food', 12.40),
      ('Bus pass', 'Transport', 3.20),
      ('Groceries run', 'Groceries', 41.80),
      ('Cinema', 'Entertainment', 15.00),
      ('Phone bill', 'Utilities', 22.00),
      ('T-shirt', 'Shopping', 18.50),
      ('Pharmacy', 'Health', 9.75),
      ('Textbook', 'Education', 54.00),
      ('Train home', 'Travel', 32.00),
      ('Coffee', 'Food', 4.50),
    ];

    for (var day = 88; day >= 0; day--) {
      final date = today.subtract(Duration(days: day));
      // Two or three entries most days, none on some, so "average per day"
      // and the burn-rate chart have texture.
      if (day % 7 == 3) continue;
      final count = day % 5 == 0 ? 3 : 2;
      for (var k = 0; k < count; k++) {
        final pick = everyday[(day + k * 3) % everyday.length];
        add(
          name: pick.$1,
          category: pick.$2,
          amount: pick.$3,
          date: DateTime(date.year, date.month, date.day, 9 + k * 4),
        );
      }
    }

    // Rent is monthly, not daily. Leaving it in the everyday rotation charged
    // it roughly fifteen times and swamped every other category.
    for (var m = 3; m >= 0; m--) {
      add(
        name: 'Rent share',
        category: 'Housing',
        amount: 380,
        date: DateTime(today.year, today.month - m, 1),
      );
    }

    // Monthly income so the six-month bar chart has both series.
    for (var m = 3; m >= 0; m--) {
      final date = DateTime(today.year, today.month - m, 2);
      add(
        name: 'Part-time shift',
        category: 'Salary',
        amount: 900,
        date: date,
        type: TransactionType.income,
      );
    }

    // A genuine subscription: same merchant, ~30-day spacing, amounts within
    // 15%. Without this `detectSubscriptions` never fires and both the
    // Recurring Charges card and the Waste Auditor widget stay empty.
    for (var m = 3; m >= 0; m--) {
      add(
        name: 'Netflix',
        category: 'Entertainment',
        amount: 15.99,
        date: today.subtract(Duration(days: m * 30)),
        note: 'Recurring: monthly',
      );
    }
    for (var m = 2; m >= 0; m--) {
      add(
        name: 'Spotify',
        category: 'Entertainment',
        amount: 9.99,
        date: today.subtract(Duration(days: m * 30 + 5)),
        note: 'Recurring: monthly',
      );
    }

    // Unplanned spending clustered on Friday evenings, so `behaviorInsight`
    // clears its "at least two in one bucket" threshold and the Spending
    // Pattern card appears.
    var fridays = 0;
    for (var back = 0; back < 40 && fridays < 3; back++) {
      final d = today.subtract(Duration(days: back));
      if (d.weekday != DateTime.friday) continue;
      fridays++;
      add(
        name: 'Night out',
        category: 'Entertainment',
        amount: 28.00,
        date: DateTime(d.year, d.month, d.day, 21),
        unplanned: true,
        tags: const [ReasonTag.social],
      );
    }

    // ------------------------------------------------------- goals & budgets
    final goals = <SavingsGoal>[
      const SavingsGoal(
        id: '$_prefix-goal-trip',
        name: 'Trip to Goa',
        current: 480,
        target: 1200,
        icon: '✈️',
      ),
      const SavingsGoal(
        id: '$_prefix-goal-laptop',
        name: 'New laptop',
        current: 150,
        target: 900,
        icon: '💻',
      ),
      // Complete, so the disabled contribute button gets exercised.
      const SavingsGoal(
        id: '$_prefix-goal-buffer',
        name: 'Emergency buffer',
        current: 500,
        target: 500,
        icon: '🛟',
      ),
    ];

    final budgets = <BudgetCategory>[
      // Deliberately near its limit so the 80% budget-alert rule fires.
      const BudgetCategory(
        id: '$_prefix-budget-food',
        name: 'Food',
        monthlyLimit: 220,
      ),
      const BudgetCategory(
        id: '$_prefix-budget-transport',
        name: 'Transport',
        monthlyLimit: 120,
      ),
      const BudgetCategory(
        id: '$_prefix-budget-ent',
        name: 'Entertainment',
        monthlyLimit: 150,
      ),
    ];

    finance.replaceAll(
      transactions: transactions,
      goals: goals,
      budgets: budgets,
      // Comfortably above total seeded spending, so `availableBalance` stays
      // positive and the allowance-based widgets (Safe-to-Spend, daily budget,
      // Smart Cards) show real numbers rather than a flat zero.
      manualBalance: 6500,
    );

    // -------------------------------------------------------------- planner
    planner.replaceAll(
      plans: [
        (title: 'Weekly groceries', estimate: 45.0, date: iso(today)),
        (
          title: 'Train ticket',
          estimate: 32.0,
          date: iso(today.add(const Duration(days: 2)))
        ),
      ],
      rangeStart: today,
      rangeEnd: today.add(const Duration(days: 13)),
      geoProfileKey: 'india-metro',
    );

    // --------------------------------------------------------- budget plans
    // `people > 1` matters: the Roommate Sync widget only shows split plans,
    // so a solo plan would leave it empty.
    budgetPlans.replaceAll([
      BudgetPlan(
        id: '$_prefix-bp-goa',
        title: 'Goa weekend',
        planType: BudgetPlanType.trip,
        dateFrom: iso(today.add(const Duration(days: 12))),
        dateTo: iso(today.add(const Duration(days: 15))),
        people: 4,
        items: const [
          BudgetLineItem(id: '$_prefix-bi-hotel', name: 'Hotel', estimate: 220),
          BudgetLineItem(id: '$_prefix-bi-travel', name: 'Train', estimate: 96),
          BudgetLineItem(id: '$_prefix-bi-food', name: 'Food', estimate: 140),
        ],
        createdAt: today.toIso8601String(),
      ),
      BudgetPlan(
        id: '$_prefix-bp-dinner',
        title: 'Farewell dinner',
        planType: BudgetPlanType.outing,
        dateFrom: iso(today.add(const Duration(days: 5))),
        people: 6,
        items: const [
          BudgetLineItem(id: '$_prefix-bi-meal', name: 'Set menu', estimate: 180),
        ],
        createdAt: today.toIso8601String(),
      ),
    ]);

    // ------------------------------------------------------- student planner
    students.replaceAll(
      horizonDays: 30,
      upcomingBills: 120,
      incomeStreams: const [
        IncomeStream(
          id: '$_prefix-inc-shifts',
          name: 'Weekend shifts',
          amount: 85,
          cadence: IncomeCadence.weekly,
        ),
        IncomeStream(
          id: '$_prefix-inc-stipend',
          name: 'Stipend',
          amount: 300,
          cadence: IncomeCadence.monthly,
        ),
      ],
      fixedCosts: const [
        FixedCost(id: '$_prefix-fc-rent', name: 'Rent', amount: 380),
        FixedCost(id: '$_prefix-fc-phone', name: 'Phone', amount: 22),
      ],
      socialPlans: [
        SocialPlan(
          id: '$_prefix-social-dinner',
          title: 'Birthday dinner',
          date: iso(today.add(const Duration(days: 4))),
          lowEstimate: 25,
          realisticEstimate: 45,
          stretchEstimate: 70,
          splitCount: 4,
          note: 'Splitting with the flat',
        ),
      ],
      loanLumpSum: 4200,
      loanSafetyBuffer: 350,
      streakDates: [
        iso(today),
        iso(today.subtract(const Duration(days: 1))),
        iso(today.subtract(const Duration(days: 2))),
      ],
    );

    // ------------------------------------------------------------ workspace
    workspace.replaceAll([
      for (final type in WorkspaceWidgetType.values)
        WorkspaceWidget(
          id: '$_prefix-w-${type.name}',
          type: type,
          size: WidgetSize.medium,
        ),
    ]);
  }

  /// Clears everything the seeder wrote, reusing each store's own reset.
  static Future<void> clear({
    required FinanceProvider finance,
    required PlannerProvider planner,
    required WorkspaceProvider workspace,
    required BudgetPlanProvider budgetPlans,
    required StudentPlannerProvider students,
  }) async {
    await finance.resetAll();
    await planner.resetAll();
    await budgetPlans.resetAll();
    await students.resetAll();
    await workspace.clear();
  }
}
