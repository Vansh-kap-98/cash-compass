import 'package:flutter/material.dart';

/// Shared chrome for the modal bottom sheets: drag handle, title block, a
/// scrollable body that stays clear of the keyboard, and a pinned submit
/// button.
///
/// Sheets grow with the keyboard rather than being covered by it, which is the
/// main reason these are sheets and not dialogs.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onSubmit,
    required this.submitLabel,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      // Lifts the sheet above the software keyboard.
      padding: EdgeInsets.only(bottom: viewInsets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: Text(submitLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
