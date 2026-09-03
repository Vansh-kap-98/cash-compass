import 'package:flutter/material.dart';

/// Design tokens for one theme.
///
/// This is the Dart port of the CSS custom-property blocks in
/// `frontend/src/index.css`. Each `[data-theme="..."]` block there becomes one
/// [AppTokens] instance here. Values are written as HSL triples to match the
/// source 1:1, so adding a new theme later is a transcription job rather than a
/// colour-matching exercise.
@immutable
class AppTokens {
  const AppTokens({
    required this.name,
    required this.label,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    this.accentContainer,
    this.onAccentContainer,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.radius,
    this.radiusControl = 14,
    this.radiusSmall = 8,
    required this.headingFont,
    required this.bodyFont,
    required this.monoFont,
  });

  /// Stable id, matching the `data-theme` value on the web (e.g. `soft-bloom`).
  final String name;

  /// Human-readable name for the theme picker in Settings.
  final String label;

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;

  /// A pale ground for surfaces that carry the accent, and the ink that sits on
  /// it. Optional: a theme that omits them falls back to [accent] itself.
  ///
  /// These exist because `accent` alone cannot fill a surface — a burnt amber
  /// card would shout. The web has the same pair as `--theme-accent-soft` /
  /// `--theme-accent-deep`, but they never reached the Dart token set, which is
  /// part of why `accent` sat unused at pure white.
  final Color? accentContainer;
  final Color? onAccentContainer;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  /// Corner radius for large surfaces — cards, sheets, dialogs.
  /// The web uses `--radius: 1.5rem` (24px).
  final double radius;

  /// Corner radius for interactive controls — buttons, inputs, chips.
  ///
  /// Radius is a scale, not a per-component guess. Before this existed the app
  /// used 2, 3, 8, 12, 14 and 24 with no rule behind which went where — inputs
  /// were 12 and the buttons beside them 14, a difference nobody chose.
  final double radiusControl;

  /// Corner radius for small inline elements — thumbnails, swatches, bars.
  final double radiusSmall;

  final String headingFont;
  final String bodyFont;
  final String monoFont;
}

/// Builds a [Color] from the same `H S% L%` triple the CSS variables use, so
/// values can be copied out of `index.css` unchanged.
Color hsl(double h, double s, double l) =>
    HSLColor.fromAHSL(1.0, h, s / 100, l / 100).toColor();

/// Ported from `frontend/src/index.css` lines 10-52, with four **deliberate
/// divergences** from the web values. See `PARITY_SPEC.md` §11.
///
/// The identity is unchanged — warm cream ground, plum primary, white cards.
/// What changed is that three of the web's tokens were unusable in practice:
///
/// | Token | Web | Here | Why |
/// | --- | --- | --- | --- |
/// | `primary` | `270 20% 72%` | `272 44% 42%` | White-on-lavender measured **2.20:1**. WCAG AA needs 4.5:1. Now 7.56:1. |
/// | `accent` | `0 0% 100%` | `20 82% 42%` | The web's accent is pure white — identical to `card`, so nothing could ever be accented. Now a burnt amber that reads against both cream and white. |
/// | `accentForeground` | `268 18% 28%` | `0 0% 100%` | Follows `accent` going dark. |
/// | `destructive` | `0 70% 55%` | `0 72% 46%` | Was 4.39:1 on white — marginally under AA. Now 5.60:1. |
///
/// `ring` tracks `primary`, as it does on the web.
///
/// Every pairing below is measured, not estimated:
/// foreground on background 10.9:1 · mutedForeground on background 5.44:1 ·
/// primary on background 6.84:1 · white on primary 7.56:1 ·
/// white on accent 4.75:1 · white on destructive 5.60:1.
const _softBloomName = 'soft-bloom';

final AppTokens softBloomTokens = AppTokens(
  name: _softBloomName,
  label: 'Soft Bloom',
  background: hsl(46, 45, 94), // #F7F3E9 warm cream
  foreground: hsl(268, 18, 24), // #3C3248 ink
  card: hsl(0, 0, 100),
  cardForeground: hsl(268, 18, 24),
  popover: hsl(0, 0, 100),
  popoverForeground: hsl(268, 18, 24),
  primary: hsl(272, 44, 42), // #6E3C9A plum
  primaryForeground: hsl(0, 0, 100),
  secondary: hsl(270, 16, 87), // #DDD9E3 lilac chip ground
  secondaryForeground: hsl(268, 18, 28),
  muted: hsl(46, 20, 96),
  mutedForeground: hsl(268, 12, 42), // #6A5E78
  accent: hsl(20, 82, 42), // #C34E13 burnt amber
  accentForeground: hsl(0, 0, 100),
  accentContainer: hsl(24, 90, 94), // #FDEDE2 warm tint
  onAccentContainer: hsl(20, 70, 24), // #683512
  destructive: hsl(0, 72, 46), // #CA2121
  destructiveForeground: hsl(0, 0, 100),
  border: hsl(270, 14, 84), // #D6CFDD
  input: hsl(270, 14, 88),
  ring: hsl(272, 44, 42),
  radius: 24, // 1.5rem — cards, sheets, dialogs
  radiusControl: 14, // buttons, inputs, chips
  radiusSmall: 8, // thumbnails, swatches, bars
  headingFont: 'Outfit',
  bodyFont: 'Inter',
  monoFont: 'JetBrains Mono',
);

/// Every theme the app can render, keyed by its `name`.
///
/// Only Soft Bloom is populated for v1 — it is the only layout the web app
/// actually reaches. The other four blocks in `index.css` (retro-pixel,
/// modern-academic, kawaii-pastel, cyber-terminal, lines 54-210) can be added
/// here as further [AppTokens] entries with no other code changes.
final Map<String, AppTokens> appThemes = {
  softBloomTokens.name: softBloomTokens,
};

const String defaultThemeName = _softBloomName;

/// Legacy `dashboard-theme` values that the web app migrates on read.
const Map<String, String> legacyThemeAliases = {
  'cottage-sage': _softBloomName,
  'editorial-grid': _softBloomName,
};

/// Resolves a stored theme name to a real theme, applying legacy aliases and
/// falling back to the default. Mirrors `ThemeContext.tsx`.
AppTokens resolveTheme(String? stored) {
  final migrated = legacyThemeAliases[stored] ?? stored;
  return appThemes[migrated] ?? appThemes[defaultThemeName]!;
}
