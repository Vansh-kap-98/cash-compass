import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame-timing reporter for profile builds.
///
/// Android's `dumpsys gfxinfo` does not see Flutter frames — the engine renders
/// to its own surface — so this hooks Flutter's scheduler directly. It reports
/// how many frames exceeded the 60fps budget and where the time went: the UI
/// thread (Dart build + layout) or the raster thread (GPU).
///
/// Enabled only in profile mode. Debug builds are far slower than reality and
/// would produce misleading numbers; release builds should not pay for this.
class FrameReport {
  static const _budget = Duration(milliseconds: 16, microseconds: 600);

  static int _total = 0;
  static int _buildJank = 0;
  static int _rasterJank = 0;
  static int _worstBuildUs = 0;
  static int _worstRasterUs = 0;
  static int _sumBuildUs = 0;
  static int _sumRasterUs = 0;

  /// Starts collecting. Safe to call unconditionally — it no-ops outside
  /// profile mode.
  static void start() {
    if (!kProfileMode) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    debugPrint('FrameReport active');
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _total++;
      final build = t.buildDuration;
      final raster = t.rasterDuration;

      // Build and raster are attributed separately and deliberately.
      // `totalSpan` includes vsync queueing latency, so thresholding on it
      // flags nearly every frame and tells you nothing about whether the app
      // is at fault. Build time is our Dart code; raster time is the GPU.
      _sumBuildUs += build.inMicroseconds;
      _sumRasterUs += raster.inMicroseconds;

      if (build.inMicroseconds > _worstBuildUs) {
        _worstBuildUs = build.inMicroseconds;
      }
      if (raster.inMicroseconds > _worstRasterUs) {
        _worstRasterUs = raster.inMicroseconds;
      }

      if (build > _budget) {
        _buildJank++;
        debugPrint('SLOW BUILD ${build.inMilliseconds}ms — app code');
      }
      if (raster > _budget) _rasterJank++;
    }
  }

  /// Logs a summary. Read it with `adb logcat -d -s flutter:V`.
  static void report() {
    if (!kProfileMode) return;
    if (_total == 0) {
      debugPrint('FRAMES none recorded');
      return;
    }
    String ms(int us) => (us / 1000).toStringAsFixed(1);
    String pct(int n) => (n / _total * 100).toStringAsFixed(1);

    debugPrint(
      'FRAMES total=$_total\n'
      '  build  avg=${ms(_sumBuildUs ~/ _total)}ms '
      'worst=${ms(_worstBuildUs)}ms over-budget=$_buildJank (${pct(_buildJank)}%)\n'
      '  raster avg=${ms(_sumRasterUs ~/ _total)}ms '
      'worst=${ms(_worstRasterUs)}ms over-budget=$_rasterJank (${pct(_rasterJank)}%)',
    );
  }

  static void reset() {
    _total = _buildJank = _rasterJank = 0;
    _worstBuildUs = _worstRasterUs = _sumBuildUs = _sumRasterUs = 0;
  }
}
