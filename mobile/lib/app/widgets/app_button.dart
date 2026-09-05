import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Which of the two button treatments this is.
enum AppButtonVariant {
  /// Solid black pill, white label. One per screen — the thing you came to do.
  primary,

  /// White pill, black label, hairline black border. Everything else.
  secondary,

  /// Destructive confirmation. Reserved for actions that delete data with no
  /// undo; see [AppColors.error] for why this is the one coloured thing here.
  destructive,
}

/// The app's button.
///
/// Wraps [FilledButton]/[OutlinedButton] rather than replacing them so the
/// Material ink, focus, and accessibility behaviour all still apply. The
/// variants exist so a screen asks for a *role* rather than picking colours.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  }) : variant = AppButtonVariant.destructive;

  final String label;

  /// Null disables the button, as everywhere in Material.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;

  /// Full-width by default: these are page-level actions. Set false for a
  /// button sitting inline in a row.
  final bool expand;

  static const _minHeight = 52.0;
  static const _inset = EdgeInsets.symmetric(horizontal: AppSpacing.xxl);

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.subtleFill,
            disabledForegroundColor: AppColors.disabled,
            padding: _inset,
            minimumSize: const Size(0, _minHeight),
            // No shadow anywhere in this design — a pill on a white page
            // separates by fill, not by elevation.
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.disabled,
            side: BorderSide(
              color: onPressed == null ? AppColors.hairline : AppColors.ink,
              width: AppStroke.hairline,
            ),
            padding: _inset,
            minimumSize: const Size(0, _minHeight),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      AppButtonVariant.destructive => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.error,
            disabledForegroundColor: AppColors.disabled,
            side: BorderSide(
              color: onPressed == null ? AppColors.hairline : AppColors.error,
              width: AppStroke.hairline,
            ),
            padding: _inset,
            minimumSize: const Size(0, _minHeight),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
