import 'dart:async';

import '../logic/receipt_parser.dart';

/// One receipt as it moves through the batch pipeline.
class BatchEntry {
  BatchEntry({
    required this.id,
    required this.imagePath,
    this.receipt,
    this.capturedAt,
    this.status = BatchStatus.pending,
    this.duplicateOf,
    this.skipped = false,
  });

  /// Stable across retries, so the review screen can keep its row identity.
  final String id;
  final String imagePath;

  /// Null until processing finishes, and on failure.
  final ParsedReceipt? receipt;

  /// When the photo was taken, from EXIF. Null when the image carried none —
  /// a screenshot or a download rather than a camera capture.
  final DateTime? capturedAt;

  final BatchStatus status;

  /// Id of an earlier entry this looks like a repeat of.
  final String? duplicateOf;

  /// Excluded from the save by the user.
  final bool skipped;

  bool get isDuplicate => duplicateOf != null;

  /// True when the date shown is a fallback rather than the real capture time,
  /// which the review screen surfaces rather than hiding.
  bool get dateIsFallback => capturedAt == null;

  BatchEntry copyWith({
    ParsedReceipt? receipt,
    DateTime? capturedAt,
    BatchStatus? status,
    String? duplicateOf,
    bool? skipped,
    bool clearDuplicate = false,
  }) =>
      BatchEntry(
        id: id,
        imagePath: imagePath,
        receipt: receipt ?? this.receipt,
        capturedAt: capturedAt ?? this.capturedAt,
        status: status ?? this.status,
        duplicateOf: clearDuplicate ? null : (duplicateOf ?? this.duplicateOf),
        skipped: skipped ?? this.skipped,
      );
}

enum BatchStatus { pending, processing, done, failed }

/// Runs receipt processing over a list of images with bounded concurrency.
///
/// Two things this deliberately is not:
///
/// **Not fully sequential.** Ten receipts one after another is a long wait on a
/// progress spinner.
///
/// **Not fully parallel.** Every concurrent job holds a decoded bitmap, and ten
/// full-resolution photos in memory at once is how a mid-range phone gets its
/// process killed.
///
/// Three at a time keeps the pipeline busy without stacking decoded images.
class ReceiptBatchQueue {
  ReceiptBatchQueue({
    required this.process,
    this.concurrency = 3,
  }) : assert(concurrency > 0);

  /// Processes one image. Injected so the queue itself stays testable without
  /// a camera, ML Kit, or the filesystem.
  final Future<BatchEntry> Function(BatchEntry entry) process;

  final int concurrency;

  /// Runs [entries], reporting the full list after each completion so a caller
  /// can render progress.
  ///
  /// Order of the result matches the order given, regardless of which jobs
  /// finish first — a review screen that reshuffles under the user as results
  /// land is unusable.
  Stream<List<BatchEntry>> run(List<BatchEntry> entries) {
    final controller = StreamController<List<BatchEntry>>();
    final results = List<BatchEntry>.from(entries);
    var next = 0;
    var active = 0;
    var completed = 0;

    void pump() {
      while (active < concurrency && next < entries.length) {
        final index = next++;
        active++;
        results[index] =
            results[index].copyWith(status: BatchStatus.processing);

        process(results[index]).then((done) {
          results[index] = done;
        }).catchError((Object _) {
          // A single unreadable image must not take down the batch.
          results[index] = results[index].copyWith(status: BatchStatus.failed);
        }).whenComplete(() {
          active--;
          completed++;
          controller.add(List<BatchEntry>.from(results));
          if (completed == entries.length) {
            controller.close();
          } else {
            pump();
          }
        });
      }
    }

    if (entries.isEmpty) {
      controller.close();
    } else {
      pump();
    }

    return controller.stream;
  }
}

/// Marks entries that look like repeats of an earlier one in the same batch.
///
/// Multi-select from a gallery is exactly where someone picks the same photo
/// twice, or picks both an original and a saved copy. Matching on merchant,
/// amount, and day catches that without flagging two genuine coffees bought on
/// the same day at different prices.
///
/// Flags rather than removes: the review screen offers a one-tap skip, because
/// a false positive that silently drops a real expense is far worse than an
/// extra row to dismiss.
List<BatchEntry> flagDuplicates(
  List<BatchEntry> entries, {
  bool Function(BatchEntry a, BatchEntry b)? matches,
}) {
  bool defaultMatch(BatchEntry a, BatchEntry b) {
    final ra = a.receipt;
    final rb = b.receipt;
    if (ra == null || rb == null) return false;
    if (ra.amount == null || rb.amount == null) return false;
    if ((ra.amount! - rb.amount!).abs() > 0.001) return false;

    final ma = ra.merchant?.toLowerCase().trim();
    final mb = rb.merchant?.toLowerCase().trim();
    if (ma == null || mb == null || ma != mb) return false;

    final da = a.capturedAt;
    final db = b.capturedAt;
    // No dates to compare means merchant and amount alone decide it.
    if (da == null || db == null) return true;
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  final test = matches ?? defaultMatch;
  final out = <BatchEntry>[];

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    String? duplicateOf;

    for (var j = 0; j < i; j++) {
      // Compare against the surviving earlier rows only, so three copies chain
      // to the first rather than flagging each other in a cycle.
      if (out[j].isDuplicate) continue;
      if (test(entry, out[j])) {
        duplicateOf = out[j].id;
        break;
      }
    }

    out.add(duplicateOf == null
        ? entry.copyWith(clearDuplicate: true)
        : entry.copyWith(duplicateOf: duplicateOf));
  }

  return out;
}
