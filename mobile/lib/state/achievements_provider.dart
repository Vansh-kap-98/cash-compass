import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dev/log.dart';
import '../logic/badges.dart';
import '../services/prefs.dart';
import 'finance_provider.dart';

/// Rewards & Badges state.
///
/// Everything this needs beyond `FinanceProvider`'s own fields and the read
/// literacy-card count is a small log this provider owns entirely — an
/// "active today" date list, a "contributed to a goal today" date list, and a
/// set of subscriptions the user marked canceled. Nothing outside this file
/// writes to them. See `lib/logic/badges.dart` for the unlock rules
/// themselves, which are pure and unit-tested independently of this class.
class AchievementsProvider extends ChangeNotifier {
  AchievementsProvider(this._prefs);

  final Prefs _prefs;

  Set<String> unlockedBadgeIds = {};
  List<String> activityDates = [];
  List<String> savingsActivityDates = [];
  Set<String> canceledSubscriptionSignatures = {};

  bool loaded = false;

  /// Last-seen `current` per goal id, used only to notice a contribution
  /// happened since the previous [recompute]. Not persisted — it is rebuilt
  /// from whatever `FinanceProvider` reports on the next call, so a cold
  /// start never misattributes existing balances as "today's" activity.
  final Map<String, double> _lastKnownGoalCurrent = {};

  List<String> _pendingCelebrations = [];

  Future<void> load() async {
    final json = await _prefs.getJson(PrefsKeys.achievements);
    if (json != null) _applyJson(json);
    loaded = true;
    notifyListeners();
  }

  void _applyJson(Map<String, dynamic> j) {
    unlockedBadgeIds = _stringSet(j['unlockedBadgeIds']);
    activityDates = _stringList(j['activityDates']);
    savingsActivityDates = _stringList(j['savingsActivityDates']);
    canceledSubscriptionSignatures = _stringSet(j['canceledSubscriptionSignatures']);
  }

  static Set<String> _stringSet(Object? raw) =>
      raw is List ? {for (final v in raw) v as String} : <String>{};

  static List<String> _stringList(Object? raw) =>
      raw is List ? [for (final v in raw) v as String] : <String>[];

  Map<String, dynamic> toJson() => {
        'unlockedBadgeIds': unlockedBadgeIds.toList(),
        'activityDates': activityDates,
        'savingsActivityDates': savingsActivityDates,
        'canceledSubscriptionSignatures':
            canceledSubscriptionSignatures.toList(),
      };

  /// Marks a detected subscription (keyed by `merchantSignature`) as
  /// canceled, for the Unsubscriber badge. Purely a badge signal — it does
  /// not touch `FinanceProvider`; the subscriptions card hides canceled
  /// entries on its own by checking this set.
  void cancelSubscription(String signature) {
    if (!canceledSubscriptionSignatures.add(signature)) return;
    notifyListeners();
    _scheduleWrite();
  }

  /// Badge ids unlocked since the last call whose celebration snackbar
  /// hasn't been shown yet. Draining clears the list, so each unlock is
  /// announced exactly once.
  List<String> consumeNewlyUnlocked() {
    final result = _pendingCelebrations;
    _pendingCelebrations = [];
    return result;
  }

  /// Re-evaluates every badge against the current state and records today's
  /// activity. Call whenever `FinanceProvider` or the literacy-card read
  /// count changes — see the listener wiring in `DashboardScreen`.
  void recompute({
    required FinanceProvider finance,
    required int readLiteracyCardCount,
  }) {
    final today = todayIso();
    var changed = false;

    var savingsActivityToday = false;
    for (final g in finance.goals) {
      final previous = _lastKnownGoalCurrent[g.id] ?? g.current;
      if (g.current > previous) savingsActivityToday = true;
      _lastKnownGoalCurrent[g.id] = g.current;
    }

    if (!activityDates.contains(today)) {
      activityDates = [...activityDates, today];
      changed = true;
    }
    if (savingsActivityToday && !savingsActivityDates.contains(today)) {
      savingsActivityDates = [...savingsActivityDates, today];
      changed = true;
    }

    final result = evaluateUnlockedBadges(
      AchievementInputs(
        goals: finance.goals,
        budgets: finance.budgets,
        transactions: finance.transactions,
        readLiteracyCardCount: readLiteracyCardCount,
        activityDates: activityDates,
        savingsActivityDates: savingsActivityDates,
        canceledSubscriptionSignatures: canceledSubscriptionSignatures,
      ),
    );

    // Union rather than replace: a badge already earned stays earned even if
    // its condition later stops holding (see `achievementBadges` doc).
    final newly = result.difference(unlockedBadgeIds);
    if (newly.isNotEmpty) {
      unlockedBadgeIds = {...unlockedBadgeIds, ...newly};
      _pendingCelebrations = [..._pendingCelebrations, ...newly];
      changed = true;
    }

    if (changed) {
      notifyListeners();
      _scheduleWrite();
    }
  }

  Timer? _writeTimer;
  bool _writePending = false;
  static const _writeDebounce = Duration(milliseconds: 500);

  void _scheduleWrite() {
    _writePending = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, flush);
  }

  Future<void> flush() async {
    if (!_writePending) return;
    _writeTimer?.cancel();
    _writePending = false;
    try {
      await _prefs.setJson(PrefsKeys.achievements, toJson());
    } catch (error) {
      logError('Achievements write', error);
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
