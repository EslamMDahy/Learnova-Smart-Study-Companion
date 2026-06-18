import 'dart:convert';

import 'key_value_store.dart';
import 'key_value_store_factory.dart';

/// Stores the latest published exams returned by backend exam endpoints.
///
/// Why this exists:
/// The backend student endpoint can currently return 500 for older published
/// exams that have null availability dates. Flutter cannot recover data from a
/// failed 500 response, so the student course sidebar can reuse the last exam
/// list that the instructor area already loaded from the backend.
class PublishedExamsCache {
  PublishedExamsCache._();

  static const _prefix = 'learnova_published_exams_course_';
  static const _indexKey = 'learnova_published_exams_course_index';
  static final KeyValueStore _local = createLocalStore();

  static String _key(int courseId) => '$_prefix$courseId';

  static void saveInstructorPayload({
    required int courseId,
    required dynamic payload,
  }) {
    final root = _asMap(payload);
    if (root == null) return;

    final rawExams = root['exams'] ?? root['items'] ?? root['results'];
    if (rawExams is! List) return;

    final normalized = rawExams
        .whereType<Map>()
        .map((item) => _normalizeExam(
              Map<String, dynamic>.from(item),
              fallbackCourseId: courseId,
            ))
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    final payloadCourseId = _asInt(root['course_id'], fallback: courseId);
    final courseIds = <int>{
      if (courseId > 0) courseId,
      if (payloadCourseId > 0) payloadCourseId,
      for (final exam in normalized)
        if (_asInt(exam['course_id']) > 0) _asInt(exam['course_id']),
    };

    for (final id in courseIds) {
      _savePayload(
        courseId: id,
        courseTitle: _emptyToNull(root['course_title'] ?? root['title']),
        courseCode: _emptyToNull(root['course_code'] ?? root['code']),
        exams: normalized,
      );
    }
  }

  static void saveInstructorExams({
    required int courseId,
    String? courseTitle,
    String? courseCode,
    required List<Map<String, dynamic>> exams,
  }) {
    if (courseId <= 0) return;

    final normalized = exams
        .map((item) => _normalizeExam(
              item,
              fallbackCourseId: courseId,
            ))
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    _savePayload(
      courseId: courseId,
      courseTitle: courseTitle,
      courseCode: courseCode,
      exams: normalized,
    );
  }

  static void saveStudentPayload({
    required int courseId,
    String? courseTitle,
    String? courseCode,
    required dynamic payload,
  }) {
    if (courseId <= 0) return;

    final root = _asMap(payload);
    final rawExams = root == null
        ? payload
        : root['exams'] ?? root['items'] ?? root['results'];
    if (rawExams is! List) return;

    final normalized = rawExams
        .whereType<Map>()
        .map((item) => _normalizeExam(
              Map<String, dynamic>.from(item),
              fallbackCourseId: courseId,
              assumePublished: true,
            ))
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    _savePayload(
      courseId: courseId,
      courseTitle: courseTitle,
      courseCode: courseCode,
      exams: normalized,
    );
  }

  static List<Map<String, dynamic>> loadPublishedExams(
    int courseId, {
    String? courseTitle,
    String? courseCode,
  }) {
    if (courseId <= 0 && _normalizeText(courseTitle).isEmpty) return const [];

    if (courseId > 0) {
      final exact = _loadFromKey(_key(courseId), requestedCourseId: courseId);
      if (exact.isNotEmpty) return exact;
    }

    final index = _readIndex();
    for (final indexedCourseId in index) {
      if (indexedCourseId == courseId) continue;
      final fromIndex = _loadFromKey(
        _key(indexedCourseId),
        requestedCourseId: courseId,
        requestedCourseTitle: courseTitle,
        requestedCourseCode: courseCode,
      );
      if (fromIndex.isNotEmpty) return fromIndex;
    }

    return const [];
  }

  static void clear(int courseId) {
    if (courseId <= 0) return;
    _local.remove(_key(courseId));
    final index = _readIndex()..remove(courseId);
    _writeIndex(index);
  }

  static void _savePayload({
    required int courseId,
    required List<Map<String, dynamic>> exams,
    String? courseTitle,
    String? courseCode,
  }) {
    if (courseId <= 0) return;

    final scopedExams = exams
        .map((exam) {
          final copy = Map<String, dynamic>.from(exam);
          if (_asInt(copy['course_id']) <= 0) copy['course_id'] = courseId;
          return copy;
        })
        .where((exam) => _asInt(exam['id']) > 0)
        .toList(growable: false);

    final cachePayload = <String, dynamic>{
      'course_id': courseId,
      'course_title': _emptyToNull(courseTitle),
      'course_code': _emptyToNull(courseCode),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'exams': scopedExams,
    }..removeWhere((_, value) => value == null);

    _local.setString(_key(courseId), jsonEncode(cachePayload));
    final index = _readIndex()..add(courseId);
    _writeIndex(index);
  }

