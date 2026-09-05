import 'package:flutter/painting.dart';

/// Spacing and radius scale.
///
/// The app is on a 4px grid. Values that are not multiples of 4 are how the
/// previous palette ended up with a 14/6 card sitting next to a 16/8 one.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Standard page gutter.
  static const pageInset = EdgeInsets.symmetric(horizontal: lg);

  /// Page padding for a scrolling tab, leaving room for the bottom bar.
  static const tabScroll = EdgeInsets.fromLTRB(lg, lg, lg, 112);

  /// Padding inside a card.
  static const cardInset = EdgeInsets.all(lg);
}

/// Corner radii.
///
/// Generous, and consistent per component type. Buttons and the bottom bar are
/// pills; cards and sheets share one surface radius.
abstract final class AppRadius {
  /// Cards, sheets, dialogs.
  static const surface = 20.0;

  /// Inputs and anything that ripples over them.
  static const control = 14.0;

  /// Thumbnails, swatches, inline bars, icon tiles.
  static const small = 10.0;

  /// Buttons and the bottom bar. Large enough to read as a pill at any height.
  static const pill = 999.0;
}

/// Stroke weights.
abstract final class AppStroke {
  /// Card borders and dividers. One hairline everywhere.
  static const hairline = 1.0;

  /// Progress ring arc and track.
  static const ring = 6.0;
}
