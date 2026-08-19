import 'package:flutter/material.dart';

/// The Workspace tab.
///
/// Placeholder until the redesigned widget canvas lands. The web version's
/// 12-column drag-resize grid is being replaced with a single-column
/// reorderable list plus a small/medium/large size toggle, since pixel-precise
/// resize handles don't work with a finger.
class WorkspaceTab extends StatelessWidget {
  const WorkspaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Text(
              'Workspace',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Customisable widgets are coming here.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
