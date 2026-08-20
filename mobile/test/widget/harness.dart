import 'package:cash_compass/app/theme/app_theme.dart';
import 'package:cash_compass/app/theme/app_tokens.dart';
import 'package:cash_compass/models/budget_category.dart';
import 'package:cash_compass/models/budget_plan.dart';
import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/services/prefs.dart';
import 'package:cash_compass/state/auth_provider.dart';
import 'package:cash_compass/state/budget_plan_provider.dart';
import 'package:cash_compass/state/currency_provider.dart';
import 'package:cash_compass/state/finance_provider.dart';
import 'package:cash_compass/state/planner_provider.dart';
import 'package:cash_compass/state/student_planner_provider.dart';
import 'package:cash_compass/state/theme_provider.dart';
import 'package:cash_compass/state/workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// In-memory [Prefs] so tests never touch disk or need platform channels.
class FakePrefs implements Prefs {
  final Map<String, Object?> store = {};

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      store[key] = value;

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      store[key] as Map<String, dynamic>?;

  @override
  Future<void> remove(String key) async => store.remove(key);

  @override
  Future<String?> getString(String key) async => store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => store[key] = value;

  @override
  Future<bool?> getBool(String key) async => store[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => store[key] = value;

  @override
  Future<List<dynamic>?> getJsonList(String key) async =>
      store[key] as List<dynamic>?;

  @override
  Future<void> setJsonList(String key, List<dynamic> value) async =>
      store[key] = value;

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final k in keys) {
      store.remove(k);
    }
  }
}

/// The set of stores an app screen needs.
class TestStores {
  TestStores._({
    required this.finance,
    required this.currency,
    required this.planner,
    required this.workspace,
    required this.budgetPlans,
    required this.students,
    required this.theme,
    required this.auth,
  });

  final FinanceProvider finance;
  final CurrencyProvider currency;
  final PlannerProvider planner;
  final WorkspaceProvider workspace;
  final BudgetPlanProvider budgetPlans;
  final StudentPlannerProvider students;
  final ThemeProvider theme;
  final AuthProvider auth;

  /// Stores with nothing in them — where null and divide-by-zero faults live.
  factory TestStores.empty() {
    final prefs = FakePrefs();
    return TestStores._(
      finance: FinanceProvider(prefs),
      currency: CurrencyProvider(prefs),
      planner: PlannerProvider(prefs),
      workspace: WorkspaceProvider(prefs),
      budgetPlans: BudgetPlanProvider(prefs),
      students: StudentPlannerProvider(prefs),
      theme: ThemeProvider(prefs),
      auth: AuthProvider(prefs),
    );
  }

  /// Stores holding enough data that every rule-based widget has content.
  ///
  /// Built inline rather than calling the app's seeder so the fixtures stay
  /// small and a test failure points at the widget, not at the seeder.
  factory TestStores.populated() {
    final s = TestStores.empty();
    final today = DateTime.now();
    String iso(DateTime d) => isoDate(d);

    final transactions = <FinanceTransaction>[
      for (var i = 0; i < 24; i++)
        FinanceTransaction(
          id: 'fixture-tx-$i',
          name: ['Lunch', 'Bus', 'Groceries', 'Cinema'][i % 4],
          amount: 8.0 + i,
          type: i % 6 == 0 ? TransactionType.income : TransactionType.expense,
          category: ['Food', 'Transport', 'Groceries', 'Entertainment'][i % 4],
          date: iso(today.subtract(Duration(days: i))),
          createdAt: today.subtract(Duration(days: i)).toIso8601String(),
        ),
      // Monthly cadence within 15% so detectSubscriptions fires.
      for (var m = 0; m < 3; m++)
        FinanceTransaction(
          id: 'fixture-sub-$m',
          name: 'Netflix',
          amount: 15.99,
          type: TransactionType.expense,
          category: 'Entertainment',
          date: iso(today.subtract(Duration(days: m * 30))),
        ),
      // Two tagged unplanned expenses in the same bucket so behaviorInsight
      // clears its threshold.
      for (var w = 0; w < 2; w++)
        FinanceTransaction(
          id: 'fixture-unplanned-$w',
          name: 'Night out',
          amount: 30,
          type: TransactionType.expense,
          category: 'Entertainment',
          date: iso(today.subtract(Duration(days: 7 * w))),
          createdAt: DateTime(today.year, today.month, today.day - 7 * w, 21)
              .toIso8601String(),
          isUnplanned: true,
          reasonTags: const [ReasonTag.social],
        ),
    ];

    s.finance.replaceAll(
      transactions: transactions,
      goals: const [
        SavingsGoal(
          id: 'fixture-goal-trip',
          name: 'Trip to Goa',
          current: 300,
          target: 1000,
          icon: '✈️',
        ),
        SavingsGoal(
          id: 'fixture-goal-laptop',
          name: 'Laptop',
          current: 90,
          target: 800,
          icon: '💻',
        ),
        SavingsGoal(
          id: 'fixture-goal-done',
          name: 'Buffer',
          current: 500,
          target: 500,
          icon: '🛟',
        ),
      ],
      budgets: const [
        BudgetCategory(id: 'fixture-b1', name: 'Food', monthlyLimit: 100),
        BudgetCategory(id: 'fixture-b2', name: 'Transport', monthlyLimit: 60),
        BudgetCategory(id: 'fixture-b3', name: 'Entertainment', monthlyLimit: 80),
      ],
      manualBalance: 1500,
    );

    s.budgetPlans.replaceAll([
      BudgetPlan(
        id: 'fixture-bp',
        title: 'Goa weekend',
        planType: BudgetPlanType.trip,
        dateFrom: iso(today),
        people: 4,
        items: const [
          BudgetLineItem(id: 'fixture-bi', name: 'Hotel', estimate: 200),
        ],
        createdAt: today.toIso8601String(),
      ),
    ]);

    return s;
  }
}

/// Wraps [child] in the providers and theme a real screen would have.
///
/// [textScale] exercises the Settings font slider range (85–120%) plus the OS
/// accessibility scale — the combination that turns "just fits" into overflow.
Widget wrapForTest(
  Widget child, {
  required TestStores stores,
  double textScale = 1.0,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: stores.finance),
      ChangeNotifierProvider.value(value: stores.currency),
      ChangeNotifierProvider.value(value: stores.planner),
      ChangeNotifierProvider.value(value: stores.workspace),
      ChangeNotifierProvider.value(value: stores.budgetPlans),
      ChangeNotifierProvider.value(value: stores.students),
      ChangeNotifierProvider.value(value: stores.theme),
      ChangeNotifierProvider.value(value: stores.auth),
    ],
    child: MaterialApp(
      theme: buildTheme(appThemes[defaultThemeName]!),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Pumps [child] and fails if anything threw — including a layout overflow,
/// which Flutter surfaces as a FlutterError rather than an exception at the
/// call site.
Future<void> pumpAndExpectClean(
  WidgetTester tester,
  Widget child, {
  required TestStores stores,
  double textScale = 1.0,
  required String reason,
}) async {
  await tester.pumpWidget(
    wrapForTest(child, stores: stores, textScale: textScale),
  );

  // Let the stores' debounced write timers fire. Building the fixtures goes
  // through the normal persist path, and the test framework asserts that no
  // timer outlives the widget tree.
  await tester.pump(const Duration(milliseconds: 600));

  expect(tester.takeException(), isNull, reason: reason);

  // Replace the tree so animated widgets dispose their tickers. The growth gem
  // repeats forever, so `pumpAndSettle` would spin here instead of settling.
  await tester.pumpWidget(const SizedBox.shrink());
}
