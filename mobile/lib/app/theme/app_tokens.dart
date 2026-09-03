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
    this.primaryContainer,
    this.onPrimaryContainer,
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

  /// The filled-surface pair for the brand colour, when the brand colour itself
  /// is too light to carry text.
  ///
  /// [primary] is what the app draws *as ink* -- links, icons, chart series,
  /// the selected tab -- so it has to clear 4.5:1 on a light ground. A pale
  /// brand colour cannot do both jobs, so it lives here and fills surfaces
  /// instead, with [onPrimaryContainer] on top of it. Optional: a theme that
  /// omits the pair falls back to [primary]/[primaryForeground].
  final Color? primaryContainer;
  final Color? onPrimaryContainer;
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

/// Builds an opaque [Color] from a `0xRRGGBB` literal.
///
/// Used where a value came from a supplied palette as an exact hex rather than
/// from the web stylesheet -- round-tripping those through HSL drifts them by a
/// digit or two, and a palette handed over as hex should stay that hex.
Color hex(int rgb) => Color(0xFF000000 | rgb);

/// Soft Bloom.
///
/// The palette is the four-swatch set supplied on 2026-09-03 -- Floral White,
/// Lavender, Periwinkle, Wisteria Blue -- which replaces the plum/amber scheme
/// ported from `frontend/src/index.css`. The web app is unchanged; the
/// divergence is recorded in `PARITY_SPEC.md` §11.
///
/// The four supplied swatches are used at their exact hex. Six further values
/// are **derived**, because a four-tint palette cannot dress a whole UI on its
/// own -- it has no ink, no white, and no error colour:
///
/// | Role | Value | Where it comes from |
/// | --- | --- | --- |
/// | `background` | `#F7F4EA` | **Floral White**, supplied |
/// | `secondary`, `input` | `#DED9E2` | **Lavender**, supplied |
/// | `accentContainer` | `#C0B9DD` | **Periwinkle**, supplied |
/// | `primaryContainer` | `#80A1D4` | **Wisteria Blue**, supplied |
/// | `card` | `#FFFFFF` | derived -- the set has no white, and cards must lift off the ground |
/// | `foreground` | `#232743` | derived ink at the family's hue (232°) |
/// | `mutedForeground` | `#5A5F7C` | derived, same hue |
/// | `primary` | `#3B619B` | **Wisteria darkened**, same hue (216°) |
/// | `accent` | `#5F4CA9` | **Periwinkle deepened**, same hue (252°) |
/// | `border` | `#D1C9D9` | derived between Lavender and the ground |
/// | `destructive` | `#CA2121` | kept -- an error colour is semantic, not brand |
///
/// **Why the two blues.** Wisteria Blue cannot carry text: white on it measures
/// **2.64:1**, under both the 4.5:1 body floor and the 3:1 large-text floor.
/// `colorScheme.primary` is read as *ink* at fifteen call sites in this app --
/// links, icons, chart series, the selected tab, income amounts -- so `primary`
/// is the darkened Wisteria that clears 5.67:1, and the supplied Wisteria fills
/// buttons and selected chips as `primaryContainer` with dark ink on it. Same
/// hue, so they read as one colour; only one of them is legible as type.
///
/// Every pairing is measured, not estimated:
/// foreground on background **13.2:1** · mutedForeground on background 5.68:1 ·
/// primary on background 5.67:1 · white on primary 6.23:1 ·
/// ink on Wisteria fill 5.52:1 · ink on Lavender 10.5:1 ·
/// ink on Periwinkle 7.79:1 · white on accent 6.80:1 ·
/// white on destructive 5.60:1.
const _softBloomName = 'soft-bloom';

final AppTokens softBloomTokens = AppTokens(
  name: _softBloomName,
  label: 'Soft Bloom',
  background: hex(0xF7F4EA), // Floral White
  foreground: hex(0x232743), // derived ink
  card: hex(0xFFFFFF),
  cardForeground: hex(0x232743),
  popover: hex(0xFFFFFF),
  popoverForeground: hex(0x232743),
  primary: hex(0x3B619B), // Wisteria, darkened so it works as type
  primaryForeground: hex(0xFFFFFF),
  primaryContainer: hex(0x80A1D4), // Wisteria Blue
  onPrimaryContainer: hex(0x232743),
  secondary: hex(0xDED9E2), // Lavender
  secondaryForeground: hex(0x232743),
  muted: hex(0xF7F5F9),
  mutedForeground: hex(0x5A5F7C),
  accent: hex(0x5F4CA9), // Periwinkle, deepened so it works as type
  accentForeground: hex(0xFFFFFF),
  accentContainer: hex(0xC0B9DD), // Periwinkle
  onAccentContainer: hex(0x232743),
  destructive: hex(0xCA2121),
  destructiveForeground: hex(0xFFFFFF),
  border: hex(0xD1C9D9),
  input: hex(0xDED9E2), // Lavender
  ring: hex(0x3B619B),
  radius: 24, // cards, sheets, dialogs
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
