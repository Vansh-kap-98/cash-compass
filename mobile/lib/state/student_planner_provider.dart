import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dev/log.dart';
import '../logic/student_planner.dart';
import '../models/json_utils.dart';
import '../services/prefs.dart';
import 'finance_provider.dart' show todayIso;

/// Inputs for the Student Planner tools.
///
/// The web version held all of this in component state and lost it on every
/// reload, which made the tools close to useless. Everything here persists.
class StudentPlannerProvider extends ChangeNotifier {
  StudentPlannerProvider(this._prefs);

  final Prefs _prefs;

  int horizonDays = 30;
  double upcomingBills = 0;
  List<IncomeStream> incomeStreams = [];
  List<FixedCost> fixedCosts = [];
  List<SocialPlan> socialPlans = [];
  double loanLumpSum = 4200;
  double loanSafetyBuffer = 350;
  List<String> streakDates = [];

  bool loaded = false;
  int revision = 0;

  bool get isOnTrackToday => streakDates.contains(todayIso());

  Future<void> load() async {
    final j = await _prefs.getJson(PrefsKeys.studentPlanner);
    if (j != null) {
      horizonDays = (j['horizonDays'] as num?)?.toInt() ?? 30;
      upcomingBills = asDouble(j['upcomingBills']);
      loanLumpSum = asDouble(j['loanLumpSum'], fallback: 4200);
      loanSafetyBuffer = asDouble(j['loanSafetyBuffer'], fallback: 350);
      incomeStreams = decodeList(j['incomeStreams'], IncomeStream.fromJson);
      fixedCosts = decodeList(j['fixedCosts'], FixedCost.fromJson);
      socialPlans = decodeList(j['socialPlans'], SocialPlan.fromJson);
      streakDates = [
        for (final d in (j['streakDates'] as List? ?? const []))
          if (d is String) d,
      ];
    }
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'horizonDays': horizonDays,
        'upcomingBills': upcomingBills,
        'loanLumpSum': loanLumpSum,
        'loanSafetyBuffer': loanSafetyBuffer,
        'incomeStreams': incomeStreams.map((s) => s.toJson()).toList(),
        'fixedCosts': fixedCosts.map((c) => c.toJson()).toList(),
        'socialPlans': socialPlans.map((p) => p.toJson()).toList(),
        'streakDates': streakDates,
      };

  void setHorizon(int days) {
    horizonDays = days.clamp(7, 120);
    _persist();
  }

  void setUpcomingBills(double value) {
    upcomingBills = value.isFinite && value > 0 ? value : 0;
    _persist();
  }

  void setLoan({double? lumpSum, double? buffer}) {
    if (lumpSum != null && lumpSum.isFinite) {
      loanLumpSum = lumpSum < 0 ? 0 : lumpSum;
    }
    if (buffer != null && buffer.isFinite) {
      loanSafetyBuffer = buffer < 0 ? 0 : buffer;
    }
    _persist();
  }

  void addIncome(String name, double amount, IncomeCadence cadence) {
    if (name.trim().isEmpty || !amount.isFinite || amount <= 0) return;
    incomeStreams.insert(
      0,
      IncomeStream(
        id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        amount: amount,
        cadence: cadence,
      ),
    );
    _persist();
  }

  void removeIncome(String id) {
    incomeStreams.removeWhere((s) => s.id == id);
    _persist();
  }

  /// Adds a fixed cost.
  ///
  /// The web app declared `fixedCosts` with no setter and no UI, so its
  /// "Total essentials" was permanently zero. This makes the feature real.
  void addFixedCost(String name, double amount) {
    if (name.trim().isEmpty || !amount.isFinite || amount <= 0) return;
    fixedCosts.insert(
      0,
      FixedCost(
        id: 'fc-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        amount: amount,
      ),
    );
    _persist();
  }

  void removeFixedCost(String id) {
    fixedCosts.removeWhere((c) => c.id == id);
    _persist();
  }

  void addSocialPlan({
    required String title,
    required String date,
    required double low,
    required double realistic,
    required double stretch,
    required int splitCount,
    String? note,
  }) {
    if (title.trim().isEmpty || !realistic.isFinite || realistic <= 0) return;
    final split = splitCount < 1 ? 1 : splitCount;
    socialPlans.insert(
      0,
      SocialPlan(
        id: 'social-${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        date: date,
        lowEstimate: low.isFinite && low > 0 ? low : realistic,
        realisticEstimate: realistic,
        stretchEstimate:
            stretch.isFinite && stretch > realistic ? stretch : realistic,
        splitCount: split,
        note: note == null || note.trim().isEmpty ? null : note.trim(),
      ),
    );
    _persist();
  }

  void removeSocialPlan(String id) {
    socialPlans.removeWhere((p) => p.id == id);
    _persist();
  }

  /// Marks today on-track, or clears it if already marked.
  void toggleTodayOnTrack() {
    final today = todayIso();
    if (streakDates.contains(today)) {
      streakDates.remove(today);
    } else {
      streakDates.insert(0, today);
    }
    _persist();
  }

  /// Replaces the planner inputs in one write. Used by the dev seeder.
  void replaceAll({
    int? horizonDays,
    double? upcomingBills,
    List<IncomeStream>? incomeStreams,
    List<FixedCost>? fixedCosts,
    List<SocialPlan>? socialPlans,
    double? loanLumpSum,
    double? loanSafetyBuffer,
    List<String>? streakDates,
  }) {
    if (horizonDays != null) this.horizonDays = horizonDays.clamp(7, 120);
    if (upcomingBills != null) this.upcomingBills = upcomingBills;
    if (incomeStreams != null) this.incomeStreams = [...incomeStreams];
    if (fixedCosts != null) this.fixedCosts = [...fixedCosts];
    if (socialPlans != null) this.socialPlans = [...socialPlans];
    if (loanLumpSum != null) this.loanLumpSum = loanLumpSum;
    if (loanSafetyBuffer != null) this.loanSafetyBuffer = loanSafetyBuffer;
    if (streakDates != null) this.streakDates = [...streakDates];
    _persist();
  }

  Future<void> resetAll() async {
    horizonDays = 30;
    upcomingBills = 0;
    incomeStreams = [];
    fixedCosts = [];
    socialPlans = [];
    loanLumpSum = 4200;
    loanSafetyBuffer = 350;
    streakDates = [];
    revision++;
    _writeTimer?.cancel();
    _writePending = false;
    notifyListeners();
    await _prefs.remove(PrefsKeys.studentPlanner);
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
      await _prefs.setJson(PrefsKeys.studentPlanner, toJson());
    } catch (error) {
      logError('Student planner write', error);
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
