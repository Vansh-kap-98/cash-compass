import 'package:cash_compass/app/theme/app_theme.dart';
import 'package:cash_compass/app/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Guards the typography, including two bugs this app has already shipped once.
///
/// 1. Selecting the Mono font pack blanked the screen. `google_fonts` throws on
///    an unknown family, and that throw happened while building `ThemeData` —
///    which `MaterialApp` reads on every build — so the whole widget tree
///    failed. The font packs are gone, but the failure mode is a property of
///    `google_fonts`, not of the packs, so the guard stays.
///
/// 2. The text-size slider did nothing. Sizes were applied with
///    `TextTheme.apply(fontSizeFactor:)`, but Google Fonts styles carry a null
///    `fontSize`, and multiplying null yields null. Scaling now happens through
///    `MediaQuery.textScaler` at paint time instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Runtime fetching is deliberately left ON, matching every other test file.
  //
  // Turning it off used to be safe here because nothing in this file built a
  // real theme. It no longer is: with fetching disabled, `google_fonts` throws
  // *asynchronously* for a catalogued family whose file is not bundled, and an
  // async throw escapes the synchronous try/catch in `AppTypography._safe`. So
  // disabling it does not make failures honest any more — it manufactures one.
  //
  // With it on, the fetch simply fails offline and the family falls back,
  // which is the same path a user on a plane takes.

  group('the family', () {
    test('exists in the google_fonts catalogue', () {
      // Checked against the catalogue rather than by building a theme:
      // building one kicks off an async download that cannot succeed here.
      expect(
        GoogleFonts.asMap().keys,
        contains(AppTypography.family),
        reason: '"${AppTypography.family}" is not in google_fonts. Asking for '
            'it throws, and that throw happens while building ThemeData — '
            'which blanks the whole screen. This is exactly how "Geist Mono" '
            'broke the old Mono pack.',
      );
    });

    test('is not one of the faces that lack Cyrillic', () {
      // The app ships in Russian. A family without Cyrillic does not fail
      // loudly — it silently renders every Russian string in a system
      // fallback, which is what the previous heading font (Outfit) was doing.
      //
      // A denylist rather than an allowlist because the real requirement is
      // "has Cyrillic", which cannot be read offline; this at least catches
      // the tempting swaps. Verify coverage before changing the family:
      //   curl -A "<a browser UA>" \
      //     "https://fonts.googleapis.com/css2?family=<Name>:wght@400" \
      //     | grep U+0301
      const noCyrillic = {'Outfit', 'Poppins', 'DM Sans', 'Space Grotesk'};

      expect(
        noCyrillic,
        isNot(contains(AppTypography.family)),
        reason: '${AppTypography.family} has no Cyrillic glyphs, so the '
            'Russian build would fall back to a system face everywhere',
      );
    });

    testWidgets('an unknown family degrades instead of blanking the screen',
        (tester) async {
      // Simulates the original bug: a family that is not in the catalogue.
      // The app must still render.
      final theme = ThemeData(
        textTheme: AppTypography.textTheme(
          fontFamily: 'Definitely Not A Real Font',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Text('still here')),
        ),
      );

      expect(
        find.text('still here'),
        findsOneWidget,
        reason: 'a missing font is decoration failing, not the app failing',
      );
    });
  });

  group('the scale', () {
    test('defines a descending display / header / body / caption ramp', () {
      // Four named steps, each smaller than the last. A scale that is not
      // monotonic is how a "caption" ends up larger than the body around it.
      expect(
        AppTypography.displaySize,
        greaterThan(AppTypography.headerSize),
      );
      expect(AppTypography.headerSize, greaterThan(AppTypography.bodySize));
      expect(AppTypography.bodySize, greaterThan(AppTypography.captionSize));
    });

    test('every style carries an explicit size', () {
      // The old theme left sizes to Material's defaults, which is what made
      // the scale impossible to reason about in one place.
      //
      // Reads `scale()` rather than `textTheme()` on purpose: the latter goes
      // through google_fonts, which starts a fetch that outlives a plain test.
      final t = AppTypography.scale();
      final styles = <String, TextStyle?>{
        'displayLarge': t.displayLarge,
        'headlineSmall': t.headlineSmall,
        'titleMedium': t.titleMedium,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
      };

      styles.forEach((name, style) {
        expect(style?.fontSize, isNotNull, reason: '$name has no size');
      });
    });

    testWidgets('the family survives being merged with the scale',
        (tester) async {
      // Regression guard. Layering the scale with `copyWith` instead of
      // `merge` replaces each slot outright and drops the family with it —
      // the app then renders in the platform default and still looks
      // plausible, which is exactly why this needs a test rather than an eye.
      late TextTheme applied;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Builder(
            builder: (context) {
              applied = Theme.of(context).textTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      for (final entry in {
        'displayLarge': applied.displayLarge,
        'titleMedium': applied.titleMedium,
        'bodyMedium': applied.bodyMedium,
        'bodySmall': applied.bodySmall,
      }.entries) {
        expect(
          entry.value?.fontFamily,
          contains(AppTypography.family),
          reason: '${entry.key} lost the font family',
        );
        expect(entry.value?.fontSize, isNotNull, reason: entry.key);
      }
    });
  });

  group('text size', () {
    /// Renders one line of body text and reports its laid-out height.
    Future<double> renderedHeight(WidgetTester tester, double scale) async {
      final stores = TestStores.empty();
      await stores.theme.setFontScale(scale);

      await tester.pumpWidget(
        wrapForTest(
          const Text('Sample', key: Key('probe')),
          stores: stores,
          textScale: stores.theme.fontSizeFactor,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      final size = tester.getSize(find.byKey(const Key('probe')));
      await tester.pumpWidget(const SizedBox.shrink());
      return size.height;
    }

    testWidgets('120% renders visibly larger text than 85%', (tester) async {
      final small = await renderedHeight(tester, 85);
      final large = await renderedHeight(tester, 120);

      expect(
        large,
        greaterThan(small),
        reason: 'the slider previously moved and nothing on screen changed',
      );
    });

    test('the scale factor tracks the slider', () async {
      final theme = TestStores.empty().theme;

      await theme.setFontScale(120);
      expect(theme.fontSizeFactor, closeTo(1.2, 0.001));

      await theme.setFontScale(85);
      expect(theme.fontSizeFactor, closeTo(0.85, 0.001));
    });

    test('out-of-range values are clamped, not rejected', () async {
      final theme = TestStores.empty().theme;

      await theme.setFontScale(999);
      expect(theme.fontScalePercent, 120);

      await theme.setFontScale(0);
      expect(theme.fontScalePercent, 85);
    });
  });

  group('the theme', () {
    test('is a single memoised instance', () {
      // There is nothing to vary any more, so rebuilding MaterialApp must not
      // rebuild 15 TextStyles.
      expect(identical(buildTheme(), buildTheme()), isTrue);
    });
  });
}
