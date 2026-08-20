import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  const AddEntrySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const AddEntrySheet(),
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
    final composedNote = _recurrence == Recurrence.none
        ? (note.isEmpty ? null : note)
        : '${note.isEmpty ? '' : '$note | '}Recurring: ${_recurrence.name}';

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
      title: 'Add Entry',
      subtitle: 'Log an expense or income. Mark recurring charges to track them.',
      onSubmit: _save,
      submitLabel: 'Save Entry',
      children: [
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
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Grocery run',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (${currency.currency.code})',
            prefixText: '${currency.currency.symbol} ',
            hintText: '0.00',
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
