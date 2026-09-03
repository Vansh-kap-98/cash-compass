import 'dart:convert';
import 'dart:io';

import 'package:cash_compass/l10n/l10n.dart';
import 'package:cash_compass/l10n/presenters.dart';
import 'package:cash_compass/logic/budget_math.dart';
import 'package:cash_compass/logic/insights.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/services/prefs.dart';
import 'package:cash_compass/state/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget/harness.dart';

/// Covers the language option itself: the stored preference, the catalogue's
/// completeness, and that a real widget actually re-reads in Russian.
void main() {
  group('LocaleProvider', () {
    test('defaults to following the device', () async {
      final provider = LocaleProvider(FakePrefs());
      await provider.load();

      expect(provider.language, AppLanguage.system);
      expect(
        provider.locale,
        isNull,
        reason: 'a null locale is what hands the choice back to Flutter',
      );
    });

    test('persists a choice and reloads it', () async {
      final prefs = FakePrefs();

      final first = LocaleProvider(prefs);
      await first.load();
      await first.setLanguage(AppLanguage.russian);
      expect(first.locale, const Locale('ru'));

      // A fresh provider over the same storage, as on the next app launch.
      final second = LocaleProvider(prefs);
      await second.load();
      expect(second.language, AppLanguage.russian);
    });

    test('an unknown stored id falls back to the device language', () async {
      final prefs = FakePrefs();
      // As if a later build had offered a language this one does not.
      await prefs.setString(PrefsKeys.language, 'kl');

      final provider = LocaleProvider(prefs);
      await provider.load();
      expect(provider.language, AppLanguage.system);
    });
  });

  group('catalogue', () {
    // Reading the ARBs directly rather than the generated class: a key missing
    // from app_ru.arb still generates, silently falling back to English, and
    // that is exactly the failure this has to catch.
    Map<String, dynamic> load(String name) => jsonDecode(
          File('lib/l10n/$name').readAsStringSync(),
        ) as Map<String, dynamic>;

    bool isMessage(String key) => !key.startsWith('@');

    test('every English message has a Russian translation', () {
      final en = load('app_en.arb').keys.where(isMessage).toSet();
      final ru = load('app_ru.arb').keys.where(isMessage).toSet();

      expect(
        en.difference(ru),
        isEmpty,
        reason: 'these keys would ship in English with the app set to Russian',
      );
      expect(
        ru.difference(en),
        isEmpty,
        reason: 'these Russian keys are orphaned — nothing renders them',
      );
    });

    test('Russian plurals declare the few/many categories', () {
      final ru = load('app_ru.arb');

      // Russian needs one/few/many where English needs only one/other. A
      // plural that declares just `other` is the shape you get from copying
      // the English message across, and it reads as broken at 2 and at 5.
      final incomplete = <String>[];
      for (final entry in ru.entries) {
        if (!isMessage(entry.key)) continue;
        final value = entry.value;
        if (value is! String || !value.contains(', plural,')) continue;
        if (!value.contains('few{') || !value.contains('many{')) {
          incomplete.add(entry.key);
        }
      }

      expect(incomplete, isEmpty);
    });
  });

  group('presenters', () {
    late AppLocalizations en;
    late AppLocalizations ru;

    setUp(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      ru = await AppLocalizations.delegate.load(const Locale('ru'));
    });

    test('a stored category renders in the active language', () {
      // The stored value never changes — only the label does.
      expect(categoryLabel(en, 'Groceries'), 'Groceries');
      expect(categoryLabel(ru, 'Groceries'), 'Продукты');
    });

    test('an unknown category falls back to the stored value', () {
      expect(categoryLabel(ru, 'Crypto'), 'Crypto');
    });

    test('the spending pattern declines its count in Russian', () {
      String message(int count) => behaviorInsightMessage(
            ru,
            BehaviorInsight(
              weekday: DateTime.friday,
              tag: ReasonTag.impulse,
              isNight: true,
              count: count,
            ),
          );

      // 1 / 2 / 5 land in one / few / many respectively.
      expect(message(1), contains('по пятницам'));
      expect(message(2), contains('по пятницам'));
      expect(message(5), contains('по пятницам'));
    });

    test('a suggestion formats money in the caller currency, not USD', () {
      final body = suggestionBody(
        en,
        const WatchCategorySuggestion(category: 'Food', savingUsd: 12.5),
        (usd) => '₹${(usd * 83.5).toStringAsFixed(2)}',
      );

      expect(body, contains('₹1043.75'));
      expect(
        body,
        isNot(contains('USD')),
        reason: 'the old wording hardcoded a USD figure whatever the currency',
      );
    });

    test('daily tips resolve in both languages', () {
      for (final tip in DailyTip.values) {
        expect(dailyTipMessage(en, tip), isNotEmpty);
        expect(dailyTipMessage(ru, tip), isNotEmpty);
        expect(
          dailyTipMessage(ru, tip),
          isNot(dailyTipMessage(en, tip)),
          reason: '$tip was never translated',
        );
      }
    });

    test('each language names itself, so the picker is always escapable', () {
      // Someone stranded in a language they cannot read has to recognise their
      // own in this list, whichever language the app is currently speaking.
      expect(languageLabel(ru, AppLanguage.english), 'English');
      expect(languageLabel(en, AppLanguage.russian), 'Русский');
    });
  });

  group('widgets', () {
    testWidgets('the same screen renders in the chosen language',
        (tester) async {
      Widget app(Locale locale) => MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: Text(context.l10n.dashTotalBalance),
              ),
            ),
          );

      await tester.pumpWidget(app(const Locale('en')));
      expect(find.text('Total balance'), findsOneWidget);

      await tester.pumpWidget(app(const Locale('ru')));
      await tester.pump();
      expect(find.text('Общий баланс'), findsOneWidget);
      expect(find.text('Total balance'), findsNothing);
    });
  });
}
