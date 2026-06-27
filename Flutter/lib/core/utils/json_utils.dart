import 'dart:convert';

/// Small, dependency-free helpers for converting untyped API/cache payloads
/// into predictable values before they reach widgets.
typedef JsonMap = Map<String, Object?>;

JsonMap? asJsonMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    final output = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) output[key] = entry.value;
    }
    return output;
  }
  return null;
}

JsonMap requireJsonMap(Object? value, String message) {
  final map = asJsonMap(value);
  if (map == null) throw FormatException(message);
  return map;
}

List<Object?>? asJsonList(Object? value) {
  if (value is List) return value.cast<Object?>();
  return null;
}

List<Object?> requireJsonList(Object? value, String message) {
  final list = asJsonList(value);
  if (list == null) throw FormatException(message);
  return list;
}

List<JsonMap> jsonMapList(Object? value) {
  if (value is! Iterable) return const <JsonMap>[];
  return value
      .map(asJsonMap)
      .whereType<JsonMap>()
      .toList(growable: false);
}

String jsonString(Object? value) => (value ?? '').toString().trim();

String? jsonNullableString(Object? value) {
  final text = jsonString(value);
  return text.isEmpty ? null : text;
}

String? jsonFirstNonEmptyString(Iterable<Object?> values) {
  for (final value in values) {
    final text = jsonNullableString(value);
    if (text != null) return text;
  }
  return null;
}

int jsonInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? jsonNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? jsonNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool jsonBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

DateTime? jsonDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<String> jsonStringList(Object? value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .map(jsonString)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final raw = jsonString(value);
  if (raw.isEmpty) return const <String>[];
  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Object? tryJsonDecode(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}
