import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// One row of `public.transactions`.
///
/// Deliberately separate from [FinanceTransaction] in `models/transaction.dart`.
/// That one is the local, offline-first record kept in shared_preferences and
/// shaped by the web app's historical JSON; this one mirrors a Postgres row and
/// nothing else. Folding them together would mean one class answering to two
/// schemas, and the first mismatch would be silent.
class CloudTransaction {
  const CloudTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.occurredOn,
    this.category,
    this.note,
  });

  factory CloudTransaction.fromRow(Map<String, dynamic> row) {
    return CloudTransaction(
      id: row['id'] as String,
      // numeric(12,2) arrives as String over the wire, not double — parsing it
      // as num would throw on every row.
      amount: double.tryParse('${row['amount']}') ?? 0,
      type: row['type'] as String? ?? 'expense',
      occurredOn: DateTime.tryParse('${row['occurred_on']}') ?? DateTime.now(),
      category: row['category'] as String?,
      note: row['note'] as String?,
    );
  }

  final String id;
  final double amount;

  /// `'income'` or `'expense'`, matching the database check constraint.
  final String type;

  final DateTime occurredOn;
  final String? category;
  final String? note;

  bool get isIncome => type == 'income';

  /// Contribution to the balance: income adds, expense subtracts.
  double get signedAmount => isIncome ? amount : -amount;
}

/// Reads and writes `public.transactions` for the signed-in user.
///
/// Every method assumes a session exists; row-level security scopes all of it
/// to `auth.uid()` server-side, so there is no user filter in any query here —
/// adding one would imply the client is what enforces the boundary.
class TransactionsRepository {
  const TransactionsRepository();

  SupabaseClient get _db => SupabaseService.client;

  static const table = 'transactions';

  /// Adds a transaction.
  ///
  /// `user_id` is deliberately absent: the column defaults to `auth.uid()`, so
  /// the server decides ownership. Sending it from the client would be both
  /// redundant and a thing an attacker could tamper with.
  Future<void> add({
    required double amount,
    required String type,
    String? category,
    String? note,
    DateTime? occurredOn,
  }) async {
    await _db.from(table).insert({
      'amount': amount,
      'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (note != null && note.isNotEmpty) 'note': note,
      if (occurredOn != null)
        'occurred_on': occurredOn.toIso8601String().split('T').first,
    });
  }

  /// One-shot fetch, newest first. Backs pull-to-refresh.
  Future<List<CloudTransaction>> list() async {
    final rows = await _db
        .from(table)
        .select()
        .order('occurred_on', ascending: false)
        .order('created_at', ascending: false);

    return rows.map(CloudTransaction.fromRow).toList();
  }

  /// Live rows, newest first.
  ///
  /// `.stream()` opens a Realtime subscription and also emits the current
  /// contents immediately, so a screen listening to this needs no separate
  /// initial fetch.
  ///
  /// Ordering is applied client-side by the SDK rather than in Postgres, so
  /// only one `order` is available — ties on the same day fall back to
  /// insertion order, which is close enough for a list the user is reading.
  Stream<List<CloudTransaction>> watch() {
    return _db
        .from(table)
        .stream(primaryKey: ['id'])
        .order('occurred_on', ascending: false)
        .map((rows) => rows.map(CloudTransaction.fromRow).toList());
  }

  /// The balance, read from the `public.balances` view.
  ///
  /// Returns 0 when the user has no rows: the view groups by `user_id`, so an
  /// account with nothing in it has no row at all rather than a row of zero.
  Future<double> balance() async {
    final row = await _db
        .from('balances')
        .select('balance')
        .maybeSingle();

    if (row == null) return 0;
    return double.tryParse('${row['balance']}') ?? 0;
  }

  /// The balance computed from rows already in hand.
  ///
  /// Used while the stream is live so the figure moves in the same frame as
  /// the list, with no second round trip. [balance] is the authority; this
  /// must agree with it, and the sum is the same arithmetic the view performs.
  static double balanceOf(Iterable<CloudTransaction> rows) =>
      rows.fold(0.0, (sum, t) => sum + t.signedAmount);
}
