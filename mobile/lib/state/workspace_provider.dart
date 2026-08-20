import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/json_utils.dart';
import '../models/workspace_widget.dart';
import '../services/image_store.dart';
import '../services/prefs.dart';

/// The user's arrangement of workspace widgets.
class WorkspaceProvider extends ChangeNotifier {
  WorkspaceProvider(this._prefs);

  final Prefs _prefs;

  List<WorkspaceWidget> widgets = [];
  bool loaded = false;

  /// Bumped on every mutation — `select` on this, not on [widgets].
  int revision = 0;

  Future<void> load() async {
    final raw = await _prefs.getJsonList(PrefsKeys.workspace);
    if (raw != null) widgets = decodeList(raw, WorkspaceWidget.fromJson);
    loaded = true;
    notifyListeners();
  }

  void add(WorkspaceWidgetType type) {
    widgets.add(
      WorkspaceWidget(
        id: '${type.name}-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
      ),
    );
    _persist();
  }

  Future<void> remove(String id) async {
    final index = widgets.indexWhere((w) => w.id == id);
    if (index < 0) return;
    final removed = widgets.removeAt(index);
    // Drop the backing file too, or removed images leak storage silently.
    await ImageStore.delete(removed.mediaPath);
    _persist();
  }

  void cycleSize(String id) {
    final index = widgets.indexWhere((w) => w.id == id);
    if (index < 0) return;
    widgets[index] = widgets[index].copyWith(size: widgets[index].size.next);
    _persist();
  }

  void setMedia(String id, String fileName) {
    final index = widgets.indexWhere((w) => w.id == id);
    if (index < 0) return;
    widgets[index] = widgets[index].copyWith(mediaPath: fileName);
    _persist();
  }

  /// Moves a widget to a new position.
  ///
  /// Wired to `onReorderItem`, which already accounts for the dragged item
  /// being removed — so [newIndex] is used as-is. The older `onReorder`
  /// callback required subtracting one when moving downward.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= widgets.length) return;
    final moved = widgets.removeAt(oldIndex);
    widgets.insert(newIndex.clamp(0, widgets.length), moved);
    _persist();
  }

  /// Replaces the whole layout in one write. Used by the dev seeder.
  void replaceAll(List<WorkspaceWidget> next) {
    widgets = [...next];
    _persist();
  }

  Future<void> clear() async {
    for (final w in widgets) {
      await ImageStore.delete(w.mediaPath);
    }
    widgets = [];
    _persist();
  }

  // ------------------------------------------------------------ persistence

  Timer? _writeTimer;
  bool _writePending = false;

  static const _writeDebounce = Duration(milliseconds: 500);

  void _persist() {
    revision++;
    notifyListeners();
    _writePending = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, flush);
  }

  Future<void> flush() async {
    if (!_writePending) return;
    _writeTimer?.cancel();
    _writePending = false;
    try {
      await _prefs.setJsonList(
        PrefsKeys.workspace,
        widgets.map((w) => w.toJson()).toList(),
      );
    } catch (error) {
      debugPrint('Workspace write failed: $error');
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
