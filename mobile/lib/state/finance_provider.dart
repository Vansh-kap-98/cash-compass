import 'package:flutter/foundation.dart';

import '../models/budget_category.dart';
import '../models/json_utils.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../services/prefs.dart';

/// Transaction / goal / budget ids seeded by an old demo build. The web app
/// strips these on load so returning users don't see fake data forever; keeping
/// the same list means a browser blob imported here is cleaned identically.
const _legacyDemoIds = <String>{
  'tx-1', 'tx-2', 'tx-3', 'tx-4', 'tx-5', 'tx-6', 'tx-7', //
  'goal-1', 'goal-2', 'goal-3',
  'budget-1', 'budget-2', 'budget-3', 'budget-4', 'budget-5',
};

/// Returns today as an ISO `yyyy-MM-dd` string in local time.
String todayIso() => isoDate(DateTime.now());

/// Formats a [DateTime] as `yyyy-MM-dd`, ignoring any time component.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The single source of truth for financial data.
///
/// Direct port of `frontend/src/contexts/FinanceContext.tsx`. All amounts are
/// held in USD; the active display currency is applied at the presentation
/// layer by `CurrencyProvider`.
class FinanceProvider extends ChangeNotifier {
  FinanceProvider(this._prefs);

  final Prefs _prefs;

  double startingBalance = 0;
  double? manualBalance;
  double? manualIncomeToDate;
  double? manualSpentToday;
  List<FinanceTransaction> transactions = [];
  List<SavingsGoal> goals = [];
  List<BudgetCategory> budgets = [];

  /// False until [load] has completed. The UI shows a neutral screen until then
  /// rather than briefly rendering zeroes over real data.
  bool loaded = false;

  // ---------------------------------------------------------------- derived

