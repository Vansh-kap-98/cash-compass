import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/receipt_batch_queue.dart';
import '../models/transaction.dart';
import '../services/receipt_scanner.dart';
import '../state/finance_provider.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/set_goal_sheet.dart';
import 'budget_plan_screen.dart';
import 'receipt_batch_review_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/goals_tab.dart';
import 'tabs/planner_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/workspace_tab.dart';

/// The app shell.
///
/// Replaces `SoftBloomLayout`'s sidebar + mobile pill bar with a single
/// [NavigationBar] — on a phone there is only the mobile pattern, so the
/// desktop sidebar has no equivalent.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Goals',
    'Planner',
    'Workspace',
    'Settings',
  ];

  /// Index of the Settings tab, where a FAB would be meaningless.
  static const _settingsIndex = 4;

  Future<void> _openQuickActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scan Receipt'),
              subtitle: const Text('Read the amount from a photo'),
              onTap: () => Navigator.pop(sheetContext, 'scan'),
            ),
            ListTile(
              leading: const Icon(Icons.burst_mode_outlined),
              title: const Text('Scan Several'),
              subtitle: const Text('Pick receipts from your gallery'),
              onTap: () => Navigator.pop(sheetContext, 'batch'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Add Entry'),
              subtitle: const Text('Log an expense or income'),
              onTap: () => Navigator.pop(sheetContext, 'entry'),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Set Goal'),
              subtitle: const Text('Create a savings target'),
              onTap: () => Navigator.pop(sheetContext, 'goal'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Plan Budget'),
              subtitle: const Text('Cost out a trip, outing, or event'),
              onTap: () => Navigator.pop(sheetContext, 'budget'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'scan':
        await _scanReceipt(context);
      case 'batch':
        await _scanBatch(context);
      case 'entry':
        await AddEntrySheet.show(context);
      case 'goal':
        await SetGoalSheet.show(context);
      case 'budget':
        await BudgetPlanScreen.open(context);
    }
  }

  /// Picks several receipts, processes them, and opens the review screen.
  ///
  /// Nothing is written until the user confirms from that screen.
  Future<void> _scanBatch(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final history = context.read<FinanceProvider>().transactions;

    final picked = await ReceiptScanner.pickBatch();
    if (!context.mounted || picked.isEmpty) return;

    // Processing runs behind a modal barrier rather than on the review screen,
    // so a half-populated list never flashes up and reorders as results land.
    final entries = <BatchEntry>[
      for (var i = 0; i < picked.length; i++)
        BatchEntry(id: 'batch-$i-${picked[i].name}', imagePath: picked[i].path),
    ];

    final processed = await showDialog<List<BatchEntry>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BatchProgressDialog(
        entries: entries,
        history: history,
      ),
    );

    if (!context.mounted || processed == null || processed.isEmpty) return;

    final saved = await ReceiptBatchReviewScreen.open(
      context,
      entries: processed,
      onRetry: (entry) async {
        final receipt = await ReceiptScanner.processFile(
          entry.imagePath,
          history: history,
        );
        return entry.copyWith(
          receipt: receipt,
          status: receipt == null ? BatchStatus.failed : BatchStatus.done,
        );
      },
    );

    if (saved != null && saved > 0) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Saved $saved receipt${saved == 1 ? '' : 's'}.')),
      );
    }
  }

  /// Captures a receipt and opens the entry sheet prefilled with what was read.
  ///
  /// A failed scan falls through to the ordinary form rather than dead-ending:
  /// the user came here to record a purchase, and the camera not cooperating is
  /// no reason to make them start over.
  Future<void> _scanReceipt(BuildContext context) async {
    final history = context.read<FinanceProvider>().transactions;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ReceiptScanner.scan(history: history);
    if (!context.mounted) return;

    switch (result) {
      case ScanSuccess(:final receipt):
        await AddEntrySheet.show(context, receipt: receipt);

      case ScanFailed(reason: ScanFailure.cancelled):
        // Backing out of the camera is not a failure worth announcing.
        return;

      case ScanFailed(:final reason):
        messenger.showSnackBar(
          SnackBar(content: Text(_scanFailureMessage(reason))),
        );
        await AddEntrySheet.show(context);
    }
  }

  static String _scanFailureMessage(ScanFailure reason) => switch (reason) {
        ScanFailure.cameraUnavailable =>
          'Camera unavailable — check the permission in Settings. '
              'Add the entry by hand for now.',
        ScanFailure.noTextFound =>
          'No text found in that photo. Try again in better light, or type it in.',
        ScanFailure.nothingUseful =>
          'Could not find an amount on that receipt. Fill it in below.',
        ScanFailure.cancelled => '',
      };

  @override
  Widget build(BuildContext context) {
    // Until the stores have hydrated, show a bare themed screen rather than
    // rendering zeroes that would immediately be replaced.
    final loaded = context.select<FinanceProvider, bool>((f) => f.loaded);
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      ),
      // IndexedStack keeps each tab alive, preserving scroll position the way
      // the web app's in-page tab switcher did.
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          GoalsTab(),
          PlannerTab(),
          WorkspaceTab(),
          SettingsTab(),
        ],
      ),
      // One FAB opening a chooser, rather than the web app's three stacked
      // buttons — stacked FABs are not an Android pattern.
      floatingActionButton: _index == _settingsIndex
          ? null
          : FloatingActionButton(
              onPressed: () => _openQuickActions(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Workspace',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Runs the batch queue behind a modal barrier, reporting progress.
///
/// Sits in front of the review screen rather than inside it so results cannot
/// reorder under the user as jobs finish at different speeds.
class _BatchProgressDialog extends StatefulWidget {
  const _BatchProgressDialog({required this.entries, required this.history});

  final List<BatchEntry> entries;
  final List<FinanceTransaction> history;

  @override
  State<_BatchProgressDialog> createState() => _BatchProgressDialogState();
}

class _BatchProgressDialogState extends State<_BatchProgressDialog> {
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final queue = ReceiptBatchQueue(
      process: (entry) async {
        // OCR must stay on this isolate: ML Kit is a platform channel and
        // cannot be called from a background one. The work is native and
        // awaited, so it does not block the UI thread regardless.
        final receipt = await ReceiptScanner.processFile(
          entry.imagePath,
          history: widget.history,
        );
        final captured = await ReceiptScanner.capturedAt(entry.imagePath);
        return entry.copyWith(
          receipt: receipt,
          capturedAt: captured,
          status: receipt == null ? BatchStatus.failed : BatchStatus.done,
        );
      },
    );

    List<BatchEntry> latest = widget.entries;
    await for (final snapshot in queue.run(widget.entries)) {
      latest = snapshot;
      if (mounted) {
        setState(() => _done = snapshot
            .where((e) =>
                e.status != BatchStatus.pending &&
                e.status != BatchStatus.processing)
            .length);
      }
    }

    if (mounted) Navigator.of(context).pop(latest);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.entries.length;
    return AlertDialog(
      title: const Text('Reading receipts'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: total == 0 ? null : _done / total,
          ),
          const SizedBox(height: 16),
          Text('$_done of $total'),
        ],
      ),
    );
  }
}
