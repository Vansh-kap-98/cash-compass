import 'package:cash_compass/app/theme/app_colors.dart';
import 'package:cash_compass/app/theme/app_spacing.dart';
import 'package:cash_compass/app/theme/app_theme.dart';
import 'package:cash_compass/app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the theme against the failure this palette makes easy: a control
/// whose label resolves to the same colour as the surface behind it.
///
/// With five hues there was always *some* contrast by accident. With black,
/// white and three greys, getting a state wrong renders the label invisible
/// rather than merely ugly — and an invisible label still passes an overflow
/// test, a golden diff at low resolution, and a quick look on a bright monitor.
void main() {
  /// The colour actually painted for [label] under [child].
  ///
  /// Reads the span's own colour, falling back to the inherited
  /// [DefaultTextStyle]: `Text` leaves the span colour null and inherits it
  /// whenever the ancestor already supplies one, which is what chips do. Only
  /// checking the span would report null for every chip and prove nothing.
  Future<Color?> paintedTextColour(
    WidgetTester tester,
    Widget child, {
    required String label,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.text(label);
    expect(finder, findsOneWidget, reason: '"$label" was never rendered');

    final span = tester.widget<Text>(finder).style?.color;
    if (span != null) return span;
    return DefaultTextStyle.of(tester.element(finder)).style.color;
  }

  group('chips', () {
    testWidgets('an ActionChip label is ink, not the surface it sits on',
        (tester) async {
      // The currency toggle on the balance card is an ActionChip, which is
      // never "selected". If the theme resolves its label as though it were,
      // the chip renders as an empty white pill.
      final colour = await paintedTextColour(
        tester,
        ActionChip(label: const Text('INR'), onPressed: () {}),
        label: 'INR',
      );

      expect(colour, isNot(AppColors.surface));
      expect(colour, AppColors.ink);
    });

    testWidgets('an unselected ChoiceChip is ink on white', (tester) async {
      final colour = await paintedTextColour(
        tester,
        ChoiceChip(
          label: const Text('1 Month'),
          selected: false,
          onSelected: (_) {},
        ),
        label: '1 Month',
      );

      expect(colour, AppColors.ink);
    });

    testWidgets('a selected ChoiceChip inverts to white on ink',
        (tester) async {
      final colour = await paintedTextColour(
        tester,
        ChoiceChip(
          label: const Text('1 Month'),
          selected: true,
          onSelected: (_) {},
        ),
        label: '1 Month',
      );

      expect(colour, AppColors.surface);
    });

    testWidgets('an unselected FilterChip is ink on white', (tester) async {
      final colour = await paintedTextColour(
        tester,
        FilterChip(
          label: const Text('Impulse'),
          selected: false,
          onSelected: (_) {},
        ),
        label: 'Impulse',
      );

      expect(colour, AppColors.ink);
    });

    testWidgets('a selected FilterChip needs its label set at the call site',
        (tester) async {
      // Documents a Material quirk rather than asserting the app is wrong:
      // FilterChip ignores `secondaryLabelStyle`, so the theme alone leaves a
      // selected chip ink-on-ink. Every FilterChip in the app therefore passes
      // its own `labelStyle` — see `add_entry_sheet.dart`. If a future Flutter
      // fixes this, that override can go and this test will say so by failing.
      final themedOnly = await paintedTextColour(
        tester,
        FilterChip(
          label: const Text('Impulse'),
          selected: true,
          onSelected: (_) {},
        ),
        label: 'Impulse',
      );
      expect(
        themedOnly,
        AppColors.ink,
        reason: 'if this is now white, drop the per-site labelStyle overrides',
      );

      // With the override the app actually uses, it is legible.
      final withOverride = await paintedTextColour(
        tester,
        FilterChip(
          label: const Text('Impulse'),
          selected: true,
          labelStyle: const TextStyle(color: AppColors.surface),
          onSelected: (_) {},
        ),
        label: 'Impulse',
      );
      expect(withOverride, AppColors.surface);
    });

    testWidgets('an InputChip label is ink', (tester) async {
      final colour = await paintedTextColour(
        tester,
        InputChip(label: const Text('Social'), onPressed: () {}),
        label: 'Social',
      );

      expect(colour, AppColors.ink);
    });
  });

  group('the ink card', () {
    testWidgets('re-themes its contents to read on black', (tester) async {
      // Everything placed on an ink surface must invert. This is the check
      // that catches the trap in AppCardTone.ink's doc: a style resolved above
      // the card stays black, and black type on a black panel lays out
      // perfectly while being invisible.
      late TextTheme inside;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: AppCard.ink(
              child: Builder(
                builder: (context) {
                  inside = Theme.of(context).textTheme;
                  return const Text('Total balance');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final entry in {
        'titleMedium': inside.titleMedium,
        'bodyMedium': inside.bodyMedium,
        'headlineSmall': inside.headlineSmall,
      }.entries) {
        expect(
          entry.value?.color,
          AppColors.surface,
          reason: '${entry.key} would be invisible on the ink card',
        );
      }

      // The muted step inverts too, rather than staying the dark grey that
      // reads as almost-black on black.
      expect(inside.bodySmall?.color, isNot(AppColors.inkSecondary));
      expect(inside.bodySmall?.color?.a, greaterThan(0.5));
    });

    testWidgets('a plain card leaves the theme alone', (tester) async {
      late TextTheme inside;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: AppCard(
              child: Builder(
                builder: (context) {
                  inside = Theme.of(context).textTheme;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(inside.titleMedium?.color, AppColors.ink);
    });
  });

  group('container edges', () {
    // Every container draws its own boundary in ink. The rule that keeps this
    // from turning a list into a table: edges are `outline`, and separators
    // *inside* a container stay on the pale `hairline`.
    testWidgets('a card is outlined in ink, not hairline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: AppCard(child: Text('Card'))),
        ),
      );

      // `first` is the card's own Material — an ancestor finder walks outward,
      // so `last` would be the Scaffold's, which carries no shape at all.
      final material = tester.widget<Material>(
        find
            .descendant(
                of: find.byType(AppCard), matching: find.byType(Material))
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;

      expect(shape.side.color, AppColors.outline);
      expect(shape.side.width, AppStroke.hairline);
    });

    test('an input rests on the outline and thickens on focus', () {
      final input = buildTheme().inputDecorationTheme;

      expect(
        (input.enabledBorder! as OutlineInputBorder).borderSide.color,
        AppColors.outline,
      );
      // Focus cannot go darker than the resting edge, so it goes heavier.
      final focused = (input.focusedBorder! as OutlineInputBorder).borderSide;
      expect(focused.color, AppColors.ink);
      expect(
        focused.width,
        greaterThan(
          (input.enabledBorder! as OutlineInputBorder).borderSide.width,
        ),
      );
    });

    test('a disabled input keeps the pale edge', () {
      // The one state that should recede rather than assert a boundary.
      final input = buildTheme().inputDecorationTheme;
      expect(
        (input.disabledBorder! as OutlineInputBorder).borderSide.color,
        AppColors.hairline,
      );
    });

    test('row dividers stay pale', () {
      // If these matched the container edge, a five-row card would show six
      // competing black lines.
      expect(buildTheme().dividerTheme.color, AppColors.hairline);
      expect(AppColors.hairline, isNot(AppColors.outline));
    });
  });

  group('buttons', () {
    testWidgets('a filled button is white on ink', (tester) async {
      final colour = await paintedTextColour(
        tester,
        FilledButton(onPressed: () {}, child: const Text('Save')),
        label: 'Save',
      );

      expect(colour, AppColors.surface);
    });

    testWidgets('an outlined button is ink on white', (tester) async {
      final colour = await paintedTextColour(
        tester,
        OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
        label: 'Cancel',
      );

      expect(colour, AppColors.ink);
    });
  });
}