  static List<Map<String, dynamic>> _loadFromKey(
    String key, {
    required int requestedCourseId,
    String? requestedCourseTitle,
    String? requestedCourseCode,
  }) {
    final raw = _local.getString(key);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      final root = _asMap(decoded);
      if (root == null) return const [];

      final rawExams = root['exams'];
      if (rawExams is! List) return const [];

      final cacheCourseId = _asInt(root['course_id']);
      final cacheTitle = _normalizeText(root['course_title']);
      final cacheCode = _normalizeText(root['course_code']);
      final requestedTitle = _normalizeText(requestedCourseTitle);
      final requestedCode = _normalizeText(requestedCourseCode);

      final allExams = rawExams
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => _asInt(item['id']) > 0)
          .toList(growable: false);

      if (allExams.isEmpty) return const [];

      final idMatched = requestedCourseId > 0 &&
          (cacheCourseId == requestedCourseId ||
              allExams.any((exam) => _asInt(exam['course_id']) == requestedCourseId));
      final titleMatched = requestedTitle.isNotEmpty && cacheTitle == requestedTitle;
      final codeMatched = requestedCode.isNotEmpty && cacheCode == requestedCode;

      if (!idMatched && !titleMatched && !codeMatched) return const [];

      if (requestedCourseId <= 0) return allExams;

      final scoped = allExams
          .where((exam) {
            final examCourseId = _asInt(exam['course_id']);
            return examCourseId <= 0 || examCourseId == requestedCourseId || cacheCourseId == requestedCourseId;
          })
          .toList(growable: false);
      return scoped.isEmpty ? allExams : scoped;
    } catch (_) {
      return const [];
    }
  }

  static Set<int> _readIndex() {
    final raw = _local.getString(_indexKey);
    if (raw == null || raw.trim().isEmpty) return <int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map(_asInt).where((id) => id > 0).toSet();
      }
    } catch (_) {}
    return <int>{};
  }

  static void _writeIndex(Set<int> index) {
    final values = index.where((id) => id > 0).toList()..sort();
    _local.setString(_indexKey, jsonEncode(values));
  }

  static Map<String, dynamic>? _normalizeExam(
    Map<String, dynamic> json, {
    int fallbackCourseId = 0,
    bool assumePublished = false,
  }) {
    final status = _normalizeText(json['status']);
    final isPublished = assumePublished ||
        _asBool(json['is_published'], fallback: false) ||
        status == 'published' ||
        status == 'live';
    if (!isPublished) return null;

    final id = _asInt(json['id'] ?? json['exam_id']);
    if (id <= 0) return null;

    final courseId = _asInt(json['course_id'], fallback: fallbackCourseId);
    final availableFrom = _asString(json['available_from']);
    final availableTo = _asString(json['available_to']);

    return <String, dynamic>{
      'id': id,
      'course_id': courseId,
      'title': _asString(json['title']).isEmpty ? 'Untitled exam' : _asString(json['title']),
      'description': _emptyToNull(json['description']),
      'exam_type': _asString(json['exam_type']).isEmpty ? 'exam' : _asString(json['exam_type']),
      'duration_minutes': _nullableInt(json['duration_minutes']),
      'max_attempts': _asInt(json['max_attempts'], fallback: 1),
      'passing_score': _nullableDouble(json['passing_score']),
      'total_questions': _asInt(json['total_questions']),
      'total_score': _nullableDouble(json['total_score']) ?? 0,
      'available_from': availableFrom.isEmpty ? null : availableFrom,
      'available_to': availableTo.isEmpty ? null : availableTo,
      // Cached published exams are visible in the sidebar. Starting the attempt
      // still goes through the backend student attempt endpoint.
      'is_available': _asBool(json['is_available'], fallback: true),
    }..removeWhere((_, value) => value == null);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _asString(dynamic value) => (value ?? '').toString().trim();

  static String _normalizeText(dynamic value) => _asString(value).toLowerCase();

  static String? _emptyToNull(dynamic value) {
    final normalized = _asString(value);
    return normalized.isEmpty ? null : normalized;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return fallback;
  }
}
