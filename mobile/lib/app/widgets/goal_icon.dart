import 'package:flutter/material.dart';

/// Line glyphs for the marks a savings goal can carry.
///
/// **The stored value is still an emoji, and must stay one.** The web app
/// renders `goal.icon` as text (`SavingsProgress.tsx`), so a goal saved on the
/// phone with a key like `'travel'` would show the literal word there. The two
/// clients share this JSON, so the data stays as it was and only this app's
/// *rendering* changes: the emoji is a lookup key here, never painted.
///
/// That is also why an emoji cannot simply be styled instead. It renders from a
/// colour font whatever style is applied, so on a monochrome page it cannot be
/// toned down — only swapped for something drawn.
const Map<String, IconData> goalIcons = {
  '🎯': Icons.adjust_outlined,
  '✈️': Icons.flight_outlined,
  '🏠': Icons.home_outlined,
  '💻': Icons.laptop_outlined,
  '🚗': Icons.directions_car_outlined,
  '📚': Icons.school_outlined,
  '🩺': Icons.favorite_outline,
  '🎁': Icons.card_giftcard_outlined,
  '🛟': Icons.shield_outlined,
  '🪙': Icons.savings_outlined,
};

/// What a goal created without an explicit mark carries. Unchanged from before
/// the icon set existed, so nothing about new records moves.
const String defaultGoalIconKey = '🎯';

/// Glyph for a stored mark.
///
/// A goal carrying an emoji this app does not offer — typed on the web, or
/// saved by an older build that had a free-text field — resolves to the default
/// glyph rather than rendering the character. No migration, and nothing on
/// screen is ever a colour emoji.
IconData goalIcon(String? stored) =>
    goalIcons[stored] ?? goalIcons[defaultGoalIconKey]!;
