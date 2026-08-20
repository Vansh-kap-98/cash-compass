import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/budget_plan.dart';
import '../models/json_utils.dart';
import '../services/prefs.dart';
import 'finance_provider.dart' show isoDate;

/// Finalised budget plans plus the in-progress draft.
///
/// The web app let you drag the planner panel around and minimise it to a tab
/// pinned to the screen edge. That is a desktop-window metaphor; here the
/// planner is a full-screen route, and "minimise" becomes a persisted draft you
/// can resume from a chip on the dashboard.
class BudgetPlanProvider extends ChangeNotifier {
  BudgetPlanProvider(this._prefs);

  final Prefs _prefs;

  List<BudgetPlan> plans = [];

  /// The plan currently being edited, if any. Persisted so closing the app
  /// mid-plan doesn't lose the work.
  BudgetPlan? draft;

  bool loaded = false;

  /// Bumped on every mutation — `select` on this, not on [plans].
  int revision = 0;

  Future<void> load() async {
    final raw = await _prefs.getJsonList(PrefsKeys.budgetPlans);
    if (raw != null) plans = decodeList(raw, BudgetPlan.fromJson);

    final draftJson = await _prefs.getJson(PrefsKeys.budgetDraft);
    if (draftJson != null) {
      try {
        draft = BudgetPlan.fromJson(draftJson);
      } catch (_) {
        draft = null;
      }
    }

    loaded = true;
    notifyListeners();
  }

  /// Starts a new draft, or returns the existing one so work is never lost.
  BudgetPlan startOrResumeDraft() {
    final existing = draft;
    if (existing != null) return existing;

    final now = DateTime.now();
    final created = BudgetPlan(
      id: 'bp-${now.millisecondsSinceEpoch}',
      title: '',
      planType: BudgetPlanType.trip,
      dateFrom: isoDate(now),
      people: 1,
      items: const [],
      createdAt: now.toIso8601String(),
    );
    draft = created;
    _persist();
    return created;
  }

  void updateDraft(BudgetPlan next) {
    draft = next;
    _persist();
  }

  void discardDraft() {
    if (draft == null) return;
    draft = null;
    _persist();
  }

  /// Reasons a draft cannot be finalised yet, empty when it is ready.
  static String? validationError(BudgetPlan plan) {
    if (plan.title.trim().isEmpty) return 'Add a plan title before finalising.';
    if (plan.items.isEmpty) {
      return 'Add at least one item to generate a bill.';
    }
    final to = plan.dateTo;
    if (to != null && to.isNotEmpty && to.compareTo(plan.dateFrom) < 0) {
      return 'End date cannot be before the start date.';
    }
    return null;
  }

  /// Moves the draft into the finalised list. Returns an error string when the
  /// plan isn't ready, so the caller can surface it.
  String? finalizeDraft() {
    final current = draft;
    if (current == null) return 'Nothing to finalise.';

    final error = validationError(current);
    if (error != null) return error;

    plans.insert(0, current.copyWith(title: current.title.trim()));
    draft = null;
    _persist();
    return null;
  }

  void deletePlan(String id) {
    final before = plans.length;
    plans.removeWhere((p) => p.id == id);
    if (plans.length != before) _persist();
  }

  /// Marks one participant of a plan as settled up.
  ///
  /// The web app's "Settle Up" button had no handler at all; this makes it real.
  void toggleSettled(String planId, String person) {
    final index = plans.indexWhere((p) => p.id == planId);
    if (index < 0) return;
    final plan = plans[index];
    final next = [...plan.settledWith];
    if (next.contains(person)) {
      next.remove(person);
    } else {
      next.add(person);
    }
    plans[index] = plan.copyWith(settledWith: next);
    _persist();
  }

  /// Replaces the finalised plans in one write. Used by the dev seeder.
  void replaceAll(List<BudgetPlan> next) {
    plans = [...next];
    _persist();
  }

  Future<void> resetAll() async {
    plans = [];
    draft = null;
    revision++;
    _writeTimer?.cancel();
    _writePending = false;
    notifyListeners();
    await _prefs.removeAll([PrefsKeys.budgetPlans, PrefsKeys.budgetDraft]);
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
        PrefsKeys.budgetPlans,
        plans.map((p) => p.toJson()).toList(),
      );
      final current = draft;
      if (current == null) {
        await _prefs.remove(PrefsKeys.budgetDraft);
      } else {
        await _prefs.setJson(PrefsKeys.budgetDraft, current.toJson());
      }
    } catch (error) {
      debugPrint('Budget plan write failed: $error');
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
