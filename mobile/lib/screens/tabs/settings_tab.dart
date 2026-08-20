import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_tokens.dart';
import '../../dev/sample_data.dart';
import '../../state/auth_provider.dart';
import '../../state/budget_plan_provider.dart';
import '../../state/currency_provider.dart';
import '../../state/planner_provider.dart';
import '../../state/student_planner_provider.dart';
import '../../state/workspace_provider.dart';
import '../../state/finance_provider.dart';
import '../../state/theme_provider.dart';

/// Settings tab. Port of `SettingsStudio.tsx`.
///
/// The currency and theme controls live here only — the desktop Right-Ctrl and
/// Right-Alt keyboard shortcuts have no meaning on a phone.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeProvider>();
    final currency = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _Section(
          title: 'Currency',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<AppCurrency>(
                segments: [
                  for (final c in AppCurrency.values)
                    ButtonSegment(value: c, label: Text(c.code)),
                ],
                selected: {currency.currency},
                onSelectionChanged: (s) => currency.setCurrency(s.first),
              ),
              const SizedBox(height: 10),
              Text(
                currency.ratesError ??
                    (currency.lastUpdated == null
                        ? 'Using fallback rates.'
                        : 'Rates updated '
                            '${_relative(currency.lastUpdated!)}.'),
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: currency.ratesLoading
                    ? null
                    : () => currency.refreshRates(),
                child: Text(
                  currency.ratesLoading ? 'Refreshing…' : 'Refresh rates',
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Theme',
          child: DropdownButtonFormField<String>(
            initialValue: themeState.themeName,
            items: [
              for (final entry in appThemes.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.label),
                ),
            ],
            onChanged: (name) {
              if (name != null) themeState.setTheme(name);
            },
          ),
        ),
        _Section(
          title: 'Typography',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FontPack>(
                initialValue: themeState.fontPack,
                items: const [
                  DropdownMenuItem(
                    value: FontPack.defaultPack,
                    child: Text('Default'),
                  ),
                  DropdownMenuItem(
                    value: FontPack.editorial,
                    child: Text('Editorial'),
                  ),
                  DropdownMenuItem(
                    value: FontPack.mono,
                    child: Text('Mono'),
                  ),
                ],
                onChanged: (pack) {
                  if (pack != null) themeState.setFontPack(pack);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Text size — ${themeState.fontScalePercent.round()}%',
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                value: themeState.fontScalePercent,
                min: 85,
                max: 120,
                divisions: 7,
                label: '${themeState.fontScalePercent.round()}%',
                onChanged: (v) => themeState.setFontScale(v),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Account',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.watch<AuthProvider>().isDemoMode
                    ? 'Demo mode — data stays on this device.'
                    : 'Signed in as '
                        '${context.watch<AuthProvider>().user?.displayName ?? ''}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(
                  context.watch<AuthProvider>().isDemoMode
                      ? 'Leave demo mode'
                      : 'Sign out',
                ),
                onPressed: () => context.read<AuthProvider>().signOut(),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Data',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset all finance data'),
            onPressed: () => _confirmReset(context),
          ),
        ),
        // Debug builds only — SampleData.load is a no-op elsewhere, and this
        // section is not rendered at all in profile or release.
        if (SampleData.isAvailable)
          _Section(
            title: 'Developer',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug build only. Loads a deterministic dataset so every '
                  'widget has something real to show.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _seed(context, load: true),
                      child: const Text('Load sample data'),
                    ),
                    OutlinedButton(
                      onPressed: () => _seed(context, load: false),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _relative(DateTime then) {
    final diff = DateTime.now().difference(then);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _seed(BuildContext context, {required bool load}) async {
    final finance = context.read<FinanceProvider>();
    final planner = context.read<PlannerProvider>();
    final workspace = context.read<WorkspaceProvider>();
    final budgetPlans = context.read<BudgetPlanProvider>();
    final students = context.read<StudentPlannerProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (load) {
      await SampleData.load(
        finance: finance,
        planner: planner,
        workspace: workspace,
        budgetPlans: budgetPlans,
        students: students,
      );
    } else {
      await SampleData.clear(
        finance: finance,
        planner: planner,
        workspace: workspace,
        budgetPlans: budgetPlans,
        students: students,
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(load ? 'Sample data loaded.' : 'Sample data cleared.'),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final finance = context.read<FinanceProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
          'This permanently deletes all transactions, goals, and budgets on '
          'this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await finance.resetAll();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
