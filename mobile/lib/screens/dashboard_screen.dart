import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/finance_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/goals_tab.dart';
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

  static const _titles = ['Dashboard', 'Goals', 'Workspace', 'Settings'];

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
          WorkspaceTab(),
          SettingsTab(),
        ],
      ),
      // Temporary: proves the write-and-persist path before the real Add Entry
      // sheet lands. Replace with the sheet in the entry/goals milestone.
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => addSampleExpense(context),
              child: const Icon(Icons.add),
            )
          : null,
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
