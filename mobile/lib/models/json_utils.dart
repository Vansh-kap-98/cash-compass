/// Shared decoding helpers for the hand-written `fromJson` factories.
///
/// These exist because of two real porting hazards from the JS original:
///
/// 1. JavaScript has one number type; Dart distinguishes `int` from `double`.
///    `jsonDecode` returns `int` for `5` and `double` for `5.0`, and `int` is
///    not assignable to `double`. Reading money without [asDouble] produces a
///    crash that only fires for whole-number amounts.
/// 2. `Enum.values.byName` throws on an unknown string. Data written by a newer
///    build must not hard-crash an older one, so [enumByName] falls back.
library;

/// Reads a JSON number as a [double], whatever the encoder wrote.
double asDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads a JSON number as a nullable [double]. Non-finite values become null,
/// matching the `Number.isFinite` guards in `FinanceContext.tsx`.
double? asNullableDouble(Object? value) {
  if (value == null) return null;
  final parsed = value is num
      ? value.toDouble()
      : value is String
          ? double.tryParse(value)
          : null;
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}

/// Looks up an enum value by name, falling back instead of throwing.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Reads a list of enum values, silently dropping entries that no longer exist.
List<T> enumListByName<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! List) return const [];
  final result = <T>[];
  for (final entry in raw) {
    if (entry is! String) continue;
    for (final value in values) {
      if (value.name == entry) {
        result.add(value);
        break;
      }
    }
  }
  return result;
}

/// Reads a list of JSON objects into models, skipping malformed entries rather
/// than losing the whole store to one bad record.
List<T> decodeList<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return <T>[];
  final result = <T>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    try {
      result.add(fromJson(Map<String, dynamic>.from(entry)));
    } catch (_) {
      // Skip records we cannot read; one corrupt row must not wipe the history.
    }
  }
  return result;
}
