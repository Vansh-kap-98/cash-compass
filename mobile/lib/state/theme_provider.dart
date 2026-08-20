import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app/theme/app_tokens.dart';
import '../services/prefs.dart';

/// Font packs offered in Settings, ported from `SettingsStudio.tsx`.
enum FontPack {
  defaultPack('default', 'Outfit', 'Inter'),
  editorial('editorial', 'Playfair Display', 'Newsreader'),
  mono('mono', 'Geist Mono', 'JetBrains Mono');

  const FontPack(this.id, this.headingFont, this.bodyFont);

  final String id;
  final String headingFont;
  final String bodyFont;

  static FontPack fromId(String? id) {
    for (final pack in FontPack.values) {
      if (pack.id == id) return pack;
    }
    return FontPack.defaultPack;
  }
}

/// Holds the active theme and the typography preferences.
///
/// Port of `ThemeContext.tsx` plus the font controls from `SettingsStudio.tsx`.
/// On the web these were two separate stores (`dashboard-theme` and
/// `cash-compass-ui-settings-v1`); both are kept here since they all feed the
/// single [buildTheme] call.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs);

  final Prefs _prefs;

  AppTokens tokens = appThemes[defaultThemeName]!;
  FontPack fontPack = FontPack.defaultPack;

  /// Text scale as a percentage, 85-120, matching the Settings slider.
  double fontScalePercent = 100;

  bool loaded = false;

  /// Multiplier applied to the text theme.
  double get fontSizeFactor => fontScalePercent / 100;

  String get themeName => tokens.name;

  Future<void> load() async {
    tokens = resolveTheme(await _prefs.getString(PrefsKeys.theme));

    final ui = await _prefs.getJson(PrefsKeys.uiSettings);
    if (ui != null) {
      fontPack = FontPack.fromId(ui['fontPack'] as String?);
      final scale = ui['fontScale'];
      if (scale is num) {
        fontScalePercent = scale.toDouble().clamp(85, 120);
      }
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(String name) async {
    final next = resolveTheme(name);
    if (next.name == tokens.name) return;
    tokens = next;
    notifyListeners();
    await _prefs.setString(PrefsKeys.theme, next.name);
  }

  Future<void> setFontPack(FontPack pack) async {
    if (pack == fontPack) return;
    fontPack = pack;
    notifyListeners();
    await _persistUiSettings();
  }

  /// Dragging the Settings slider fires this on every tick. Repainting per tick
  /// is wanted — writing to disk per tick is not — so the write is debounced.
  Future<void> setFontScale(double percent) async {
    final clamped = percent.clamp(85, 120).toDouble();
    if (clamped == fontScalePercent) return;
    fontScalePercent = clamped;
    notifyListeners();
    _scheduleWrite();
  }

  Timer? _writeTimer;
  bool _writePending = false;

  static const _writeDebounce = Duration(milliseconds: 500);

  void _scheduleWrite() {
    _writePending = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, flush);
  }

  /// Writes immediately if anything is pending. Called on app pause.
  Future<void> flush() async {
    if (!_writePending) return;
    _writeTimer?.cancel();
    _writePending = false;
    try {
      await _persistUiSettings();
    } catch (error) {
      debugPrint('UI settings write failed: $error');
      _writePending = true;
    }
  }

  Future<void> _persistUiSettings() => _prefs.setJson(PrefsKeys.uiSettings, {
        'fontPack': fontPack.id,
        'fontScale': fontScalePercent,
      });

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
