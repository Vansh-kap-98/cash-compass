import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The page ground: thin drawn curves instead of flat white.
///
/// Sits behind a screen's content, never in front of it. Cards are opaque
/// white, so this only ever shows through the gutters and the empty space
/// below short pages — which is the point, since that space is what read as
/// unfinished.
///
/// Two rules keep it from becoming decoration for its own sake:
///
/// * **It is drawn at hairline weight in [AppColors.backdropLine]**, one step
///   darker than the rule between list rows — 1.36:1 on white. Far too light
///   to compete with content, and just dark enough to be seen at all, which
///   the divider grey was not.
/// * **It is anchored to the page's corners**, not scattered. The curves sweep
///   out of the top-left and back into the bottom-right, so the eye reads them
///   as a ground the content sits on rather than as objects on the page.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, this.child});

  /// Painted over the backdrop. Omit to use this as a bare background.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The curves never change, so this paints once and is skipped on every
        // rebuild of the content above it.
        // IgnorePointer because a background must never swallow a tap — in
        // the empty regions this is the topmost thing under the finger.
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _BackdropPainter()),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = AppColors.backdropLine;

    // A softer pass for the largest shapes, so the composition has depth
    // without any single line asking to be looked at.
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = AppColors.backdropLine.withValues(alpha: 0.6);

    // Top-left: two nested sweeps leaving the corner.
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.10, h * 0.16)
        ..cubicTo(
          w * 0.18,
          h * 0.05,
          w * 0.46,
          h * 0.12,
          w * 0.72,
          h * 0.02,
        ),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.06, h * 0.24)
        ..cubicTo(
          w * 0.22,
          h * 0.12,
          w * 0.52,
          h * 0.20,
          w * 0.84,
          h * 0.07,
        ),
      faint,
    );

    // A long diagonal through the middle third, well below the fold on a
    // scrolling page and behind the cards everywhere else.
    canvas.drawPath(
      Path()
        ..moveTo(w * 1.05, h * 0.42)
        ..cubicTo(
          w * 0.70,
          h * 0.50,
          w * 0.42,
          h * 0.44,
          -w * 0.05,
          h * 0.58,
        ),
      faint,
    );

    // Bottom-right: a large arc returning to the corner, plus a ring that is
    // mostly off-canvas. Both are clipped by the page edge, which is what
    // stops them reading as objects.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, h * 1.02)
        ..cubicTo(
          w * 0.50,
          h * 0.88,
          w * 0.74,
          h * 0.94,
          w * 1.06,
          h * 0.78,
        ),
      stroke,
    );
    canvas.drawCircle(Offset(w * 1.02, h * 0.90), w * 0.34, faint);

    // One small closed mark, off to the left, to break the parallel sweeps.
    canvas.drawCircle(Offset(w * 0.12, h * 0.72), w * 0.16, faint);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}
