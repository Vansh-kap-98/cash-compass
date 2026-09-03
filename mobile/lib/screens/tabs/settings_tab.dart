import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_tokens.dart';
import '../../dev/sample_data.dart';
import '../../l10n/l10n.dart';
import '../../l10n/presenters.dart';
import '../../state/auth_provider.dart';
import '../../state/budget_plan_provider.dart';
import '../../state/currency_provider.dart';
import '../../state/locale_provider.dart';
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
    final l10n = context.l10n;
    final themeState = context.watch<ThemeProvider>();
    final currency = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Language sits at the top: someone who has opened Settings because
        // the app is in the wrong language should not have to read four other
        // section headings to find it.
        _Section(
          title: l10n.settingsLanguage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<AppLanguage>(
                initialValue: context.watch<LocaleProvider>().language,
                isExpanded: true,
                items: [
                  for (final language in AppLanguage.values)
                    DropdownMenuItem(
                      value: language,
                      child: Text(languageLabel(l10n, language)),
                    ),
                ],
                onChanged: (language) {
                  if (language != null) {
                    context.read<LocaleProvider>().setLanguage(language);
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                l10n.settingsLanguageSubtitle,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _Section(
          title: l10n.settingsCurrency,
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
                        ? l10n.settingsUsingFallbackRates
                        : l10n.settingsRatesUpdated(
                            _relative(l10n, currency.lastUpdated!),
                          )),
                style: theme.textTheme.bodySmall,
              ),
              TextButton(
                onPressed: currency.ratesLoading
                    ? null
                    : () => currency.refreshRates(),
                child: Text(
                  currency.ratesLoading
                      ? l10n.settingsRefreshing
                      : l10n.settingsRefreshRates,
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: l10n.settingsTheme,
          child: DropdownButtonFormField<String>(
            initialValue: themeState.themeName,
            items: [
              for (final entry in appThemes.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(themeLabel(l10n, entry.value)),
                ),
            ],
            onChanged: (name) {
              if (name != null) themeState.setTheme(name);
            },
          ),
        ),
        _Section(
          title: l10n.settingsTypography,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FontPack>(
                initialValue: themeState.fontPack,
                items: [
                  DropdownMenuItem(
                    value: FontPack.defaultPack,
                    child: Text(l10n.settingsFontDefault),
                  ),
                  DropdownMenuItem(
                    value: FontPack.editorial,
                    child: Text(l10n.settingsFontEditorial),
                  ),
                  DropdownMenuItem(
                    value: FontPack.mono,
                    child: Text(l10n.settingsFontMono),
                  ),
                ],
                onChanged: (pack) {
                  if (pack != null) themeState.setFontPack(pack);
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsTextSize(themeState.fontScalePercent.round()),
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
          title: l10n.settingsAccount,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.watch<AuthProvider>().isDemoMode
                    ? l10n.settingsDemoMode
                    : l10n.settingsSignedInAs(
                        context.watch<AuthProvider>().user?.displayName ?? '',
                      ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(
                  context.watch<AuthProvider>().isDemoMode
                      ? l10n.settingsLeaveDemo
                      : l10n.settingsSignOut,
                ),
                onPressed: () => context.read<AuthProvider>().signOut(),
              ),
            ],
          ),
        ),
        _Section(
          title: l10n.settingsData,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.settingsResetAll),
            onPressed: () => _confirmReset(context),
          ),
        ),
        // Debug builds only — SampleData.load is a no-op elsewhere, and this
        // section is not rendered at all in profile or release.
        if (SampleData.isAvailable)
          _Section(
            title: l10n.settingsDeveloper,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsDeveloperBody,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _seed(context, load: true),
                      child: Text(l10n.settingsLoadSample),
                    ),
                    OutlinedButton(
                      onPressed: () => _seed(context, load: false),
                      child: Text(l10n.actionClear),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _relative(AppLocalizations l10n, DateTime then) {
    final diff = DateTime.now().difference(then);
    if (diff.inMinutes < 1) return l10n.relativeJustNow;
    if (diff.inMinutes < 60) return l10n.relativeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.relativeHoursAgo(diff.inHours);
    return l10n.relativeDaysAgo(diff.inDays);
  }

  Future<void> _seed(BuildContext context, {required bool load}) async {
    final l10n = context.l10n;
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
        content: Text(
          load ? l10n.settingsSampleLoaded : l10n.settingsSampleCleared,
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final finance = context.read<FinanceProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.actionReset),
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
