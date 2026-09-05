import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../logic/receipt_batch_queue.dart';
import '../logic/receipt_parser.dart';
import '../models/transaction.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';

/// Review a scanned batch before any of it is written.
///
/// Nothing here touches the transaction store until the user confirms. A batch
/// that auto-saved would be worse than no batch feature: OCR is a guess, and
/// five wrong guesses written at once is harder to unpick than five typed
/// entries — especially with no way to edit or delete a transaction yet.
///
/// Every row is independent. A bad parse on one receipt must not block the
/// others, force a re-scan of the batch, or lose the nine that read correctly.
class ReceiptBatchReviewScreen extends StatefulWidget {
  const ReceiptBatchReviewScreen({
    super.key,
    required this.entries,
    this.onRetry,
  });

  final List<BatchEntry> entries;

  /// Re-runs OCR for one image. Null disables the retry action, which is what
  /// the tests use.
  final Future<BatchEntry> Function(BatchEntry entry)? onRetry;

  static Future<int?> open(
    BuildContext context, {
    required List<BatchEntry> entries,
    Future<BatchEntry> Function(BatchEntry entry)? onRetry,
  }) =>
      Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ReceiptBatchReviewScreen(
            entries: entries,
            onRetry: onRetry,
          ),
        ),
      );

  @override
  State<ReceiptBatchReviewScreen> createState() =>
      _ReceiptBatchReviewScreenState();
}

class _ReceiptBatchReviewScreenState extends State<ReceiptBatchReviewScreen> {
  late List<BatchEntry> _entries = List.of(widget.entries);

  /// Per-row edits, keyed by entry id so a retry cannot scramble them.
  final Map<String, TextEditingController> _names = {};
  final Map<String, TextEditingController> _amounts = {};
  final Map<String, DateTime> _dates = {};
  final Set<String> _retrying = {};

  @override
  void initState() {
    super.initState();
    _entries = flagDuplicates(_entries);
    for (final entry in _entries) {
      _seed(entry);
    }
  }

  void _seed(BatchEntry entry) {
    final currency = context.read<CurrencyProvider>();
    final receipt = entry.receipt;

    final amount = receipt?.amount;
    final detected = receipt?.currencyCode;
    final shown = amount == null
        ? ''
        : (detected == null || detected == currency.currency.code
                ? amount
                : currency.convertToActiveFromCode(amount, detected) ?? amount)
            .toStringAsFixed(2);

    _names[entry.id] = TextEditingController(text: receipt?.merchant ?? '');
    _amounts[entry.id] = TextEditingController(text: shown);
    _dates[entry.id] = entry.capturedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _savableCount => _entries
      .where((e) => !e.skipped && e.status != BatchStatus.failed)
      .length;

  void _toggleSkip(BatchEntry entry) {
    setState(() {
      final i = _entries.indexWhere((e) => e.id == entry.id);
      _entries[i] = _entries[i].copyWith(skipped: !_entries[i].skipped);
    });
  }

  Future<void> _retry(BatchEntry entry) async {
    final onRetry = widget.onRetry;
    if (onRetry == null) return;

    setState(() => _retrying.add(entry.id));
    final updated = await onRetry(entry);
    if (!mounted) return;

    setState(() {
      _retrying.remove(entry.id);
      final i = _entries.indexWhere((e) => e.id == entry.id);
      // Only this row changes. Re-flagging duplicates keeps the batch coherent
      // when a retry turns a failure into a readable receipt.
      _entries[i] = updated;
      _entries = flagDuplicates(_entries);
      _names[entry.id]?.dispose();
      _amounts[entry.id]?.dispose();
      _seed(updated);
    });
  }

  Future<void> _pickDate(BatchEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dates[entry.id] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _dates[entry.id] = picked);
  }

