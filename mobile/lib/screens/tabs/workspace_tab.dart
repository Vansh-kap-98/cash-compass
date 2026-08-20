import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/workspace_widget.dart';
import '../../state/workspace_provider.dart';
import '../../widgets/workspace/widget_bodies.dart';

/// The Workspace tab — a customisable stack of widgets.
///
/// The web app used a 12-column grid with drag-to-resize handles. On a phone
/// that grid gives ~19dp columns and the handles need mouse precision, so this
/// is a single-column reorderable list with a Small/Medium/Large size toggle.
/// Same capability, touch-appropriate input.
class WorkspaceTab extends StatefulWidget {
  const WorkspaceTab({super.key});

  @override
  State<WorkspaceTab> createState() => _WorkspaceTabState();
}

class _WorkspaceTabState extends State<WorkspaceTab> {
  bool _editing = false;

  Future<void> _openPicker() async {
    final chosen = await showModalBottomSheet<WorkspaceWidgetType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Add a widget', style: TextStyle(fontSize: 20)),
            ),
            for (final type in WorkspaceWidgetType.values)
              ListTile(
                title: Text(type.label),
                onTap: () => Navigator.pop(sheetContext, type),
              ),
          ],
        ),
      ),
    );

    if (chosen != null && mounted) {
      context.read<WorkspaceProvider>().add(chosen);
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear workspace?'),
        content: const Text(
          'Every widget is removed, including any images you added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if ((ok ?? false) && mounted) {
      await context.read<WorkspaceProvider>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<WorkspaceProvider>();

    if (store.widgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('Build your workspace', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Add the cards you want to see at a glance.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openPicker,
                icon: const Icon(Icons.add),
                label: const Text('Add widget'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Text(
                _editing ? 'Drag to reorder' : 'Workspace',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              if (_editing)
                TextButton(
                  onPressed: _confirmClear,
                  child: const Text('Clear'),
                ),
              IconButton(
                icon: Icon(_editing ? Icons.check : Icons.tune),
                tooltip: _editing ? 'Done' : 'Edit layout',
                onPressed: () => setState(() => _editing = !_editing),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add widget',
                onPressed: _openPicker,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: store.widgets.length,
            // Handles are shown only in edit mode, so normal scrolling and
            // widget interaction aren't fighting the drag gesture.
            buildDefaultDragHandles: false,
            onReorderItem: store.reorder,
            itemBuilder: (context, index) {
              final widget = store.widgets[index];
              return Padding(
                key: ValueKey(widget.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: WorkspaceCard(
                  widget: widget,
                  index: index,
                  editing: _editing,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact header control sized to fit inside [WorkspaceCard]'s fixed header.
///
/// A plain `IconButton` enforces a 48px (40px when compact) minimum tap target,
/// which is taller than the header the cards can afford.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: child,
        ),
      ),
    );
  }
}

/// One widget card on the workspace.
///
/// Public so the widget-test matrix can render the real card rather than a
/// copy of its layout — the header/body height split is exactly what the
/// overflow tests need to exercise.
class WorkspaceCard extends StatelessWidget {
  const WorkspaceCard({
    super.key,
    required this.widget,
    required this.index,
    required this.editing,
  });

  /// Header height, identical in view and edit mode.
  static const _headerHeight = 22.0;

  final WorkspaceWidget widget;
  final int index;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.read<WorkspaceProvider>();

    return Card(
      child: SizedBox(
        height: widget.size.height,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed height so the body gets the same space in both modes.
              // Without this the edit controls make the header ~40px instead
              // of ~16px, silently stealing 24px from every card the moment
              // the user taps Edit — enough to overflow half the widgets.
              SizedBox(
                height: _headerHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.type.label,
                        style: theme.textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (editing) ...[
                      // Cycles S -> M -> L, replacing the desktop resize handle.
                      _HeaderButton(
                        tooltip: 'Resize',
                        onPressed: () => store.cycleSize(widget.id),
                        child: Text(
                          widget.size.label,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      _HeaderButton(
                        tooltip: 'Remove',
                        onPressed: () => store.remove(widget.id),
                        child: const Icon(Icons.close, size: 16),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.drag_handle, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // ClipRect is a backstop: content is written to fit, but text
              // scaling and translations vary, and painting outside the card
              // looks far worse than being clipped.
              Expanded(
                child: ClipRect(child: buildWidgetBody(context, widget)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
