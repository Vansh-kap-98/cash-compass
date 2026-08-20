import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_provider.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/set_goal_sheet.dart';
import 'budget_plan_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/goals_tab.dart';
import 'tabs/planner_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/workspace_tab.dart';

/// The app shell.
///
/// Replaces `SoftBloomLayout`'s sidebar + mobile pill bar with a single
/// [NavigationBar] — on a phone there is only the mobile pattern, so the
/// desktop sidebar has no equivalent.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Goals',
    'Planner',
    'Workspace',
    'Settings',
  ];

  /// Index of the Settings tab, where a FAB would be meaningless.
  static const _settingsIndex = 4;

  Future<void> _openQuickActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Add Entry'),
              subtitle: const Text('Log an expense or income'),
              onTap: () => Navigator.pop(sheetContext, 'entry'),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Set Goal'),
              subtitle: const Text('Create a savings target'),
              onTap: () => Navigator.pop(sheetContext, 'goal'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Plan Budget'),
              subtitle: const Text('Cost out a trip, outing, or event'),
              onTap: () => Navigator.pop(sheetContext, 'budget'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'entry':
        await AddEntrySheet.show(context);
      case 'goal':
        await SetGoalSheet.show(context);
      case 'budget':
        await BudgetPlanScreen.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Until the stores have hydrated, show a bare themed screen rather than
    // rendering zeroes that would immediately be replaced.
    final loaded = context.select<FinanceProvider, bool>((f) => f.loaded);
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      // IndexedStack keeps each tab alive, preserving scroll position the way
      // the web app's in-page tab switcher did.
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          GoalsTab(),
          PlannerTab(),
          WorkspaceTab(),
          SettingsTab(),
        ],
      ),
      // One FAB opening a chooser, rather than the web app's three stacked
      // buttons — stacked FABs are not an Android pattern.
      floatingActionButton: _index == _settingsIndex
          ? null
          : FloatingActionButton(
              onPressed: () => _openQuickActions(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Workspace',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