  /// Sum of every expense ever recorded, in USD.
  double get totalSpent => transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Sum of every income entry, in USD.
  double get totalIncome => transactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Expenses dated today. Mirrors `BalanceOverview.tsx`.
  double get spentToday {
    final today = todayIso();
    return transactions
        .where((t) => t.isExpense && t.date == today)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// The manual snapshot the user typed, or zero if they haven't set one.
  double get totalBalance => manualBalance ?? 0;

  /// What's left of the snapshot after all recorded expenses. Never negative,
  /// matching the web app's `Math.max(0, ...)`.
  double get availableBalance {
    final remaining = totalBalance - totalSpent;
    return remaining < 0 ? 0 : remaining;
  }

  /// Total expenses grouped by category, largest first. Used by the charts and
  /// the top-categories widget.
  List<MapEntry<String, double>> expensesByCategory({DateTime? month}) {
    final totals = <String, double>{};
    for (final t in transactions) {
      if (!t.isExpense) continue;
      if (month != null && !_isInMonth(t.date, month)) continue;
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  bool _isInMonth(String isoDay, DateTime month) {
    final parsed = DateTime.tryParse(isoDay);
    if (parsed == null) return false;
    return parsed.year == month.year && parsed.month == month.month;
  }

  // ------------------------------------------------------------- load/save

  Future<void> load() async {
    final json = await _prefs.getJson(PrefsKeys.finance);
    if (json != null) {
      _applyJson(json);
    }
    loaded = true;
    notifyListeners();
  }

  void _applyJson(Map<String, dynamic> j) {
    startingBalance = asDouble(j['startingBalance']);
    manualBalance = asNullableDouble(j['manualBalance']);
    manualIncomeToDate = asNullableDouble(j['manualIncomeToDate']);
    manualSpentToday = asNullableDouble(j['manualSpentToday']);

    transactions = decodeList(j['transactions'], FinanceTransaction.fromJson)
        .where((t) => !_legacyDemoIds.contains(t.id))
        .toList();
    goals = decodeList(j['goals'], SavingsGoal.fromJson)
        .where((g) => !_legacyDemoIds.contains(g.id))
        .toList();
    budgets = decodeList(j['budgets'], BudgetCategory.fromJson)
        .where((b) => !_legacyDemoIds.contains(b.id))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'startingBalance': startingBalance,
        'manualBalance': manualBalance,
        'manualIncomeToDate': manualIncomeToDate,
        'manualSpentToday': manualSpentToday,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
      };

  /// Repaints immediately, then writes to disk in the background.
  ///
  /// The web version wrote to `localStorage` synchronously inside every
  /// mutator. On mobile that would block the frame, so the notify and the write
  /// are deliberately decoupled: the UI never waits on I/O.
  void _persist() {
    notifyListeners();
    _fireAndForget(_prefs.setJson(PrefsKeys.finance, toJson()));
  }

  // -------------------------------------------------------------- mutators

  /// Records an income or expense entry.
  ///
  /// Silently ignores non-positive amounts, matching the web app — the Add
  /// Entry form is responsible for telling the user why nothing happened.
  void addTransaction({
    required String name,
    required double amount,
    required TransactionType type,
    required String category,
    required String date,
    String? note,
    bool isUnplanned = false,
    List<ReasonTag> reasonTags = const [],
  }) {
    if (!amount.isFinite || amount <= 0) return;

    final isExpense = type == TransactionType.expense;
    final trimmedName = name.trim();
    final resolvedCategory = category.trim().isEmpty
        ? (isExpense ? 'Other' : 'Income')
        : category.trim();

    transactions.insert(
      0,
      FinanceTransaction(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        name: trimmedName.isEmpty ? 'Manual Entry' : trimmedName,
        amount: amount,
        type: type,
        category: resolvedCategory,
        date: date,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        icon: categoryIcons[resolvedCategory] ?? (isExpense ? '💸' : '💰'),
        createdAt: DateTime.now().toIso8601String(),
        // Reason tags only describe unplanned *spending*; income never carries
        // them, so both fields are dropped for income entries.
        isUnplanned: isExpense && isUnplanned,
        reasonTags: isExpense ? reasonTags : const [],
      ),
    );
    _persist();
  }

  /// Creates a savings goal. [target] is floored at 1 so [SavingsGoal.progress]
  /// can never divide by zero; [initialAmount] is clamped into range.
  void addGoal({
    required String name,
    required double target,
    double initialAmount = 0,
    String icon = '🎯',
  }) {
    if (!target.isFinite) return;
    final resolvedTarget = target < 1 ? 1.0 : target;
    final resolvedCurrent =
        initialAmount.isFinite ? initialAmount.clamp(0.0, resolvedTarget) : 0.0;
    final trimmedName = name.trim();

    goals.insert(
      0,
      SavingsGoal(
        id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
        name: trimmedName.isEmpty ? 'Goal' : trimmedName,
        current: resolvedCurrent.toDouble(),
        target: resolvedTarget,
        icon: icon,
      ),
    );
    _persist();
  }

  /// Adds to a goal's balance, capped at its target. There is deliberately no
  /// withdrawal path — the web app has none either.
  void contributeToGoal(String goalId, double amount) {
    if (!amount.isFinite || amount <= 0) return;
    var changed = false;

    goals = goals.map((g) {
      if (g.id != goalId) return g;
      final next = (g.current + amount).clamp(0.0, g.target).toDouble();
      if (next == g.current) return g;
      changed = true;
      return g.copyWith(current: next);
    }).toList();

    if (changed) _persist();
  }

  /// Creates or updates a category budget, matching on name case-insensitively.
  void upsertBudget(String name, double monthlyLimit) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !monthlyLimit.isFinite || monthlyLimit <= 0) return;

    final index = budgets
        .indexWhere((b) => b.name.toLowerCase() == trimmed.toLowerCase());

    if (index >= 0) {
      budgets[index] = budgets[index].copyWith(monthlyLimit: monthlyLimit);
    } else {
      budgets.insert(
        0,
        BudgetCategory(
          id: 'budget-${DateTime.now().millisecondsSinceEpoch}',
          name: trimmed,
          monthlyLimit: monthlyLimit,
        ),
      );
    }
    _persist();
  }

  /// Sets the manual balance snapshot. Each field is floored at zero when
  /// finite and nulled otherwise, matching `setManualSnapshot`.
  void setManualSnapshot({
    double? balance,
    double? incomeToDate,
    double? spentToday,
  }) {
    double? clean(double? v) {
      if (v == null || !v.isFinite) return null;
      return v < 0 ? 0 : v;
    }

    manualBalance = clean(balance);
    manualIncomeToDate = clean(incomeToDate);
    manualSpentToday = clean(spentToday);
    _persist();
  }

  /// Wipes all finance data. Used when entering demo mode and by the reset
  /// control in Settings.
  Future<void> resetAll() async {
    startingBalance = 0;
    manualBalance = null;
    manualIncomeToDate = null;
    manualSpentToday = null;
    transactions = [];
    goals = [];
    budgets = [];
    notifyListeners();
    await _prefs.remove(PrefsKeys.finance);
  }
}

/// Starts a background write without awaiting it, logging rather than throwing
/// if it fails. Named to avoid colliding with `dart:async`'s `unawaited`, which
/// swallows errors silently.
void _fireAndForget(Future<void> future) {
  future.catchError((Object error) {
    debugPrint('Background write failed: $error');
  });
}
