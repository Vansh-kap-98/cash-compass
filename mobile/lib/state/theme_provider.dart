import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dev/log.dart';
import '../services/prefs.dart';

/// Display preferences.
///
/// This used to hold the active theme and a choice of three font packs, on top
/// of the text scale. Both selections are gone: there is one palette and one
/// family now, established in `lib/app/theme/`.
///
/// The text scale stays. It is an accessibility control, not a styling choice —
/// removing it along with the "pick your vibe" machinery would have taken a
/// real affordance out with the decoration.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs);

  final Prefs _prefs;

  /// Text scale as a percentage, 85-120, matching the Settings slider.
  double fontScalePercent = 100;

  bool loaded = false;

  /// Multiplier applied to the text theme.
  double get fontSizeFactor => fontScalePercent / 100;

  Future<void> load() async {
    // Reads the same blob the old build wrote. A stored `fontPack` is ignored
    // rather than migrated — there is nowhere for it to go — but leaving the
    // key in place means an upgrade does not have to rewrite the record just
    // to drop a field.
    final ui = await _prefs.getJson(PrefsKeys.uiSettings);
    if (ui != null) {
      final scale = ui['fontScale'];
      if (scale is num) {
        fontScalePercent = scale.toDouble().clamp(85, 120);
      }
    }

    loaded = true;
    notifyListeners();
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
      logError('UI settings write', error);
      _writePending = true;
    }
  }

  Future<void> _persistUiSettings() =>
      _prefs.setJson(PrefsKeys.uiSettings, {'fontScale': fontScalePercent});

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