  void _saveAll() {
    final finance = context.read<FinanceProvider>();
    final currency = context.read<CurrencyProvider>();
    var saved = 0;

    for (final entry in _entries) {
      if (entry.skipped || entry.status == BatchStatus.failed) continue;

      final name = _names[entry.id]?.text.trim() ?? '';
      final typed = double.tryParse(_amounts[entry.id]?.text.trim() ?? '');
      if (name.isEmpty || typed == null || typed <= 0) continue;

      finance.addTransaction(
        name: name,
        amount: currency.convertToUsd(typed),
        type: TransactionType.expense,
        category: entry.receipt?.category ?? 'Other',
        date: isoDate(_dates[entry.id] ?? DateTime.now()),
        note: 'Scanned receipt',
      );
      saved++;
    }

    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.batchReviewTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _ReceiptRow(
          entry: _entries[i],
          name: _names[_entries[i].id]!,
          amount: _amounts[_entries[i].id]!,
          date: _dates[_entries[i].id]!,
          retrying: _retrying.contains(_entries[i].id),
          canRetry: widget.onRetry != null,
          onRetry: () => _retry(_entries[i]),
          onSkipToggle: () => _toggleSkip(_entries[i]),
          onPickDate: () => _pickDate(_entries[i]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _savableCount == 0 ? null : _saveAll,
            child: Text(
              _savableCount == 0
                  ? l10n.batchNothingToSave
                  : l10n.batchSaveCount(_savableCount),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.entry,
    required this.name,
    required this.amount,
    required this.date,
    required this.retrying,
    required this.canRetry,
    required this.onRetry,
    required this.onSkipToggle,
    required this.onPickDate,
  });

  final BatchEntry entry;
  final TextEditingController name;
  final TextEditingController amount;
  final DateTime date;
  final bool retrying;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onSkipToggle;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();
    final receipt = entry.receipt;
    final failed = entry.status == BatchStatus.failed || receipt == null;

    return Card(
      child: Opacity(
        opacity: entry.skipped ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(path: entry.imagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (failed)
                          Text(
                            l10n.batchCouldNotRead,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.error),
                          )
                        else ...[
                          TextField(
                            controller: name,
                            decoration: InputDecoration(
                              labelText: l10n.batchFieldMerchant,
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  l10n.entryFieldAmount(currency.currency.code),
                              isDense: true,
                              helperText: _amountHint(l10n, receipt, currency),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(isoDate(date)),
                  ),
                  if (entry.dateIsFallback)
                    Expanded(
                      child: Text(
                        l10n.batchNoPhotoDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (canRetry)
                    IconButton(
                      onPressed: retrying ? null : onRetry,
                      icon: retrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      tooltip: l10n.batchRetryTooltip,
                    ),
                  TextButton(
                    onPressed: onSkipToggle,
                    child: Text(
                      entry.skipped ? l10n.actionInclude : l10n.actionSkip,
                    ),
                  ),
                ],
              ),
              if (entry.isDuplicate)
                _Banner(
                  icon: Icons.copy_all_outlined,
                  text: l10n.batchDuplicateWarning,
                ),
              if (receipt?.discrepancy != null)
                _Banner(
                  icon: Icons.help_outline,
                  text: receiptDiscrepancyMessage(
                    l10n,
                    receipt!.discrepancy!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Explains the amount when it is not simply what the receipt printed.
  String? _amountHint(
    AppLocalizations l10n,
    ParsedReceipt? receipt,
    CurrencyProvider currency,
  ) {
    if (receipt == null) return null;
    final detected = receipt.currencyCode;
    final raw = receipt.amount;

    if (detected != null &&
        raw != null &&
        detected != currency.currency.code &&
        currency.knowsRate(detected)) {
      return l10n.batchAmountConverted(raw.toStringAsFixed(2), detected);
    }
    if (receipt.amountConfidence.needsReview) return l10n.scannedPleaseCheck;
    return null;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return ClipRRect(
      borderRadius: Theme.of(context).radii.smallBorder,
      child: SizedBox(
        width: 56,
        height: 72,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.receipt_long_outlined, size: 20),
              ),
      ),
    );
  }
}
