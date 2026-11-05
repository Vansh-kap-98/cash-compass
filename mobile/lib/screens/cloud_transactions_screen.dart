import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/widgets/app_button.dart';
import '../app/widgets/app_card.dart';
import '../app/widgets/app_list_row.dart';
import '../services/transactions_repository.dart';
import '../state/currency_provider.dart';

/// The synced transaction list, backed by Supabase.
///
/// Deliberately a separate screen from the Dashboard rather than a rewrite of
/// it. The Dashboard is the offline-first product — shared_preferences, usable
/// with no account — and turning it into a network-backed view would be a
/// large, risky change across a well-tested surface. This screen is the
/// server-backed path, and nothing else in the app depends on it.
///
/// Live by subscription: [TransactionsRepository.watch] emits the current rows
/// immediately and again on every insert, so a transaction added on the web
/// lands here without a refresh. Pull-to-refresh exists as the fallback for
/// when the socket is asleep or the network dropped.
class CloudTransactionsScreen extends StatefulWidget {
  const CloudTransactionsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CloudTransactionsScreen()),
      );

  @override
  State<CloudTransactionsScreen> createState() =>
      _CloudTransactionsScreenState();
}

class _CloudTransactionsScreenState extends State<CloudTransactionsScreen> {
  static const _repo = TransactionsRepository();

  StreamSubscription<List<CloudTransaction>>? _sub;

  List<CloudTransaction>? _rows; // null = still loading
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    setState(() {
      _rows = null;
      _error = null;
    });

    _sub = _repo.watch().listen(
      (rows) {
        if (!mounted) return;
        setState(() {
          _rows = rows;
          _error = null;
        });
      },
      // Surfaced, never swallowed. A dead socket otherwise looks exactly like
      // an account with no transactions.
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _error = e);
      },
    );
  }

  /// Pull-to-refresh: a one-shot read for when the subscription is not
  /// delivering. Replaces the list wholesale rather than merging, so a row
  /// deleted elsewhere actually disappears.
  Future<void> _refresh() async {
    try {
      final rows = await _repo.list();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synced transactions'),
        actions: [
          IconButton(
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _body(context, rows),
      ),
    );
  }

  Widget _body(BuildContext context, List<CloudTransaction>? rows) {
    // Error first: an error with stale rows still on screen is worse than one
    // that says so plainly.
    if (_error != null) return _ErrorState(error: _error!, onRetry: _subscribe);

    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currency = context.watch<CurrencyProvider>();
    final balance = TransactionsRepository.balanceOf(rows);

    return ListView(
      // Always scrollable, or pull-to-refresh cannot be triggered on a short
      // or empty list — which is exactly when it is needed.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        AppCard.ink(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    currency.formatFromUsd(balance),
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Derived from ${rows.length} '
                    '${rows.length == 1 ? 'transaction' : 'transactions'}, live.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _EmptyState()
        else
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const AppRowDivider(),
                  _Row(row: rows[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddSheet(),
    );
    // The stream delivers the new row on its own; this is only for the case
    // where Realtime is unavailable and the insert still succeeded.
    if (added == true) await _refresh();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final CloudTransaction row;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final date = row.occurredOn;

    return AppListRow(
      title: row.category?.isNotEmpty == true ? row.category! : row.type,
      subtitle: row.note?.isNotEmpty == true
          ? row.note
          : '${date.year}-${'${date.month}'.padLeft(2, '0')}-'
              '${'${date.day}'.padLeft(2, '0')}',
      trailing:
          '${row.isIncome ? '+' : '−'}${currency.formatFromUsd(row.amount)}',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_queue_outlined, size: 40),
          const SizedBox(height: 12),
          Text('No synced transactions yet',
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Add one here, or on the web app signed in to the same account — '
            'it will appear on both.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The real message, not a generic apology. A PostgrestException carries
    // the reason the database refused — an RLS denial reads very differently
    // from a missing table, and hiding that costs hours.
    final detail = switch (error) {
      final PostgrestException e => e.message,
      final AuthException e => e.message,
      _ => error.toString(),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Could not load transactions',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(detail, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              AppButton(label: 'Try again', onPressed: onRetry),
            ],
          ),
        ),
      ],
    );
  }
}

/// Add-transaction form.
class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  static const _repo = TransactionsRepository();

  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();

  String _type = 'expense';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final typed = double.tryParse(_amount.text.trim());
    if (typed == null || typed <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Stored in USD, like everything else in this app — the database has no
      // currency column, so a figure typed in rupees must be converted before
      // it is sent or the two platforms will disagree.
      final usd = context.read<CurrencyProvider>().convertToUsd(typed);
      await _repo.add(
        amount: double.parse(usd.toStringAsFixed(2)),
        type: _type,
        category: _category.text.trim(),
        note: _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = switch (e) {
          final PostgrestException pe => pe.message,
          _ => e.toString(),
        };
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = context.watch<CurrencyProvider>().currency.code;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add transaction', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount ($code)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: _saving ? 'Saving…' : 'Save',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
