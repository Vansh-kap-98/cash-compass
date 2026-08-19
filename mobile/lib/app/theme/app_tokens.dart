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
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.radius,
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
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  /// Corner radius in logical pixels. The web uses `--radius: 1.5rem` (24px).
  final double radius;

  final String headingFont;
  final String bodyFont;
  final String monoFont;
}

/// Builds a [Color] from the same `H S% L%` triple the CSS variables use, so
/// values can be copied out of `index.css` unchanged.
Color hsl(double h, double s, double l) =>
    HSLColor.fromAHSL(1.0, h, s / 100, l / 100).toColor();

/// Ported from `frontend/src/index.css` lines 10-52.
const _softBloomName = 'soft-bloom';

final AppTokens softBloomTokens = AppTokens(
  name: _softBloomName,
  label: 'Soft Bloom',
  background: hsl(46, 45, 94),
  foreground: hsl(268, 18, 24),
  card: hsl(0, 0, 100),
  cardForeground: hsl(268, 18, 24),
  popover: hsl(0, 0, 100),
  popoverForeground: hsl(268, 18, 24),
  primary: hsl(270, 20, 72),
  primaryForeground: hsl(0, 0, 100),
  secondary: hsl(270, 16, 87),
  secondaryForeground: hsl(268, 18, 28),
  muted: hsl(46, 20, 96),
  mutedForeground: hsl(268, 12, 42),
  accent: hsl(0, 0, 100),
  accentForeground: hsl(268, 18, 28),
  destructive: hsl(0, 70, 55),
  destructiveForeground: hsl(0, 0, 100),
  border: hsl(270, 14, 84),
  input: hsl(270, 14, 88),
  ring: hsl(270, 20, 72),
  radius: 24, // 1.5rem
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
