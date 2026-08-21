import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll behaviour for the whole app.
///
/// Removes the overscroll stretch that Android 12+ applies by default. Pulling
/// past the end of a list squashed and smeared the entire page, which reads as
/// a rendering glitch on a dense financial dashboard — cards visibly distort
/// and numbers warp.
///
/// Worth knowing: **scroll physics and the overscroll indicator are separate.**
/// `ClampingScrollPhysics` stops the list from *travelling* past its edge
/// (the iOS-style rubber-band), but the stretch is drawn by
/// `StretchingOverscrollIndicator`, which `MaterialScrollBehavior` installs
/// independently. Setting the physics alone does nothing about it; the
/// indicator has to be overridden here.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Returning the child untouched means no stretch and no glow — the list
    // simply stops at its edge.
    return child;
  }

  /// Also allows dragging with a mouse or trackpad.
  ///
  /// The Material default omits mouse, so scrolling by dragging does nothing
  /// on a desktop or in an emulator window — only the wheel works.
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
