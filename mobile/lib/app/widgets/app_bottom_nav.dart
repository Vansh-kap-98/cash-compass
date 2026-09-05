import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One tab in [AppBottomNav].
@immutable
class AppNavDestination {
  const AppNavDestination({required this.icon, required this.label});

  /// A line icon. Outlined weights read better dim against black than filled
  /// ones, which turn into grey blobs at 24dp.
  final IconData icon;

  /// Not painted — the bar is icon-only — but announced by screen readers and
  /// shown on long-press. It is the only name a tab has, so it must be the
  /// real, localised one.
  final String label;
}

/// The black capsule bar with a neon-white glow on the active tab.
///
/// The glow is built from two independent pieces, which is what keeps it both
/// convincing and cheap:
///
/// * A **halo** — a white radial gradient that slides to the selected slot.
///   A gradient is a shader fill, so moving it every frame costs nothing like
///   a blur would, and it carries all of the travel.
/// * A **bloom** — two blurred copies of the glyph under the sharp one, which
///   is what stops the lit icon looking like a flat white fill. This is a real
///   `ImageFilter.blur`, so it is built *only* for slots that are actually
///   glowing; at rest that is one, and mid-transition two.
///
/// Deliberately not done here: no raised bump deforming the bar's top edge —
/// that reads as skeuomorphic and fights the flat treatment everywhere else —
/// and no `BackdropFilter`, which blurs everything painted beneath it and is
/// the usual cause of bottom-bar jank.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavDestination> destinations;

  /// Long enough to read as travel rather than a jump, short enough not to lag
  /// the tab content that switches instantly beneath it.
  static const duration = Duration(milliseconds: 260);
  static const curve = Curves.easeInOut;

  /// Identifies the glow so a test can measure where it actually landed.
  /// Its widget properties hold the animation's *target*, so only the rendered
  /// rect says whether it is under the right icon.
  static const haloKey = Key('app-bottom-nav-halo');

  static const _barHeight = 64.0;
  static const _iconSize = 24.0;
  static const _haloSize = 54.0;

  @override
  Widget build(BuildContext context) {
    final count = destinations.length;
    assert(count > 0, 'a nav bar with no destinations has nothing to show');

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        // The bar animates on every tab change while the page behind it does
        // not; isolating it keeps that repaint off the rest of the tree.
        child: RepaintBoundary(
          child: SizedBox(
            height: _barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
              child: ClipRRect(
                // Clips the halo, which is wider than a slot and would
                // otherwise bleed past the capsule's rounded ends.
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Halo(
                      index: currentIndex,
                      count: count,
                      size: _haloSize,
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < count; i++)
                          Expanded(
                            child: _NavSlot(
                              destination: destinations[i],
                              selected: i == currentIndex,
                              iconSize: _iconSize,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sliding radial glow behind the selected icon.
class _Halo extends StatelessWidget {
  const _Halo({
    required this.index,
    required this.count,
    required this.size,
  });

  final int index;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Laid out in pixels against the bar's measured width rather than with
      // `Alignment`. Alignment places a child's *centre* at
      // `parentCentre + x · (parentWidth − childWidth) / 2`, so mapping slot
      // centres onto its −1..1 axis pulls every halo toward the middle by a
      // factor of `width / (width − haloSize)` — about 20% here, and most
      // visible on the outermost tabs, which is exactly where it looked wrong.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / count;
          final left = slot * (index + 0.5) - size / 2;
          final top = (constraints.maxHeight - size) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                left: left,
                top: top,
                width: size,
                height: size,
                duration: AppBottomNav.duration,
                curve: AppBottomNav.curve,
                child: const IgnorePointer(
                  key: AppBottomNav.haloKey,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x66FFFFFF),
                          Color(0x1FFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One tappable icon, with its bloom.
class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.destination,
    required this.selected,
    required this.iconSize,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        // The bar carries no text, so this is how a name is reachable at all
        // without a screen reader.
        message: destination.label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox(
            height: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: selected ? 1 : 0),
              duration: AppBottomNav.duration,
              curve: AppBottomNav.curve,
              builder: (context, t, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Built only while this slot is actually lit. An
                    // ImageFiltered with zero opacity still allocates and
                    // filters a layer, so skipping it entirely is what keeps
                    // the cost to the one or two slots mid-transition rather
                    // than all five, every frame.
                    if (t > 0.01) ..._bloom(t),
                    Icon(
                      destination.icon,
                      size: iconSize,
                      color: Color.lerp(
                        AppColors.onInkDim,
                        AppColors.surface,
                        t,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Two blurred copies under the sharp glyph — a wide, faint pass for the
  /// spill and a tight, brighter one for the core. One pass alone reads as a
  /// smudge; three is not distinguishable from two at this size.
  List<Widget> _bloom(double t) {
    Widget pass(double sigma, double alpha) => IgnorePointer(
          child: Opacity(
            opacity: (alpha * t).clamp(0.0, 1.0),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Icon(
                destination.icon,
                size: iconSize,
                color: AppColors.surface,
              ),
            ),
          ),
        );

    return [pass(9, 0.85), pass(4, 0.95)];
  }
}
