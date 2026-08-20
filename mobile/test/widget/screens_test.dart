import 'package:cash_compass/screens/auth_screen.dart';
import 'package:cash_compass/screens/budget_plan_screen.dart';
import 'package:cash_compass/screens/tabs/dashboard_tab.dart';
import 'package:cash_compass/screens/tabs/goals_tab.dart';
import 'package:cash_compass/screens/tabs/planner_tab.dart';
import 'package:cash_compass/screens/tabs/settings_tab.dart';
import 'package:cash_compass/screens/tabs/workspace_tab.dart';
import 'package:cash_compass/widgets/add_entry_sheet.dart';
import 'package:cash_compass/widgets/set_goal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Smoke-renders every screen empty and populated.
///
/// These do not assert on appearance — they assert that each screen builds at
/// all, which nothing verified before. Several of these screens had never been
/// rendered outside a manual emulator session.
void main() {
  final screens = <String, Widget Function()>{
    'DashboardTab': () => const DashboardTab(),
    'GoalsTab': () => const GoalsTab(),
    'PlannerTab': () => const PlannerTab(),
    'WorkspaceTab': () => const WorkspaceTab(),
    'SettingsTab': () => const SettingsTab(),
    'AddEntrySheet': () => const AddEntrySheet(),
    'SetGoalSheet': () => const SetGoalSheet(),
    'AuthScreen': () => const AuthScreen(),
  };

  group('screens build', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} · populated', (tester) async {
        await pumpAndExpectClean(
          tester,
          entry.value(),
          stores: TestStores.populated(),
          reason: '${entry.key} threw with data',
        );
      });

      testWidgets('${entry.key} · empty', (tester) async {
        await pumpAndExpectClean(
          tester,
          entry.value(),
          stores: TestStores.empty(),
          reason: '${entry.key} threw with no data',
        );
      });
    }

    testWidgets('BudgetPlanScreen · with a draft', (tester) async {
      final stores = TestStores.populated();
      // The screen renders a spinner without one, so start a draft first —
      // that is how the route is always entered in the app.
      stores.budgetPlans.startOrResumeDraft();

      await pumpAndExpectClean(
        tester,
        const BudgetPlanScreen(),
        stores: stores,
        reason: 'BudgetPlanScreen threw with an active draft',
      );
    });
  });

  group('screens survive a large text scale', () {
    // The Settings slider reaches 120% and Android accessibility goes further.
    // Rows of side-by-side fields are the first thing to break.
    for (final entry in screens.entries) {
      testWidgets('${entry.key} · 1.3x text', (tester) async {
        await pumpAndExpectClean(
          tester,
          entry.value(),
          stores: TestStores.populated(),
          textScale: 1.3,
          reason: '${entry.key} overflowed at 1.3x text scale',
        );
      });
    }
  });
}
