import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../dev/log.dart';
import '../logic/receipt_parser.dart';
import '../logic/subscriptions.dart';
import '../models/transaction.dart';
// `isoDate` lives alongside the store that consumes it rather than in models/.
import '../state/finance_provider.dart';

/// Why a scan produced nothing, so the UI can say something specific rather
/// than a generic failure.
enum ScanFailure {
  /// The user backed out of the camera. Not an error — say nothing.
  cancelled,

  /// The camera could not be opened, usually because permission was refused.
  cameraUnavailable,

  /// A photo was taken but no text came back — a blurry shot, or a picture of
  /// something that is not a receipt.
  noTextFound,

  /// Text was recognised but no amount or merchant could be pulled out of it.
  nothingUseful,
}

/// The outcome of a scan: either a receipt, or a reason there isn't one.
sealed class ScanResult {
  const ScanResult();
}

class ScanSuccess extends ScanResult {
  const ScanSuccess(this.receipt);
  final ParsedReceipt receipt;
}

class ScanFailed extends ScanResult {
  const ScanFailed(this.reason);
  final ScanFailure reason;
}

/// Camera capture plus on-device OCR, feeding [parseReceiptLines].
///
/// Everything here runs on the phone. ML Kit's Latin text recogniser is bundled
/// into the APK, so no image and no recognised text ever leaves the device —
/// which is the only reason it is acceptable to point this at a document
/// containing someone's card digits and purchase history.
///
/// The parsing itself lives in `logic/receipt_parser.dart` and is pure. This
/// class is the IO shell around it: camera, ML Kit, and the filesystem.
abstract final class ReceiptScanner {
  static const _folder = 'receipts';

  /// Opens the camera, reads the photo, and returns what could be extracted.
  ///
  /// [history] is the existing transaction list, used only to decide whether
  /// this charge would look like a subscription. Pass the real list; the check
  /// is a cheap pass over it.
  static Future<ScanResult> scan({
    required List<FinanceTransaction> history,
    ImageSource source = ImageSource.camera,
  }) async {
    final XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: source,
        // Full sensor resolution is far more than OCR needs and makes ML Kit
        // noticeably slower. 1600px keeps small print legible.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
    } catch (error) {
      // A refused camera permission surfaces as a PlatformException here.
      logError('Receipt capture', error);
      return const ScanFailed(ScanFailure.cameraUnavailable);
    }

    if (shot == null) return const ScanFailed(ScanFailure.cancelled);

    final lines = await _recogniseLines(shot.path);
    if (lines.isEmpty) return const ScanFailed(ScanFailure.noTextFound);

    final storedPath = await _store(shot);
    final parsed = parseReceiptLines(lines, imagePath: storedPath);

    if (parsed.isEmpty) {
      // Nothing usable, so the stored image is only clutter.
      await _delete(storedPath);
      return const ScanFailed(ScanFailure.nothingUseful);
    }

    return ScanSuccess(_withSubscriptionHint(parsed, history));
  }

  // --------------------------------------------------------------------- OCR

  static Future<List<String>> _recogniseLines(String imagePath) async {
    final recogniser = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognised = await recogniser.processImage(
        InputImage.fromFilePath(imagePath),
      );

      // ML Kit returns blocks in detection order, not reading order, and the
      // parser depends on order absolutely: it takes the merchant from the top
      // five lines and searches for the total from the bottom up. Sorting by
      // vertical position restores the reading order the parser assumes.
      final lines = <({double top, String text})>[];
      for (final block in recognised.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          if (text.isEmpty) continue;
          lines.add((top: line.boundingBox.top, text: text));
        }
      }
      lines.sort((a, b) => a.top.compareTo(b.top));

      return [for (final line in lines) line.text];
    } catch (error) {
      logError('Receipt OCR', error);
      return const [];
    } finally {
      // Native resource — leaking it holds the recogniser open for the life of
      // the process.
      await recogniser.close();
    }
  }

  // ----------------------------------------------------------------- storage

  /// Copies the capture into app-private storage.
  ///
  /// `getApplicationDocumentsDirectory` is not world-readable, unlike anything
  /// under `/sdcard`. A receipt photo shows what someone bought, where, and
  /// often the last digits of their card, so it must not land anywhere another
  /// app can enumerate.
  static Future<String?> _store(XFile shot) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/$_folder');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final name = 'receipt-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest = File('${dir.path}/$name');
      await dest.writeAsBytes(await shot.readAsBytes());
      return dest.path;
    } catch (error) {
      // A failed copy must not lose the scan — the parsed fields are the
      // valuable part, the image is a nice-to-have.
      logError('Receipt image store', error);
      return null;
    }
  }

  static Future<void> _delete(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (error) {
      logError('Receipt image delete', error);
    }
  }

  // ------------------------------------------------------------ subscription

  /// Flags the receipt when this merchant and amount would read as recurring.
  ///
  /// Runs the real [wouldBeSubscription] over history-plus-candidate rather
  /// than a lookalike rule, so the warning cannot disagree with the Waste
  /// Auditor about what counts as a subscription.
  static ParsedReceipt _withSubscriptionHint(
    ParsedReceipt receipt,
    List<FinanceTransaction> history,
  ) {
    final merchant = receipt.merchant;
    final amount = receipt.amount;
    if (merchant == null || amount == null) return receipt;

    final looksRecurring = wouldBeSubscription(
      history: history,
      merchant: merchant,
      amount: amount,
      date: isoDate(DateTime.now()),
    );

    return looksRecurring
        ? receipt.copyWith(suggestsSubscription: true)
        : receipt;
  }
}
