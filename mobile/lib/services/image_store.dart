import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../dev/log.dart';

/// Stores images picked for the workspace media widget.
///
/// Only the filename is persisted, never the bytes. Two reasons: encoding a
/// multi-megabyte image into the layout JSON would stall the UI thread on every
/// reorder, and the absolute documents path can change between app updates, so
/// storing it would eventually produce broken images.
class ImageStore {
  static const _folder = 'widget_media';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_folder');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Resolves a stored filename to an absolute path for the current install.
  static Future<String?> resolve(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    final dir = await _dir();
    final file = File('${dir.path}/$fileName');
    return file.existsSync() ? file.path : null;
  }

  /// Prompts for an image and copies it into app storage.
  ///
  /// Downscaled on pick — a full-resolution phone photo is far more than a
  /// dashboard card needs, and this keeps storage and decode cost sane.
  static Future<String?> pickAndStore(String widgetId) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final dir = await _dir();
      // A unique name per pick, not a fixed '<widgetId>.jpg'. Reusing the name
      // meant the stored path never changed, so the widget saw no update — and
      // Flutter's ImageCache is keyed on path, so the previous bitmap kept
      // rendering until the app restarted.
      final fileName = '$widgetId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest = File('${dir.path}/$fileName');
      await dest.writeAsBytes(await picked.readAsBytes());

      // Remove any earlier image for this widget so replacements don't pile up.
      for (final entity in dir.listSync()) {
        if (entity is File &&
            entity.path.split(RegExp(r'[/\\]')).last.startsWith('$widgetId-') &&
            entity.path != dest.path) {
          try {
            entity.deleteSync();
          } catch (_) {
            // A locked or already-removed file is not worth failing the pick.
          }
        }
      }

      return fileName;
    } catch (error) {
      logError('Image pick', error);
      return null;
    }
  }

  /// Deletes a stored image. Call when its widget is removed, or the files
  /// accumulate invisibly.
  static Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      final dir = await _dir();
      final file = File('${dir.path}/$fileName');
      if (file.existsSync()) await file.delete();
    } catch (error) {
      logError('Image delete', error);
    }
  }
}
