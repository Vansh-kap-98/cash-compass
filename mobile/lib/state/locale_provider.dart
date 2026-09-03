import 'package:flutter/widgets.dart';

import '../services/prefs.dart';

/// The languages offered in Settings.
///
/// [system] defers to the device language, which is what a fresh install
/// starts on: someone whose phone is already in Russian should not have to
/// find the setting before the app speaks to them.
enum AppLanguage {
  system('system', null),
  english('en', Locale('en')),
  russian('ru', Locale('ru'));

  const AppLanguage(this.id, this.locale);

  /// Persisted value. Stable across releases — do not renumber or rename.
  final String id;

  /// The locale to force, or null to follow the device.
  final Locale? locale;

  static AppLanguage fromId(String? id) {
    for (final language in AppLanguage.values) {
      if (language.id == id) return language;
    }
    return AppLanguage.system;
  }
}

/// Holds the chosen interface language.
///
/// Kept apart from [ThemeProvider] despite both being display preferences:
/// this one feeds `MaterialApp.locale` rather than `ThemeData`, and a language
/// change must rebuild every string in the tree, not just re-skin it.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._prefs);

  final Prefs _prefs;

  AppLanguage language = AppLanguage.system;
  bool loaded = false;

  /// What `MaterialApp.locale` should be. Null hands the choice back to
  /// Flutter, which resolves the device locale against `supportedLocales`.
  Locale? get locale => language.locale;

  Future<void> load() async {
    language = AppLanguage.fromId(await _prefs.getString(PrefsKeys.language));
    loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage next) async {
    if (next == language) return;
    language = next;
    notifyListeners();
    await _prefs.setString(PrefsKeys.language, next.id);
  }
}
