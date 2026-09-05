import 'dart:io';

import 'package:cash_compass/app/widgets/goal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps colour out of a monochrome interface.
///
/// An emoji renders from a colour font whatever `TextStyle` is applied to it,
/// so one on a page cannot be toned down — only replaced. That makes it the
/// single easiest way for colour to creep back in, and the hardest to notice in
/// review, since the character is usually a couple of bytes at the end of a
/// string.
void main() {
  /// Codepoints that render in colour on Android. Deliberately excludes the
  /// typographic marks the copy legitimately uses — arrows, dashes, the minus
  /// sign — which share these Unicode blocks but are drawn by the text font.
  final pictograph = RegExp(
    '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]',
    unicode: true,
  );
  const typographic = {'→', '←', '−', '✓', '—', '–'};

  List<String> pictographsIn(String text) =>
      pictograph.allMatches(text).map((m) => m.group(0)!).where(
            (c) => !typographic.contains(c),
          ).toList();

  group('translations', () {
    // The catalogues are where an emoji hides best: it is display copy, it
    // survives translation, and it reaches the screen without passing through
    // any widget that could restyle it.
    for (final name in ['app_en.arb', 'app_ru.arb']) {
      test('$name carries no emoji', () {
        final file = File('lib/l10n/$name');
        expect(file.existsSync(), isTrue, reason: '$name is missing');

        final offenders = <String>[];
        for (final line in file.readAsLinesSync()) {
          final found = pictographsIn(line);
          if (found.isNotEmpty) offenders.add('${found.join()}  $line');
        }

        expect(
          offenders,
          isEmpty,
          reason: 'these strings would paint in colour:\n'
              '${offenders.join('\n')}',
        );
      });
    }
  });

  group('goal marks', () {
    // The one place an emoji is still stored: `goal.icon` is shared JSON and
    // the web app paints it as text, so the character has to survive a
    // round-trip. It is a lookup key here and is never rendered — these check
    // the lookup holds rather than that the character is gone.
    test('every offered mark resolves to a glyph', () {
      for (final key in goalIcons.keys) {
        expect(goalIcon(key), isA<IconData>(), reason: key);
      }
    });

    test('the default is one of the offered marks', () {
      expect(goalIcons.containsKey(defaultGoalIconKey), isTrue);
    });

    test('an unknown mark falls back rather than rendering the character', () {
      // A goal typed on the web, or saved by the old free-text field.
      expect(goalIcon('🦄'), goalIcons[defaultGoalIconKey]);
      expect(goalIcon(''), goalIcons[defaultGoalIconKey]);
      expect(goalIcon(null), goalIcons[defaultGoalIconKey]);
    });
  });
}
