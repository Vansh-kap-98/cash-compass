/// Collision-free id generation.
///
/// The obvious `'$prefix-${DateTime.now().millisecondsSinceEpoch}'` breaks as
/// soon as two records are created inside the same millisecond — which never
/// happens when a human taps a button, but happens immediately in a loop
/// (importing, seeding, or a future bulk edit). Duplicate ids also collide in
/// `ValueKey`s, which makes Flutter mis-associate list rows.
///
/// A monotonic counter appended to the timestamp keeps ids unique within a
/// session while staying sortable and readable.
library;

int _counter = 0;

/// Returns an id like `tx-1787159963270-7`.
String newId(String prefix) {
  _counter++;
  return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$_counter';
}

/// Resets the counter. Tests only — keeps ids predictable across cases.
void resetIdCounterForTest() => _counter = 0;
