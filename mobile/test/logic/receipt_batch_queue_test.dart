import 'dart:async';

import 'package:cash_compass/logic/receipt_batch_queue.dart';
import 'package:cash_compass/logic/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// The queue's contract: bounded concurrency, stable order, and one bad image
/// never taking down the batch.
void main() {
  BatchEntry entry(String id, {ParsedReceipt? receipt, DateTime? at}) =>
      BatchEntry(
        id: id,
        imagePath: '/tmp/$id.jpg',
        receipt: receipt,
        capturedAt: at,
      );

  ParsedReceipt parsed({double? amount = 10, String? merchant = 'Shop'}) =>
      ParsedReceipt(amount: amount, merchant: merchant);

  group('bounded concurrency', () {
    test('never exceeds the limit, and does not run one at a time', () async {
      var active = 0;
      var peak = 0;
      final gates = <Completer<void>>[];

      final queue = ReceiptBatchQueue(
        concurrency: 3,
        process: (e) async {
          active++;
          peak = active > peak ? active : peak;
          final gate = Completer<void>();
          gates.add(gate);
          await gate.future;
          active--;
          return e.copyWith(status: BatchStatus.done);
        },
      );

      final entries = [for (var i = 0; i < 9; i++) entry('e$i')];
      final done = queue.run(entries).drain<void>();

      // Let the first wave start.
      await Future<void>.delayed(Duration.zero);
      expect(peak, 3,
          reason: 'three should be in flight, not one and not nine');

      // Release everything.
      while (gates.length < entries.length) {
        for (final g in List.of(gates)) {
          if (!g.isCompleted) g.complete();
        }
        await Future<void>.delayed(Duration.zero);
      }
      for (final g in gates) {
        if (!g.isCompleted) g.complete();
      }
      await done;

      expect(
        peak,
        lessThanOrEqualTo(3),
        reason: 'exceeding the limit stacks decoded bitmaps and gets the '
            'process killed on a mid-range phone',
      );
    });

    test('result order matches input order, not completion order', () async {
      final queue = ReceiptBatchQueue(
        concurrency: 3,
        process: (e) async {
          // Reverse the natural finishing order.
          final index = int.parse(e.id.substring(1));
          await Future<void>.delayed(Duration(milliseconds: (5 - index) * 10));
          return e.copyWith(status: BatchStatus.done);
        },
      );

      final entries = [for (var i = 0; i < 5; i++) entry('e$i')];
      final snapshots = await queue.run(entries).toList();

      expect(
        snapshots.last.map((e) => e.id).toList(),
        ['e0', 'e1', 'e2', 'e3', 'e4'],
        reason: 'a review list that reshuffles as results land is unusable',
      );
    });
  });

  group('failure isolation', () {
    test('one throwing image does not stop the rest', () async {
      final queue = ReceiptBatchQueue(
        concurrency: 2,
        process: (e) async {
          if (e.id == 'e2') throw StateError('unreadable');
          return e.copyWith(
            receipt: parsed(),
            status: BatchStatus.done,
          );
        },
      );

      final entries = [for (var i = 0; i < 5; i++) entry('e$i')];
      final snapshots = await queue.run(entries).toList();
      final finalState = snapshots.last;

      expect(finalState, hasLength(5));
      expect(
        finalState.firstWhere((e) => e.id == 'e2').status,
        BatchStatus.failed,
      );
      expect(
        finalState.where((e) => e.status == BatchStatus.done),
        hasLength(4),
        reason: 'the other four must still be readable',
      );
    });

    test('an empty batch closes cleanly', () async {
      final queue = ReceiptBatchQueue(process: (e) async => e);
      expect(await queue.run([]).toList(), isEmpty);
    });
  });

  group('duplicate flagging', () {
    final day = DateTime(2026, 8, 21, 14);

    test('same merchant, amount, and day is flagged', () {
      final out = flagDuplicates([
        entry('a', receipt: parsed(), at: day),
        entry('b', receipt: parsed(), at: day),
      ]);

      expect(out[0].isDuplicate, isFalse);
      expect(out[1].duplicateOf, 'a');
    });

    test('a different amount is not a duplicate', () {
      final out = flagDuplicates([
        entry('a', receipt: parsed(amount: 10), at: day),
        entry('b', receipt: parsed(amount: 11), at: day),
      ]);

      expect(out[1].isDuplicate, isFalse);
    });

    test('a different day is not a duplicate', () {
      final out = flagDuplicates([
        entry('a', receipt: parsed(), at: day),
        entry('b', receipt: parsed(), at: day.add(const Duration(days: 1))),
      ]);

      expect(
        out[1].isDuplicate,
        isFalse,
        reason: 'the same coffee bought two days running is two expenses',
      );
    });

    test('three copies all chain to the first', () {
      final out = flagDuplicates([
        entry('a', receipt: parsed(), at: day),
        entry('b', receipt: parsed(), at: day),
        entry('c', receipt: parsed(), at: day),
      ]);

      expect(out[1].duplicateOf, 'a');
      expect(
        out[2].duplicateOf,
        'a',
        reason: 'chaining to the surviving original, not to another duplicate',
      );
    });

    test('unparsed entries are never flagged', () {
      final out = flagDuplicates([
        entry('a', at: day),
        entry('b', at: day),
      ]);

      expect(out[1].isDuplicate, isFalse);
    });
  });
}
