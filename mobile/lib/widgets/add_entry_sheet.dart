import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/receipt_parser.dart';
import '../models/transaction.dart';
import '../state/currency_provider.dart';
import '../state/finance_provider.dart';
import 'sheet_scaffold.dart';

/// Log an expense or income entry.
///
/// Port of the Add Entry dialog in `QuickActions.tsx`. A bottom sheet rather
/// than a dialog: it is the Android idiom and behaves properly with the
/// keyboard.
class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({super.key, this.receipt});

  /// Fields read off a scanned receipt, used to prefill the form.
  ///
  /// The scan seeds the same form the user would have filled by hand rather
  /// than getting a screen of its own: validation, currency conversion, and
  /// category rules then have exactly one implementation, and a bad OCR guess
  /// is corrected with the controls the user already knows.
  final ParsedReceipt? receipt;

  static Future<void> show(BuildContext context, {ParsedReceipt? receipt}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AddEntrySheet(receipt: receipt),
      );

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = 'Groceries';
  DateTime _date = DateTime.now();
  Recurrence _recurrence = Recurrence.none;
  bool _unplanned = false;
  final Set<ReasonTag> _reasonTags = {};

  String? _error;

  /// Set when the scanned amount was converted from another currency, so the
  /// user can see the figure on screen is not the figure on the paper.
  String? _convertedFrom;

  /// True once the user edits a scanned field, so its "check this" hint can be
  /// dropped — the value is theirs now, not the OCR's.
  final Set<String> _confirmed = {};

  ParsedReceipt? get _receipt => widget.receipt;
  bool get _fromScan => _receipt != null;

  @override
  void initState() {
    super.initState();
    final receipt = widget.receipt;
    if (receipt == null) return;

    // The amount is filled in the *active* currency, whatever the receipt was
    // printed in.
    //
    // The parser now reports the currency it saw. When that differs from the
    // user's and a rate is known, convert — a €24.50 receipt scanned by someone
    // working in rupees should fill in the rupee figure, because that is what
    // the field is labelled and what `_save` will convert back from.
    //
    // When the receipt carried no currency marker, or names one with no rate,
    // the number is taken as-is: assuming it is already in the user's currency
    // is right far more often than guessing, and the review hint asks them to
    // check either way.
    final amount = receipt.amount;
    if (amount != null) {
      final currency = context.read<CurrencyProvider>();
      final detected = receipt.currencyCode;
      final converted = detected == null || detected == currency.currency.code
          ? amount
          : currency.convertToActiveFromCode(amount, detected) ?? amount;

      _amountController.text = converted.toStringAsFixed(2);

      // Say so when the figure on screen is not the figure on the paper.
      if (detected != null &&
          detected != currency.currency.code &&
          currency.knowsRate(detected)) {
        _convertedFrom = '${amount.toStringAsFixed(2)} $detected converted to '
            '${currency.currency.code}';
      } else if (detected != null && !currency.knowsRate(detected)) {
        _convertedFrom = 'Receipt is in $detected — no exchange rate '
            'available, so this is unconverted';
      }
    }

    final merchant = receipt.merchant;
    if (merchant != null) _nameController.text = merchant;

    final category = receipt.category;
    if (category != null && expenseCategories.contains(category)) {
      _category = category;
    }

    // A receipt is always money going out.
    _type = TransactionType.expense;

    if (receipt.suggestsSubscription) _recurrence = Recurrence.monthly;
  }

  /// Whether a scanned field still deserves a "please check" hint.
  bool _needsReview(String field, FieldConfidence confidence) =>
      _fromScan && confidence.needsReview && !_confirmed.contains(field);

  /// Hint text for a field the OCR was unsure about, or null when it was
  /// confident, hand-typed, or already corrected.
  String? _reviewHint(String field, FieldConfidence confidence) =>
      _needsReview(field, confidence) ? 'Scanned — please check' : null;

  void _markConfirmed(String field) {
    if (_confirmed.contains(field)) return;
    setState(() => _confirmed.add(field));
  }

  bool get _isExpense => _type == TransactionType.expense;
  List<String> get _categories =>
      _isExpense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setType(TransactionType next) {
    setState(() {
      _type = next;
      // Matches the web app: switching type resets the category, and income
      // never carries the unplanned context.
      _category = next == TransactionType.income ? 'Salary' : 'Groceries';
      if (next == TransactionType.income) {
        _unplanned = false;
        _reasonTags.clear();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    final typed = double.tryParse(_amountController.text.trim());

    if (name.isEmpty || typed == null || !typed.isFinite || typed <= 0) {
      const message = 'Please provide a name and a valid amount.';
      setState(() => _error = message);
      // Also surfaced as a snack bar: the inline error sits at the end of a
      // long scrolling form, so tapping Save from the top would otherwise look
      // like nothing happened at all.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(message)),
      );
      return;
    }

    final currency = context.read<CurrencyProvider>();
    final note = _noteController.text.trim();
    // The recurrence is carried in the note, exactly as the web app does, so
    // the subscription detector can still see it.
    final parts = <String>[
      if (note.isNotEmpty) note,
      if (_recurrence != Recurrence.none) 'Recurring: ${_recurrence.name}',
      // Marks the entry as OCR-derived so a wrong figure can be traced back to
      // a scan rather than blamed on the user's typing.
      if (_fromScan) 'Scanned receipt',
    ];
    final composedNote = parts.isEmpty ? null : parts.join(' | ');

    context.read<FinanceProvider>().addTransaction(
          name: name,
          amount: currency.convertToUsd(typed),
          type: _type,
          category: _category,
          date: isoDate(_date),
          note: composedNote,
          isUnplanned: _unplanned,
          reasonTags: _reasonTags.toList(),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _recurrence == Recurrence.none
              ? 'Entry saved.'
              : 'Recurring ${_recurrence.name} entry added.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();

    return SheetScaffold(
      title: _fromScan ? 'Check Receipt' : 'Add Entry',
      subtitle: _fromScan
          ? 'Read from your receipt. Anything marked "please check" was a '
              'guess — correct it before saving.'
          : 'Log an expense or income. Mark recurring charges to track them.',
      onSubmit: _save,
      submitLabel: 'Save Entry',
      children: [
        if (_receipt?.suggestsSubscription ?? false) ...[
          // Surfaced before saving, not after: once the entry is in, the Waste
          // Auditor would flag it anyway, and by then the user has lost the
          // chance to say "no, this was a one-off".
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.autorenew,
                      color: theme.colorScheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This looks like a recurring charge. Set to monthly — '
                      'change it below if that is wrong.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SegmentedButton<TransactionType>(
          segments: const [
            ButtonSegment(
              value: TransactionType.expense,
              label: Text('Expense'),
              icon: Icon(Icons.arrow_downward),
            ),
            ButtonSegment(
              value: TransactionType.income,
              label: Text('Income'),
              icon: Icon(Icons.arrow_upward),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (s) => _setType(s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _markConfirmed('name'),
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Grocery run',
            helperText: _reviewHint(
              'name',
              _receipt?.merchantConfidence ?? FieldConfidence.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _markConfirmed('amount'),
          decoration: InputDecoration(
            labelText: 'Amount (${currency.currency.code})',
            prefixText: '${currency.currency.symbol} ',
            hintText: '0.00',
            helperText: _reviewHint(
                  'amount',
                  _receipt?.amountConfidence ?? FieldConfidence.none,
                ) ??
                _convertedFrom,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (c) {
                  if (c != null) setState(() => _category = c);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(isoDate(_date)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Is this recurring?', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in Recurrence.values)
              ChoiceChip(
                label: Text(r.label),
                selected: _recurrence == r,
                onSelected: (_) => setState(() => _recurrence = r),
              ),
          ],
        ),
        if (_isExpense) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _unplanned,
            title: const Text('Unplanned / spontaneous'),
            subtitle: const Text(
              'Optional context to make insights more useful, never judgmental.',
            ),
            onChanged: (v) => setState(() {
              _unplanned = v;
              if (!v) _reasonTags.clear();
            }),
          ),
          if (_unplanned) ...[
            Text(
              'What influenced this? Optional',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in ReasonTag.values)
                  FilterChip(
                    label: Text(tag.label),
                    selected: _reasonTags.contains(tag),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _reasonTags.add(tag);
                      } else {
                        _reasonTags.remove(tag);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note',
            hintText: 'Any details about this entry',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}
