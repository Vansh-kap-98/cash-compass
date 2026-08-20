import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/day_plan.dart';
import '../models/json_utils.dart';
import '../services/prefs.dart';
import 'finance_provider.dart';

/// Day plans, the budgeting date range, and the chosen location profile.
///
/// Port of the planner state in `DashboardPlanner.tsx` plus the date range that
/// `SoftBloomLayout.tsx` owned on the web. Both live here because the daily
/// budget is derived from them together.
///
/// Follows the same debounced-write pattern as [FinanceProvider]: repaint
/// immediately, coalesce disk writes, flush on app pause.
class PlannerProvider extends ChangeNotifier {
  PlannerProvider(this._prefs);

  final Prefs _prefs;

  List<DayPlan> plans = [];
  DateTime rangeStart = DateTime.now();
  DateTime rangeEnd = DateTime.now().add(const Duration(days: 7));
  String geoProfileKey = 'us-city';

  bool loaded = false;

  /// Bumped on every mutation — `select` on this, not on [plans], since the
  /// list is mutated in place.
  int revision = 0;

  Future<void> load() async {
    final plansJson = await _prefs.getJsonList(PrefsKeys.dayPlans);
    if (plansJson != null) {
      plans = decodeList(plansJson, DayPlan.fromJson);
    }

    final range = await _prefs.getJson(PrefsKeys.dateRange);
    if (range != null) {
      final start = DateTime.tryParse(range['start'] as String? ?? '');
      final end = DateTime.tryParse(range['end'] as String? ?? '');
      if (start != null && end != null && !end.isBefore(start)) {
        rangeStart = start;
        rangeEnd = end;
      }
    }

    final geo = await _prefs.getString(PrefsKeys.geoProfile);
    if (geo != null && geo.isNotEmpty) geoProfileKey = geo;

    loaded = true;
    notifyListeners();
  }

  /// Plans falling on [date] (ISO `yyyy-MM-dd`).
  List<DayPlan> plansFor(String date) =>
      plans.where((p) => p.date == date).toList();

  /// Total planned spend for [date], in USD.
  double plannedFor(String date) =>
      plansFor(date).fold(0.0, (sum, p) => sum + p.estimate);

  void addPlan({
    required String title,
    required double estimate,
    required String date,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || !estimate.isFinite || estimate <= 0) return;
    plans.insert(
      0,
      DayPlan(
        id: 'plan-${DateTime.now().millisecondsSinceEpoch}',
        title: trimmed,
        estimate: estimate,
        date: date,
      ),
    );
    _persist();
  }

  void removePlan(String id) {
    final before = plans.length;
    plans.removeWhere((p) => p.id == id);
    if (plans.length != before) _persist();
  }

  void setRange({DateTime? start, DateTime? end}) {
    var nextStart = start ?? rangeStart;
    var nextEnd = end ?? rangeEnd;
    // Keep the range valid rather than rejecting the edit: if the user moves
    // the start past the end, carry the end along with it.
    if (nextEnd.isBefore(nextStart)) {
      if (start != null) {
        nextEnd = nextStart;
      } else {
        nextStart = nextEnd;
      }
    }
    rangeStart = nextStart;
    rangeEnd = nextEnd;
    _persist();
  }

  void setGeoProfile(String key) {
    if (key == geoProfileKey) return;
    geoProfileKey = key;
    _persist();
  }

  /// Replaces the planner state in one write. Used by the dev seeder.
  void replaceAll({
    List<({String title, double estimate, String date})>? plans,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? geoProfileKey,
  }) {
    if (plans != null) {
      this.plans = [
        for (var i = 0; i < plans.length; i++)
          DayPlan(
            id: 'seed-plan-$i',
            title: plans[i].title,
            estimate: plans[i].estimate,
            date: plans[i].date,
          ),
      ];
    }
    if (rangeStart != null) this.rangeStart = rangeStart;
    if (rangeEnd != null) this.rangeEnd = rangeEnd;
    if (geoProfileKey != null) this.geoProfileKey = geoProfileKey;
    _persist();
  }

  Future<void> resetAll() async {
    plans = [];
    rangeStart = DateTime.now();
    rangeEnd = DateTime.now().add(const Duration(days: 7));
    revision++;
    _writeTimer?.cancel();
    _writePending = false;
    notifyListeners();
    await _prefs.removeAll([PrefsKeys.dayPlans, PrefsKeys.dateRange]);
  }

  // ------------------------------------------------------------ persistence

  Timer? _writeTimer;
  bool _writePending = false;

  static const _writeDebounce = Duration(milliseconds: 500);

  void _persist() {
    revision++;
    notifyListeners();
    _writePending = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, flush);
  }

  Future<void> flush() async {
    if (!_writePending) return;
    _writeTimer?.cancel();
    _writePending = false;
    try {
      await _prefs.setJsonList(
        PrefsKeys.dayPlans,
        plans.map((p) => p.toJson()).toList(),
      );
      await _prefs.setJson(PrefsKeys.dateRange, {
        'start': isoDate(rangeStart),
        'end': isoDate(rangeEnd),
      });
      await _prefs.setString(PrefsKeys.geoProfile, geoProfileKey);
    } catch (error) {
      debugPrint('Planner write failed: $error');
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
