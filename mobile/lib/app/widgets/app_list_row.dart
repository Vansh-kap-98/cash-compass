import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Leading glyph, title plus secondary line, trailing value or chevron.
///
/// The shape most of this app's lists already have — a transaction, a
/// subscription, a goal, a settings entry — expressed once so they stop
/// drifting apart.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingSubtitle,
    this.onTap,
    this.showChevron = false,
    this.emphasiseTrailing = true,
  });

  final String title;
  final String? subtitle;

  /// Typically an [AppIconTile] or an [AppAvatar].
  final Widget? leading;

  /// The value at the right edge — usually a formatted amount.
  final String? trailing;

  /// A second, smaller line under [trailing].
  final String? trailingSubtitle;

  final VoidCallback? onTap;

  /// Adds a chevron after [trailing]. For rows that navigate.
  final bool showChevron;

  /// Renders [trailing] at body weight rather than semibold. Turn off where the
  /// value is incidental rather than the point of the row.
  final bool emphasiseTrailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing!,
                  style: emphasiseTrailing ? text.titleSmall : text.bodyMedium,
                ),
                if (trailingSubtitle != null)
                  Text(trailingSubtitle!, style: text.bodySmall),
              ],
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.inkSecondary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: row,
    );
  }
}

/// A hairline between rows.
///
/// Separate from [AppListRow] so a list owns its own separator policy — no
/// trailing rule under the last row, which is what a per-row divider gives you.
class AppRowDivider extends StatelessWidget {
  const AppRowDivider({super.key, this.indent = 0});

  /// Left inset, so a rule can start where the text does rather than under the
  /// leading glyph.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppStroke.hairline,
      thickness: AppStroke.hairline,
      indent: indent,
      color: AppColors.hairline,
    );
  }
}
