import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Circular percentage indicator: black arc on a grey track, figure centred.
///
/// A [CustomPaint] rather than a [CircularProgressIndicator] because Material's
/// indicator cannot show a centred label, and stacking one behind a [Text]
/// leaves the arc cap and the type fighting for the same optical centre.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    this.size = 72,
    this.label,
    this.strokeWidth = AppStroke.ring,
  });

  /// 0..1. Values outside are clamped — a goal at 130% still draws a full ring
  /// rather than winding round a second time.
  final double progress;

  final double size;

  /// Centred text. Defaults to the rounded percentage; pass a string to show
  /// something else, or an empty one to show nothing.
  final String? label;

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    final text = label ?? '${(clamped * 100).round()}%';

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: clamped, strokeWidth: strokeWidth),
        child: Center(
          child: text.isEmpty
              ? null
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    // Keeps the figure clear of the arc at small diameters and
                    // at large text scales.
                    padding: EdgeInsets.all(strokeWidth + AppSpacing.xs),
                    child: Text(
                      text,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.subtleFill;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.ink;

    canvas.drawCircle(centre, radius, track);

    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      // Twelve o'clock, clockwise — the direction a reader expects a dial to
      // fill, and the one the reference shows.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
