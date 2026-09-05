import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The app's one [ThemeData].
///
/// There is no theme switching. The web app carried five `data-theme` blocks
/// and this port carried the machinery to match, but only one was ever built
/// and the picker shipped with a single entry in it. That machinery is gone:
/// the palette in [AppColors], the scale in [AppTypography], and the geometry
/// in [AppSpacing] are the whole of it.
///
/// Everything colour- or radius-related must still come from here rather than
/// from literals in widgets — that discipline is what makes a change like this
/// one possible at all.
///
/// Text *size* is deliberately not handled here — see `main.dart`, which scales
/// through `MediaQuery.textScaler` at paint time. Baking the Settings slider
/// into [ThemeData] does not work with a downloaded font: the styles come back
/// with a null `fontSize`, and multiplying null yields nothing.
ThemeData buildTheme() => _cached ??= _build();

ThemeData? _cached;

/// The radius scale, carried on [ThemeData] so widgets can ask for it instead
/// of guessing a literal.
///
/// Kept as a [ThemeExtension] rather than folded into [AppRadius] because the
/// widgets that need it are drawing their own rounded surface — an [InkWell]
/// ripple over an [InputDecorator], an image thumbnail — and reading it from
/// the theme keeps a ripple aligned to the field it sits in when either moves.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    required this.surface,
    required this.control,
    required this.small,
  });

  /// Cards, sheets, dialogs.
  final double surface;

  /// Inputs, and anything that ripples over them.
  final double control;

  /// Thumbnails, swatches, inline bars.
  final double small;

  BorderRadius get controlBorder => BorderRadius.circular(control);
  BorderRadius get smallBorder => BorderRadius.circular(small);

  @override
  AppRadii copyWith({double? surface, double? control, double? small}) =>
      AppRadii(
        surface: surface ?? this.surface,
        control: control ?? this.control,
        small: small ?? this.small,
      );

  @override
  AppRadii lerp(AppRadii? other, double s) {
    if (other == null) return this;
    return AppRadii(
      surface: lerpDouble(surface, other.surface, s)!,
      control: lerpDouble(control, other.control, s)!,
      small: lerpDouble(small, other.small, s)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<AppRadii>()`, falling back to the
/// default scale so a theme built without the extension still renders.
extension AppRadiiAccess on ThemeData {
  AppRadii get radii =>
      extension<AppRadii>() ??
      const AppRadii(
        surface: AppRadius.surface,
        control: AppRadius.control,
        small: AppRadius.small,
      );
}

/// The theme to use *inside* an ink-filled surface.
///
/// Ink and surface swap roles: type, icons, borders and controls all invert so
/// anything placed on a black panel reads without being told to.
///
/// This exists because the text theme carries explicit colours. A widget asking
/// for `textTheme.titleMedium` on a black card would otherwise get black type
/// on black, and a `DefaultTextStyle` cannot help — an explicit colour wins
/// over an inherited one. Overriding the theme for the subtree is the only
/// treatment that reaches every descendant, including ones written before the
/// dark surface existed.
ThemeData invertTheme(ThemeData base) {
  final text = base.textTheme.apply(
    bodyColor: AppColors.surface,
    displayColor: AppColors.surface,
  );

  // Dimmed white, for what `inkSecondary` says on a light ground.
  const onInkMuted = Color(0xB3FFFFFF);
  const onInkLine = Color(0x3DFFFFFF);

  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: text.copyWith(
      bodySmall: text.bodySmall?.copyWith(color: onInkMuted),
      labelMedium: text.labelMedium?.copyWith(color: onInkMuted),
      labelSmall: text.labelSmall?.copyWith(color: onInkMuted),
    ),
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.ink,
      onSurface: AppColors.surface,
      onSurfaceVariant: onInkMuted,
      primary: AppColors.surface,
      onPrimary: AppColors.ink,
      outline: onInkLine,
      outlineVariant: onInkLine,
    ),
    iconTheme: const IconThemeData(color: AppColors.surface, size: 22),
    dividerColor: onInkLine,
    dividerTheme: const DividerThemeData(
      color: onInkLine,
      thickness: AppStroke.hairline,
      space: AppStroke.hairline,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: border(onInkLine),
      enabledBorder: border(onInkLine),
      focusedBorder: border(AppColors.surface, width: 2),
      disabledBorder: border(onInkLine),
      labelStyle: const TextStyle(color: onInkMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.surface),
      hintStyle: const TextStyle(color: onInkMuted),
      helperStyle: const TextStyle(color: onInkMuted),
    ),
    // Inverted again: a chip on a black card is white with dark type.
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      side: const BorderSide(color: AppColors.surface),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.surface,
        textStyle: text.labelLarge,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.surface,
      selectionHandleColor: AppColors.surface,
      selectionColor: Color(0x59FFFFFF),
    ),
  );
}

/// Maps the palette onto Material's colour roles.
///
/// This mapping is the lever that makes the re-skin tractable: every widget in
/// the app already reads `colorScheme.primary`, `.error`, `.onSurfaceVariant`
/// and so on rather than naming colours itself, so pointing those roles at the
/// monochrome palette re-skins the whole tree at once. What is left afterwards
/// is *shape* work — pills, hairlines, spacing — not a colour hunt.
const _scheme = ColorScheme(
  brightness: Brightness.light,

  // Primary is the ink. Buttons, links, active states, progress.
  primary: AppColors.ink,
  onPrimary: AppColors.surface,
  primaryContainer: AppColors.subtleFill,
  onPrimaryContainer: AppColors.ink,

  // Secondary carries the quiet fills: chips at rest, muted panels.
  secondary: AppColors.subtleFill,
  onSecondary: AppColors.ink,
  secondaryContainer: AppColors.subtleFill,
  onSecondaryContainer: AppColors.ink,

  // Tertiary was the old accent slot, used for the one emphasised figure on
  // the dashboard. It stays ink; the emphasis now comes from the fill behind
  // it, which is the rule this design applies everywhere.
  tertiary: AppColors.ink,
  onTertiary: AppColors.surface,
  tertiaryContainer: AppColors.subtleFill,
  onTertiaryContainer: AppColors.ink,

  // The one exception. See AppColors.error.
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.subtleFill,
  onErrorContainer: AppColors.error,

  surface: AppColors.surface,
  onSurface: AppColors.ink,
  surfaceContainerHighest: AppColors.subtleFill,
  onSurfaceVariant: AppColors.inkSecondary,

  // Material's own split, and the same one this palette makes: `outline` is
  // the edge of a container, `outlineVariant` a rule drawn inside one. Any
  // widget the app has not themed by hand still lands on the right side of
  // it.
  outline: AppColors.outline,
  outlineVariant: AppColors.hairline,
);

ThemeData _build() {
  final textTheme = AppTypography.textTheme();

  final surfaceShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.surface),
    side: const BorderSide(
      color: AppColors.outline,
      width: AppStroke.hairline,
    ),
  );

  OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    extensions: const [
      AppRadii(
        surface: AppRadius.surface,
        control: AppRadius.control,
        small: AppRadius.small,
      ),
    ],
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    textTheme: textTheme,
    dividerColor: AppColors.hairline,
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: AppStroke.hairline,
      space: AppStroke.hairline,
    ),
    splashFactory: InkSparkle.splashFactory,

    // Hairline border, no shadow. Picking one and applying it everywhere is
    // what stops a page looking assembled from two different kits.
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: surfaceShape,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineMedium,
    ),

    // Buttons are pills. Black fill for the primary action, white with a black
    // hairline for everything else.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.subtleFill,
        disabledForegroundColor: AppColors.disabled,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        minimumSize: const Size(0, 52),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.disabled,
        side: const BorderSide(
          color: AppColors.ink,
          width: AppStroke.hairline,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        minimumSize: const Size(0, 52),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        disabledForegroundColor: AppColors.disabled,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minimumSize: const Size(0, 48),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: inputBorder(AppColors.outline),
      enabledBorder: inputBorder(AppColors.outline),
      // Focus is carried by weight rather than colour: the resting edge is
      // already ink, so there is nowhere darker to go.
      focusedBorder: inputBorder(AppColors.ink, width: 2),
      errorBorder: inputBorder(AppColors.error),
      focusedErrorBorder: inputBorder(AppColors.error, width: 2),
      // A disabled field keeps the pale edge — it is the one state that should
      // recede rather than assert a boundary.
      disabledBorder: inputBorder(AppColors.hairline),
      labelStyle: const TextStyle(color: AppColors.inkSecondary),
      floatingLabelStyle: const TextStyle(color: AppColors.ink),
      hintStyle: const TextStyle(color: AppColors.disabled),
      helperStyle: const TextStyle(color: AppColors.inkSecondary),
      errorStyle: const TextStyle(color: AppColors.error),
    ),

    // Selected chips invert to ink; unselected stay white with a hairline.
    //
    // The label colours are plain [TextStyle]s, not a `WidgetStateTextStyle`.
    // `RawChip` reads `labelStyle.color` off the style *before* resolving it
    // against the widget states, so a state-dependent style hands it null and
    // the label ends up with no colour at all — which on this palette is an
    // empty white pill rather than a visibly wrong one. `secondaryLabelStyle`
    // is the hook Material gives for the selected case.
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.ink,
      secondarySelectedColor: AppColors.ink,
      checkmarkColor: AppColors.surface,
      disabledColor: AppColors.subtleFill,
      labelStyle: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        color: AppColors.surface,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? AppColors.hairline
              : AppColors.outline,
          width: AppStroke.hairline,
        ),
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.surface
              : AppColors.ink,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.outline, width: AppStroke.hairline),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
    ),

    // A black disc with a white glyph, matching the primary button and the
    // nav bar it sits above. Left unthemed it took Material 3's defaults — a
    // pale rounded square — which was the only non-monochrome-looking control
    // on the dashboard.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.surface,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: CircleBorder(),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
      linearTrackColor: AppColors.subtleFill,
      circularTrackColor: AppColors.subtleFill,
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.ink,
      inactiveTrackColor: AppColors.subtleFill,
      thumbColor: AppColors.ink,
      overlayColor: Color(0x14000000),
      valueIndicatorColor: AppColors.ink,
      valueIndicatorTextStyle: TextStyle(color: AppColors.surface),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.inkSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.ink
            : AppColors.subtleFill,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.outline),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.surface),
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.surface,
      ),
      actionTextColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.ink,
      textColor: AppColors.ink,
    ),

    iconTheme: const IconThemeData(color: AppColors.ink, size: 22),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      textStyle: const TextStyle(
        color: AppColors.surface,
        fontSize: AppTypography.captionSize,
      ),
    ),
  );
}
