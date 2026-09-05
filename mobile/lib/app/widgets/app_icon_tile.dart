import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Black rounded square, white glyph. The category marker.
///
/// Takes either an [IconData] or a short string, so an emoji category icon —
/// which is what the transaction and goal records actually store — can sit in
/// the same slot as a Material icon without a second component.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    this.icon,
    this.glyph,
    this.size = 40,
    this.muted = false,
  }) : assert(icon != null || glyph != null, 'give it an icon or a glyph');

  const AppIconTile.icon(IconData this.icon, {super.key, this.size = 40})
      : glyph = null,
        muted = false;

  /// A short string — an emoji, or one or two initials.
  const AppIconTile.glyph(String this.glyph, {super.key, this.size = 40})
      : icon = null,
        muted = false;

  final IconData? icon;
  final String? glyph;
  final double size;

  /// Grey ground instead of black, for a de-emphasised or inactive row.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ground = muted ? AppColors.subtleFill : AppColors.ink;
    final onGround = muted ? AppColors.inkSecondary : AppColors.surface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.small),
        // The black tile is bounded by its own fill. The muted one is pale grey
        // on white and would otherwise have no edge at all.
        border: muted
            ? Border.all(color: AppColors.outline, width: AppStroke.hairline)
            : null,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: onGround)
          // An emoji renders in its own colour font regardless of the style, so
          // the tile stays black-and-white only for text glyphs. That is
          // deliberate: recolouring a user's chosen emoji is worse than the
          // small amount of colour it brings.
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  glyph!,
                  style: TextStyle(
                    fontSize: size * 0.45,
                    height: 1,
                    color: onGround,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}
