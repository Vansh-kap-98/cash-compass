import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// How much weight a card carries.
///
/// The reference sheet uses all three: most cards are white with a hairline,
/// the one figure a page is built from sits on grey, and the hero card — the
/// thing the screen exists to show — inverts to solid ink.
enum AppCardTone {
  /// White with a hairline border. The default, and most of the app.
  plain,

  /// Filled with [AppColors.subtleFill]. Recessed rather than louder — for a
  /// figure everything else on the page is derived from.
  quiet,

  /// Solid ink with white content. One per screen at most: a second black card
  /// on a page turns emphasis into wallpaper.
  ///
  /// **Build the contents through a `Builder`.** The inversion is a `Theme`
  /// wrapped around the child, so it only reaches widgets that call
  /// `Theme.of` *below* the card. A style read from the enclosing `build` —
  /// `final theme = Theme.of(context)` at the top of the method — is the light
  /// one, and paints black type on the black panel. It lays out correctly and
  /// is completely invisible, which is a nastier failure than an obvious one.
  ink,
}

/// A surface with a hairline border, or an inverted ink panel.
///
/// The brief offers a choice between a hairline border and a subtle shadow;
/// this design takes the border and uses it everywhere. Mixing the two is what
/// makes a page look assembled from two different kits, and a hairline stays
/// crisp at every device pixel ratio where a 1dp shadow goes muddy.
///
/// Emphasis comes from [tone] or from spacing — never from a coloured edge.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInset,
    this.tone = AppCardTone.plain,
    this.onTap,
  });

  /// Shorthand for the hero card.
  const AppCard.ink({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInset,
    this.onTap,
  }) : tone = AppCardTone.ink;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardTone tone;

  /// Makes the whole card tappable, with a ripple clipped to its radius.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isInk = tone == AppCardTone.ink;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.surface),
      side: const BorderSide(
        // The ink card's fill already separates it, but it keeps an edge of its
        // own colour so every card measures the same — otherwise a black one
        // would sit 1dp narrower than the white one above it.
        color: AppColors.outline,
        width: AppStroke.hairline,
      ),
    );

    Widget body = Padding(padding: padding, child: child);

    // Everything inside an ink card is re-themed rather than re-coloured by
    // hand, so a widget dropped onto one reads correctly without knowing it is
    // on a dark ground. See [invertTheme].
    if (isInk) {
      body = Theme(data: invertTheme(Theme.of(context)), child: body);
    }

    return Material(
      color: switch (tone) {
        AppCardTone.plain => AppColors.surface,
        AppCardTone.quiet => AppColors.subtleFill,
        AppCardTone.ink => AppColors.ink,
      },
      shape: shape,
      // Explicitly flat. See the class doc.
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
