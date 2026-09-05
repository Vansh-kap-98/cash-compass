import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A full-bleed ink panel whose lower edge is a wave rather than a straight cut.
///
/// The reference sheet opens on one of these: the wordmark sits in solid black
/// across the top of the screen, and the black releases into the page along a
/// curve instead of a hard line. It is the one place the design allows a shape
/// that is not a rectangle or a circle, which is what makes it read as the
/// front door rather than as another card.
///
/// Its contents are re-themed by [invertTheme], so anything placed inside is
/// legible on the ink without being told.
class AppHeaderPanel extends StatelessWidget {
  const AppHeaderPanel({
    super.key,
    required this.child,
    this.height = 260,
  });

  final Widget child;

  /// Height to the *deepest* point of the wave. The panel's flat area is
  /// shorter than this, which is why content sits in the upper part of it.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _WaveClipper(),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: AppColors.ink,
          child: Theme(
            data: invertTheme(Theme.of(context)),
            child: SafeArea(
              bottom: false,
              // The wave eats into the bottom third, so content is kept clear
              // of it rather than centred in the box and clipped by the curve.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 72),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    // One broad lobe, as the reference draws it: the edge falls away from the
    // left, bottoms out left of centre, then lifts in a long clean run to a
    // right edge that sits higher than the left. An earlier version used two
    // lobes and read as busy — a single asymmetric sweep is quieter and is
    // what the sheet actually shows.
    //
    // Control points are fractions of the box, so the curve keeps its shape on
    // any width instead of flattening out on a wide screen.
    return Path()
      ..lineTo(0, h * 0.72)
      ..cubicTo(w * 0.22, h * 0.99, w * 0.46, h * 1.00, w * 0.66, h * 0.84)
      ..cubicTo(w * 0.80, h * 0.73, w * 0.90, h * 0.66, w, h * 0.56)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
