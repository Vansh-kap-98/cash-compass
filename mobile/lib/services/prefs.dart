import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../dev/log.dart';

/// Every storage key the app uses, in one place.
///
/// These deliberately keep the web app's key names. Nothing reads them across
/// platforms today, but keeping them identical means a JSON blob exported from
/// the browser can be dropped straight into the phone (and vice versa) without
/// a translation step.
abstract final class PrefsKeys {
  static const finance = 'cash-compass-finance-v1';
  static const workspace = 'cash-compass-workspace-v3';
  static const dayPlans = 'cash-compass-day-plans-v1';
  static const budgetPlans = 'cash-compass-budget-plans-v1';

  /// In-progress budget plan. Replaces the web app's "minimise to edge tab"
  /// affordance, which only made sense as a desktop window.
  static const budgetDraft = 'cash-compass-budget-draft-v1';

  /// Student planner inputs. The web app persisted none of this.
  static const studentPlanner = 'cash-compass-student-planner-v1';
  static const dateRange = 'cash-compass-range-v1';
  static const uiSettings = 'cash-compass-ui-settings-v1';
  static const exchangeRates = 'cash-compass-exchange-rates-v1';
  static const fixedLiabilities = 'cash-compass-fixed-liabilities-v1';
  static const region = 'cash-compass-region';

  /// Not present in the web app — the location profile was component state
  /// there and reset on every reload.
  static const geoProfile = 'cash-compass-geo-profile-v1';
  static const demoMode = 'cash-compass-demo-mode-v1';
  static const completedTour = 'cash-compass-has-completed-tour-v1';
  static const theme = 'dashboard-theme';
  static const currency = 'dashboard-currency';

  /// Keys cleared when entering demo mode, matching `enableDemoMode` in
  /// `AuthContext.tsx`. Note the web app deliberately leaves the tour flag,
  /// region, and UI settings alone — those are device preferences, not data.
  static const clearedOnDemoMode = <String>[
    finance,
    dateRange,
    dayPlans,
  ];
}

/// Thin wrapper over [SharedPreferencesAsync] for reading and writing JSON.
///
/// The important behavioural difference from the web app: `localStorage` is
/// synchronous, this is not. Stores therefore load once at startup into
/// in-memory fields and write through in the background, rather than hitting
/// disk on every read.
class Prefs {
  Prefs([SharedPreferencesAsync? backing])
      : _prefs = backing ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  Future<String?> getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<bool?> getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// Reads and decodes a JSON object, returning null rather than throwing if the
  /// stored value is absent or corrupt. A single bad blob must not prevent the
  /// app from starting.
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (error) {
      logError('Prefs.getJson("$key")', error);
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  /// Reads and decodes a JSON array, with the same tolerance as [getJson].
  Future<List<dynamic>?> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
      return null;
    } catch (error) {
      logError('Prefs.getJsonList("$key")', error);
      return null;
    }
  }

  Future<void> setJsonList(String key, List<dynamic> value) =>
      setString(key, jsonEncode(value));

  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }
}
