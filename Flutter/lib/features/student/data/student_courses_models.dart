import 'dart:convert';

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _asBool(dynamic value, {bool fallback = false}) {
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

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String _asString(dynamic value) => (value ?? '').toString().trim();


String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = _asNullableString(value);
    if (text != null) return text;
  }
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final raw = value.toString().trim();
  if (raw.isEmpty) return const [];
  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

enum StudentCourseSource { enrolled, publicSearch }

class StudentCourse {
  final int id;
  final String title;
  final String? description;
  final String? courseCode;
  final String? category;
  final String? coverImageUrl;
  final List<String> tags;
  final String status;
  final String? enrollmentStatus;
  final String courseType;
  final int? organizationId;
  final bool isOpenForEnrollment;
  final bool requiresEnrollmentApproval;
  final String visibilityLevel;
  final int? createdBy;
  final int? enrollmentCount;
  final int? pendingInvites;
  final double? averageRating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final StudentCourseSource source;

  const StudentCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.courseCode,
    required this.category,
    required this.coverImageUrl,
    required this.tags,
    required this.status,
    required this.enrollmentStatus,
    required this.courseType,
    required this.organizationId,
    required this.isOpenForEnrollment,
    required this.requiresEnrollmentApproval,
    required this.visibilityLevel,
    required this.createdBy,
    required this.enrollmentCount,
    required this.pendingInvites,
    required this.averageRating,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
  });

  String get safeTitle => title.trim().isEmpty ? 'Untitled course' : title.trim();

  String get safeCode {
    final code = (courseCode ?? '').trim();
    return code.isEmpty ? 'COURSE-$id' : code;
  }

  String get safeCategory {
    final value = (category ?? '').trim();
    return value.isEmpty ? 'General' : value;
  }

  String get safeDescription {
    final value = (description ?? '').trim();
    return value.isEmpty
        ? 'No course description has been added yet.'
        : value;
  }

  bool get isEnrolled => source == StudentCourseSource.enrolled;

  bool get isPendingEnrollment =>
      (enrollmentStatus ?? '').trim().toLowerCase() == 'pending';

  bool get canEnroll =>
      !isEnrolled && isOpenForEnrollment && status.toLowerCase() == 'published';

  String get enrollmentBadge {
    final normalized = (enrollmentStatus ?? '').trim().toLowerCase();
    if (normalized == 'pending') return 'Pending approval';
    if (normalized == 'suspended') return 'Suspended';
    if (normalized == 'completed') return 'Completed';
    return 'Enrolled';
  }

  String get publicBadge {
    if (!isOpenForEnrollment) return 'Closed';
    if (requiresEnrollmentApproval) return 'Approval required';
    return 'Open';
  }

  StudentCourse copyWith({
    String? enrollmentStatus,
    String? coverImageUrl,
    StudentCourseSource? source,
  }) {
    return StudentCourse(
      id: id,
      title: title,
      description: description,
      courseCode: courseCode,
      category: category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags,
      status: status,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      courseType: courseType,
      organizationId: organizationId,
      isOpenForEnrollment: isOpenForEnrollment,
      requiresEnrollmentApproval: requiresEnrollmentApproval,
      visibilityLevel: visibilityLevel,
      createdBy: createdBy,
      enrollmentCount: enrollmentCount,
      pendingInvites: pendingInvites,
      averageRating: averageRating,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source ?? this.source,
    );
  }

  factory StudentCourse.fromMyJson(Map<String, dynamic> json) {
    return StudentCourse(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      courseCode: _asString(json['course_code']).isEmpty
          ? null
          : _asString(json['course_code']),
      category: _asString(json['category']).isEmpty
          ? null
          : _asString(json['category']),
      coverImageUrl: _firstNonEmptyString([
        json['cover_url'],
        json['cover_image_url'],
        json['coverImageUrl'],
      ]),
      tags: _asStringList(json['tags']),
      status: _asString(json['status']).isEmpty ? 'published' : _asString(json['status']),
      enrollmentStatus: _asString(json['enrollment_status']).isEmpty
          ? 'active'
          : _asString(json['enrollment_status']),
      courseType: _asString(json['course_type']).isEmpty
          ? 'individual'
          : _asString(json['course_type']),
      organizationId: _asNullableInt(json['organization_id']),
      isOpenForEnrollment: _asBool(
        json['is_open_for_enrollment'],
        fallback: true,
      ),
      requiresEnrollmentApproval: _asBool(json['requires_enrollment_approval']),
      visibilityLevel: _asString(json['visibility_level']).isEmpty
          ? 'public'
          : _asString(json['visibility_level']),
      createdBy: _asNullableInt(json['created_by']),
      enrollmentCount: _asNullableInt(json['enrollment_count']),
      pendingInvites: _asNullableInt(json['pending_invites']),
      averageRating: _asNullableDouble(json['average_rating']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      source: StudentCourseSource.enrolled,
    );
  }

  factory StudentCourse.fromSearchJson(Map<String, dynamic> json) {
    return StudentCourse(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      courseCode: _asString(json['course_code']).isEmpty
          ? null
          : _asString(json['course_code']),
      category: _asString(json['category']).isEmpty
          ? null
          : _asString(json['category']),
      coverImageUrl: _firstNonEmptyString([
        json['cover_url'],
        json['cover_image_url'],
        json['coverImageUrl'],
      ]),
      tags: _asStringList(json['tags']),
      status: _asString(json['status']).isEmpty ? 'published' : _asString(json['status']),
      enrollmentStatus: null,
      courseType: _asString(json['course_type']).isEmpty
          ? 'individual'
          : _asString(json['course_type']),
      organizationId: _asNullableInt(json['organization_id']),
      isOpenForEnrollment: _asBool(
        json['is_open_for_enrollment'],
        fallback: true,
      ),
      requiresEnrollmentApproval: _asBool(json['requires_enrollment_approval']),
      visibilityLevel: _asString(json['visibility_level']).isEmpty
          ? 'public'
          : _asString(json['visibility_level']),
      createdBy: _asNullableInt(json['created_by']),
      enrollmentCount: _asNullableInt(json['enrollment_count']),
      pendingInvites: null,
      averageRating: _asNullableDouble(json['average_rating']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      source: StudentCourseSource.publicSearch,
    );
  }
}

class StudentMyCoursesResponse {
  final List<StudentCourse> items;
  final int total;

  const StudentMyCoursesResponse({required this.items, required this.total});

  factory StudentMyCoursesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid /courses/my payload');
    }

    final items = rawItems
        .whereType<Map>()
        .map((item) => StudentCourse.fromMyJson(Map<String, dynamic>.from(item)))
        .where((course) => course.id > 0)
        .toList(growable: false);

    return StudentMyCoursesResponse(
      items: items,
      total: _asInt(json['total'], fallback: items.length),
    );
  }
}

class StudentCourseSearchResponse {
  final int total;
  final int limit;
  final int offset;
  final List<StudentCourse> results;

  const StudentCourseSearchResponse({
    required this.total,
    required this.limit,
    required this.offset,
    required this.results,
  });

  factory StudentCourseSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] ?? json['items'] ?? json['courses'];
    if (rawResults is! List) {
      throw const FormatException('Invalid /courses/search payload');
    }

    final results = _parseSearchResults(rawResults);

    return StudentCourseSearchResponse(
      total: _asInt(json['total'], fallback: results.length),
      limit: _asInt(json['limit'], fallback: results.length),
      offset: _asInt(json['offset']),
      results: results,
    );
  }

  factory StudentCourseSearchResponse.fromList(
    List<dynamic> rawResults, {
    required int limit,
    required int offset,
  }) {
    final results = _parseSearchResults(rawResults);
    return StudentCourseSearchResponse(
      total: results.length,
      limit: limit,
      offset: offset,
      results: results,
    );
  }

  static List<StudentCourse> _parseSearchResults(List<dynamic> rawResults) {
    return rawResults
        .whereType<Map>()
        .map((item) => StudentCourse.fromSearchJson(Map<String, dynamic>.from(item)))
        .where((course) => course.id > 0)
        .toList(growable: false);
  }
}

class StudentCourseAutocompleteResponse {
  final List<String> suggestions;

  const StudentCourseAutocompleteResponse({required this.suggestions});

  factory StudentCourseAutocompleteResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSuggestions =
        json['suggestions'] ?? json['items'] ?? json['results'];

    if (rawSuggestions is List) {
      return StudentCourseAutocompleteResponse.fromList(rawSuggestions);
    }

    return const StudentCourseAutocompleteResponse(suggestions: []);
  }

  factory StudentCourseAutocompleteResponse.fromList(List<dynamic> raw) {
    final seen = <String>{};
    final suggestions = <String>[];

    for (final item in raw) {
      final suggestion = _asString(item);
      if (suggestion.isEmpty) continue;

      final normalized = suggestion.toLowerCase();
      if (seen.add(normalized)) {
        suggestions.add(suggestion);
      }
    }

    return StudentCourseAutocompleteResponse(
      suggestions: suggestions.take(8).toList(growable: false),
    );
  }
}

class StudentCourseEnrollmentResult {
  final int enrollmentId;
  final int courseId;
  final String status;
  final String enrollmentType;
  final DateTime? enrolledAt;

  const StudentCourseEnrollmentResult({
    required this.enrollmentId,
    required this.courseId,
    required this.status,
    required this.enrollmentType,
    required this.enrolledAt,
  });

  bool get isPending => status.trim().toLowerCase() == 'pending';

  factory StudentCourseEnrollmentResult.fromJson(Map<String, dynamic> json) {
    return StudentCourseEnrollmentResult(
      enrollmentId: _asInt(json['enrollment_id']),
      courseId: _asInt(json['course_id']),
      status: _asString(json['status']).isEmpty ? 'active' : _asString(json['status']),
      enrollmentType: _asString(json['enrollment_type']).isEmpty
          ? 'self'
          : _asString(json['enrollment_type']),
      enrolledAt: _asDate(json['enrolled_at']),
    );
  }
}

class StudentCourseInviteAcceptResult {
  final String message;
  final int courseId;
  final int? enrollmentId;
  final bool enrolled;
  final DateTime? acceptedAt;

  const StudentCourseInviteAcceptResult({
    required this.message,
    required this.courseId,
    required this.enrollmentId,
    required this.enrolled,
    required this.acceptedAt,
  });

  factory StudentCourseInviteAcceptResult.fromJson(Map<String, dynamic> json) {
    return StudentCourseInviteAcceptResult(
      message: _asString(json['message']).isEmpty
          ? 'Invitation accepted. You are now enrolled in the course.'
          : _asString(json['message']),
      courseId: _asInt(json['course_id']),
      enrollmentId: _asNullableInt(json['enrollment_id']),
      enrolled: _asBool(json['enrolled'], fallback: true),
      acceptedAt: _asDate(json['accepted_at']),
    );
  }
}


class StudentCourseContent {
  final StudentCourse? course;
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;

  const StudentCourseContent({
    required this.course,
    required this.modules,
    this.exams = const [],
    this.examsLoadError,
  });

  int get materialCount => modules.fold<int>(
        0,
        (total, module) => total + module.materials.length,
      );

  int get examCount => exams.length;

  bool get hasExamsLoadError =>
      examsLoadError != null && examsLoadError!.trim().isNotEmpty;
}

class StudentCourseModule {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int orderIndex;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<StudentCourseMaterial> materials;

  const StudentCourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.isPublished,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.materials = const [],
  });

  String get safeTitle {
    final value = title.trim();
    return value.isEmpty ? 'Untitled module' : value;
  }

  String get safeDescription {
    final value = (description ?? '').trim();
    return value.isEmpty ? 'No module description has been added yet.' : value;
  }

  StudentCourseModule copyWith({
    List<StudentCourseMaterial>? materials,
  }) {
    return StudentCourseModule(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      orderIndex: orderIndex,
      isPublished: isPublished,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      materials: materials ?? this.materials,
    );
  }

  factory StudentCourseModule.fromJson(Map<String, dynamic> json) {
    return StudentCourseModule(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      orderIndex: _asInt(json['order_index']),
      isPublished: _asBool(json['is_published']),
      publishedAt: _asDate(json['published_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }
}


class StudentCourseTopic {
  final int id;
  final int materialId;
  final String title;
  final String? description;
  final int orderIndex;
  final int? parentTopicId;
  final bool isAiGenerated;
  final bool isReviewed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentCourseTopic({
    required this.id,
    required this.materialId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.parentTopicId,
    required this.isAiGenerated,
    required this.isReviewed,
    required this.createdAt,
    required this.updatedAt,
  });

  String get safeTitle {
    final value = title.trim();
    return value.isEmpty ? 'Untitled topic' : value;
  }

  String get safeDescription {
    final value = (description ?? '').trim();
    return value.isEmpty ? 'No topic description has been added yet.' : value;
  }

  factory StudentCourseTopic.fromJson(Map<String, dynamic> json) {
    return StudentCourseTopic(
      id: _asInt(json['id']),
      materialId: _asInt(json['material_id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      orderIndex: _asInt(json['order_index']),
      parentTopicId: _asNullableInt(json['parent_topic_id']),
      isAiGenerated: _asBool(json['is_ai_generated']),
      isReviewed: _asBool(json['is_reviewed']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }
}


class StudentCourseTranscriptSegment {
  final String marker;
  final String text;

  const StudentCourseTranscriptSegment({
    required this.marker,
    required this.text,
  });

  bool get isValid => marker.trim().isNotEmpty && text.trim().isNotEmpty;

  factory StudentCourseTranscriptSegment.fromJson(Map<String, dynamic> json) {
    final rawMarker = _asString(
      json['timestamp'] ??
          json['time'] ??
          json['start_time'] ??
          json['start'] ??
          json['marker'],
    );
    final rawText = _asString(
      json['text'] ?? json['content'] ?? json['transcript'] ?? json['body'],
    );

    return StudentCourseTranscriptSegment(
      marker: rawMarker.isEmpty ? '00:00' : rawMarker,
      text: rawText,
    );
  }
}

List<StudentCourseTranscriptSegment> _asTranscriptSegments(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => StudentCourseTranscriptSegment.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((segment) => segment.isValid)
        .toList(growable: false);
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return const [];

  return [
    StudentCourseTranscriptSegment(marker: '00:00', text: raw),
  ];
}

List<StudentCourseTopic> _asTopics(dynamic value) {
  if (value == null || value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => StudentCourseTopic.fromJson(Map<String, dynamic>.from(item)))
      .where((topic) => topic.id > 0)
      .toList(growable: false);
}


class StudentCourseMaterial {
  final int id;
  final int moduleId;
  final String? title;
  final String? description;
  final String type;
  final String status;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? pageCount;
  final int? durationSeconds;
  final DateTime? uploadedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? downloadUrl;
  final String? summary;
  final List<StudentCourseTranscriptSegment> transcriptSegments;
  final List<StudentCourseTopic> topics;

  const StudentCourseMaterial({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.pageCount,
    required this.durationSeconds,
    required this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.downloadUrl,
    required this.summary,
    this.transcriptSegments = const [],
    this.topics = const [],
  });

  String get safeTitle {
    final fromTitle = (title ?? '').trim();
    if (fromTitle.isNotEmpty) return fromTitle;

    final fromFile = (fileName ?? '').trim();
    if (fromFile.isNotEmpty) return fromFile;

    return 'Untitled material';
  }

  String get safeDescription {
    final value = (description ?? '').trim();
    return value.isEmpty ? 'No material description has been added yet.' : value;
  }

  String get safeType {
    final value = type.trim();
    return value.isEmpty ? 'material' : value.replaceAll('_', ' ');
  }

  String get safeStatus {
    final value = status.trim();
    return value.isEmpty ? 'available' : value.replaceAll('_', ' ');
  }

  bool get hasDownloadUrl => (downloadUrl ?? '').trim().isNotEmpty;

  StudentCourseMaterial copyWith({
    List<StudentCourseTopic>? topics,
  }) {
    return StudentCourseMaterial(
      id: id,
      moduleId: moduleId,
      title: title,
      description: description,
      type: type,
      status: status,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      pageCount: pageCount,
      durationSeconds: durationSeconds,
      uploadedAt: uploadedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      downloadUrl: downloadUrl,
      summary: summary,
      transcriptSegments: transcriptSegments,
      topics: topics ?? this.topics,
    );
  }

  factory StudentCourseMaterial.fromJson(Map<String, dynamic> json) {
    return StudentCourseMaterial(
      id: _asInt(json['id']),
      moduleId: _asInt(json['module_id']),
      title: _asString(json['title']).isEmpty
          ? null
          : _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      type: _asString(json['type']).isEmpty ? 'material' : _asString(json['type']),
      status: _asString(json['status']).isEmpty
          ? 'available'
          : _asString(json['status']),
      fileName: _asString(json['file_name']).isEmpty
          ? null
          : _asString(json['file_name']),
      fileSize: _asNullableInt(json['file_size']),
      mimeType: _asString(json['mime_type']).isEmpty
          ? null
          : _asString(json['mime_type']),
      pageCount: _asNullableInt(json['page_count']),
      durationSeconds: _asNullableInt(json['duration_seconds']),
      uploadedAt: _asDate(json['uploaded_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      downloadUrl: _asString(json['download_url']).isEmpty
          ? null
          : _asString(json['download_url']),
      summary: _asString(json['summary']).isEmpty
          ? null
          : _asString(json['summary']),
      transcriptSegments: _asTranscriptSegments(
        json['transcript_segments'] ??
            json['transcript'] ??
            json['captions'] ??
            json['segments'],
      ),
      topics: _asTopics(json['topics']),
    );
  }
}

class StudentCourseExamListResponse {
  final int courseId;
  final int total;
  final List<StudentCourseExam> exams;

  const StudentCourseExamListResponse({
    required this.courseId,
    required this.total,
    required this.exams,
  });

  factory StudentCourseExamListResponse.fromJson(Map<String, dynamic> json) {
    final rawExams = json['exams'] ?? json['items'] ?? json['results'];
    if (rawExams is! List) {
      throw const FormatException('Invalid student exams payload');
    }

    final exams = rawExams
        .whereType<Map>()
        .map((item) => StudentCourseExam.fromJson(Map<String, dynamic>.from(item)))
        .where((exam) => exam.id > 0)
        .toList(growable: false);

    return StudentCourseExamListResponse(
      courseId: _asInt(json['course_id']),
      total: _asInt(json['total'], fallback: exams.length),
      exams: exams,
    );
  }
}

class StudentCourseExam {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String examType;
  final int? durationMinutes;
  final int maxAttempts;
  final double? passingScore;
  final int totalQuestions;
  final double totalScore;
  final int? moduleId;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isAvailable;

  const StudentCourseExam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.examType,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.passingScore,
    required this.totalQuestions,
    required this.totalScore,
    required this.moduleId,
    required this.availableFrom,
    required this.availableTo,
    required this.isAvailable,
  });

  String get safeTitle => title.trim().isEmpty ? 'Untitled exam' : title.trim();
  String get safeType => examType.trim().isEmpty ? 'exam' : examType.trim();

  String get safeDescription {
    final value = (description ?? '').trim();
    return value.isEmpty
        ? 'This published assessment is ready for enrolled students.'
        : value;
  }

  bool get hasAvailabilityWindow => availableFrom != null || availableTo != null;

  factory StudentCourseExam.fromJson(Map<String, dynamic> json) {
    return StudentCourseExam(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      examType: _asString(json['exam_type']).isEmpty
          ? 'exam'
          : _asString(json['exam_type']),
      durationMinutes: _asNullableInt(json['duration_minutes']),
      maxAttempts: _asInt(json['max_attempts'], fallback: 1),
      passingScore: _asNullableDouble(json['passing_score']),
      totalQuestions: _asInt(json['total_questions']),
      totalScore: _asNullableDouble(json['total_score']) ?? 0,
      moduleId: _asNullableInt(json['module_id'] ?? json['moduleId']),
      availableFrom: _asDate(json['available_from']),
      availableTo: _asDate(json['available_to']),
      isAvailable: _asBool(json['is_available'], fallback: true),
    );
  }
}

class StudentExamAttempt {
  final int examId;
  final int attemptId;
  final int attemptNumber;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String title;
  final String? description;
  final String? instructions;
  final String examType;
  final int? durationMinutes;
  final int totalQuestions;
  final double totalScore;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool enableProctoring;
  final bool preventCopyPaste;
  final bool preventTabSwitch;
  final bool requireWebcam;
  final bool requireMicrophone;
  final List<StudentExamSection> sections;

  const StudentExamAttempt({
    required this.examId,
    required this.attemptId,
    required this.attemptNumber,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.title,
    required this.description,
    required this.instructions,
    required this.examType,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.totalScore,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.enableProctoring,
    required this.preventCopyPaste,
    required this.preventTabSwitch,
    required this.requireWebcam,
    required this.requireMicrophone,
    required this.sections,
  });

  String get safeTitle => title.trim().isEmpty ? 'Untitled exam' : title.trim();
  String get safeType => examType.trim().isEmpty ? 'exam' : examType.trim();

  List<StudentExamQuestion> get questions => sections
      .expand((section) => section.questions)
      .toList(growable: false);

  factory StudentExamAttempt.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = rawSections is List
        ? rawSections
            .whereType<Map>()
            .map((item) => StudentExamSection.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <StudentExamSection>[];

    return StudentExamAttempt(
      examId: _asInt(json['exam_id']),
      attemptId: _asInt(json['attempt_id']),
      attemptNumber: _asInt(json['attempt_number'], fallback: 1),
      status: _asString(json['status']).isEmpty
          ? 'in_progress'
          : _asString(json['status']),
      startedAt: _asDate(json['started_at']),
      expiresAt: _asDate(json['expires_at']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      instructions: _asString(json['instructions']).isEmpty
          ? null
          : _asString(json['instructions']),
      examType: _asString(json['exam_type']).isEmpty
          ? 'exam'
          : _asString(json['exam_type']),
      durationMinutes: _asNullableInt(json['duration_minutes']),
      totalQuestions: _asInt(json['total_questions']),
      totalScore: _asNullableDouble(json['total_score']) ?? 0,
      shuffleQuestions: _asBool(json['shuffle_questions']),
      shuffleOptions: _asBool(json['shuffle_options']),
      enableProctoring: _asBool(json['enable_proctoring']),
      preventCopyPaste: _asBool(json['prevent_copy_paste']),
      preventTabSwitch: _asBool(json['prevent_tab_switch']),
      requireWebcam: _asBool(json['require_webcam']),
      requireMicrophone: _asBool(json['require_microphone']),
      sections: sections,
    );
  }
}

class StudentExamSection {
  final int id;
  final String title;
  final String? description;
  final String questionType;
  final int orderIndex;
  final int questionCount;
  final double sectionScore;
  final int? timeLimitMinutes;
  final bool mustComplete;
  final List<StudentExamQuestion> questions;

  const StudentExamSection({
    required this.id,
    required this.title,
    required this.description,
    required this.questionType,
    required this.orderIndex,
    required this.questionCount,
    required this.sectionScore,
    required this.timeLimitMinutes,
    required this.mustComplete,
    required this.questions,
  });

  String get safeTitle => title.trim().isEmpty ? 'Questions' : title.trim();

  factory StudentExamSection.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => StudentExamQuestion.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((question) => question.examQuestionId > 0)
            .toList(growable: false)
        : const <StudentExamQuestion>[];

    return StudentExamSection(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      questionType: _asString(json['question_type']).isEmpty
          ? 'question'
          : _asString(json['question_type']),
      orderIndex: _asInt(json['order_index']),
      questionCount: _asInt(json['question_count'], fallback: questions.length),
      sectionScore: _asNullableDouble(json['section_score']) ?? 0,
      timeLimitMinutes: _asNullableInt(json['time_limit_minutes']),
      mustComplete: _asBool(json['must_complete'], fallback: true),
      questions: questions,
    );
  }
}

class StudentExamQuestion {
  final int examQuestionId;
  final int questionId;
  final int orderIndex;
  final double points;
  final String questionText;
  final String type;
  final String difficulty;
  final List<StudentExamQuestionOption> options;
  final bool autoGradable;

  const StudentExamQuestion({
    required this.examQuestionId,
    required this.questionId,
    required this.orderIndex,
    required this.points,
    required this.questionText,
    required this.type,
    required this.difficulty,
    required this.options,
    required this.autoGradable,
  });

  String get safeText => questionText.trim().isEmpty
      ? 'Question text is not available.'
      : questionText.trim();
  String get safeType => type.trim().isEmpty ? 'question' : type.trim();
  String get safeDifficulty => difficulty.trim().isEmpty ? 'medium' : difficulty.trim();

  bool get hasOptions => options.isNotEmpty;

  bool get allowsMultipleSelection {
    final normalized = safeType.toLowerCase().replaceAll('-', '_');
    return normalized.contains('multi_select') ||
        normalized.contains('multiple_answer') ||
        normalized.contains('checkbox');
  }

  factory StudentExamQuestion.fromJson(Map<String, dynamic> json) {
    return StudentExamQuestion(
      examQuestionId: _asInt(json['exam_question_id']),
      questionId: _asInt(json['question_id']),
      orderIndex: _asInt(json['order_index']),
      points: _asNullableDouble(json['points']) ?? 0,
      questionText: _asString(json['question_text']),
      type: _asString(json['type']).isEmpty ? 'question' : _asString(json['type']),
      difficulty: _asString(json['difficulty']).isEmpty
          ? 'medium'
          : _asString(json['difficulty']),
      options: _asExamOptions(json['options']),
      autoGradable: _asBool(json['auto_gradable']),
    );
  }
}

class StudentExamQuestionOption {
  final String id;
  final String text;

  const StudentExamQuestionOption({
    required this.id,
    required this.text,
  });

  bool get isValid => text.trim().isNotEmpty;

  factory StudentExamQuestionOption.fromJson(Map<String, dynamic> json, int index) {
    final rawId = _asString(json['id'] ?? json['key'] ?? json['value']);
    final rawText = _asString(
      json['text'] ?? json['label'] ?? json['answer'] ?? json['content'],
    );

    return StudentExamQuestionOption(
      id: rawId.isEmpty ? index.toString() : rawId,
      text: rawText.isEmpty ? 'Option ${index + 1}' : rawText,
    );
  }
}

List<StudentExamQuestionOption> _asExamOptions(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    final options = <StudentExamQuestionOption>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      if (item is Map) {
        final option = StudentExamQuestionOption.fromJson(
          Map<String, dynamic>.from(item),
          i,
        );
        if (option.isValid) options.add(option);
      } else {
        final text = _asString(item);
        if (text.isNotEmpty) {
          options.add(StudentExamQuestionOption(id: i.toString(), text: text));
        }
      }
    }
    return options;
  }
  return const [];
}

class StudentExamAnswerDraft {
  final int examQuestionId;
  final int? selectedOptionIndex;
  final List<int>? selectedOptionIndices;
  final String? answerText;
  final int? timeTakenSeconds;

  const StudentExamAnswerDraft({
    required this.examQuestionId,
    this.selectedOptionIndex,
    this.selectedOptionIndices,
    this.answerText,
    this.timeTakenSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'exam_question_id': examQuestionId,
      if (selectedOptionIndex != null) 'selected_option_index': selectedOptionIndex,
      if (selectedOptionIndices != null) 'selected_option_indices': selectedOptionIndices,
      if ((answerText ?? '').trim().isNotEmpty) 'answer_text': answerText!.trim(),
      if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
    };
  }
}

class StudentExamSubmitResult {
  final int attemptId;
  final int examId;
  final String status;
  final double? totalScore;
  final double? percentageScore;
  final bool? isPassed;
  final int? correctCount;
  final int? incorrectCount;
  final int? unansweredCount;
  final DateTime? submittedAt;

  const StudentExamSubmitResult({
    required this.attemptId,
    required this.examId,
    required this.status,
    required this.totalScore,
    required this.percentageScore,
    required this.isPassed,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.submittedAt,
  });

  factory StudentExamSubmitResult.fromJson(Map<String, dynamic> json) {
    return StudentExamSubmitResult(
      attemptId: _asInt(json['attempt_id']),
      examId: _asInt(json['exam_id']),
      status: _asString(json['status']).isEmpty ? 'submitted' : _asString(json['status']),
      totalScore: _asNullableDouble(json['total_score']),
      percentageScore: _asNullableDouble(json['percentage_score']),
      isPassed: json.containsKey('is_passed') ? _asBool(json['is_passed']) : null,
      correctCount: _asNullableInt(json['correct_count']),
      incorrectCount: _asNullableInt(json['incorrect_count']),
      unansweredCount: _asNullableInt(json['unanswered_count']),
      submittedAt: _asDate(json['submitted_at']),
    );
  }
}



class StudentExamAttemptSummary {
  final int attemptId;
  final int attemptNumber;
  final String status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final double totalScore;
  final double? earnedScore;
  final double? percentageScore;
  final bool? isPassed;

  const StudentExamAttemptSummary({
    required this.attemptId,
    required this.attemptNumber,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.gradedAt,
    required this.totalScore,
    required this.earnedScore,
    required this.percentageScore,
    required this.isPassed,
  });

  bool get isInProgress => status.trim().toLowerCase() == 'in_progress';
  bool get hasResult {
    final normalized = status.trim().toLowerCase();
    return submittedAt != null ||
        normalized == 'submitted' ||
        normalized == 'graded' ||
        normalized == 'completed';
  }

  factory StudentExamAttemptSummary.fromJson(Map<String, dynamic> json) {
    return StudentExamAttemptSummary(
      attemptId: _asInt(json['attempt_id']),
      attemptNumber: _asInt(json['attempt_number'], fallback: 1),
      status: _asString(json['status']).isEmpty ? 'in_progress' : _asString(json['status']),
      startedAt: _asDate(json['started_at']),
      submittedAt: _asDate(json['submitted_at']),
      gradedAt: _asDate(json['graded_at']),
      totalScore: _asNullableDouble(json['total_score']) ?? 0,
      earnedScore: _asNullableDouble(json['earned_score']),
      percentageScore: _asNullableDouble(json['percentage_score']),
      isPassed: json.containsKey('is_passed') && json['is_passed'] != null
          ? _asBool(json['is_passed'])
          : null,
    );
  }
}

class StudentExamAttemptsList {
  final int examId;
  final List<StudentExamAttemptSummary> attempts;

  const StudentExamAttemptsList({required this.examId, required this.attempts});

  factory StudentExamAttemptsList.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'];
    final attempts = rawAttempts is List
        ? rawAttempts
            .whereType<Map>()
            .map((item) => StudentExamAttemptSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((attempt) => attempt.attemptId > 0)
            .toList(growable: false)
        : const <StudentExamAttemptSummary>[];

    return StudentExamAttemptsList(
      examId: _asInt(json['exam_id']),
      attempts: attempts,
    );
  }
}

class StudentExamLatestResult {
  final int courseId;
  final int examId;
  final String title;
  final String examType;
  final bool hasAttempt;
  final int? attemptId;
  final int? inProgressAttemptId;
  final int? attemptNumber;
  final String? status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final int? timeSpentSeconds;
  final double scoreEarned;
  final double totalScore;
  final double? percentageScore;
  final bool? isPassed;
  final bool gradingPending;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final int attemptsUsed;
  final int attemptsRemaining;
  final bool canStart;
  final List<StudentExamResultQuestion> questions;

  const StudentExamLatestResult({
    required this.courseId,
    required this.examId,
    required this.title,
    required this.examType,
    required this.hasAttempt,
    required this.attemptId,
    required this.inProgressAttemptId,
    required this.attemptNumber,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.timeSpentSeconds,
    required this.scoreEarned,
    required this.totalScore,
    required this.percentageScore,
    required this.isPassed,
    required this.gradingPending,
    required this.totalQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.attemptsUsed,
    required this.attemptsRemaining,
    required this.canStart,
    required this.questions,
  });

  String get safeTitle => title.trim().isEmpty ? 'Untitled assessment' : title.trim();
  String get safeType => examType.trim().isEmpty ? 'quiz' : examType.trim();
  String get statusLabel {
    if (!hasAttempt) return 'Not taken';
    final normalized = (status ?? '').trim().toLowerCase();
    if (gradingPending) return 'Grading';
    if (normalized == 'graded' || normalized == 'completed' || normalized == 'submitted') {
      return 'Completed';
    }
    return 'Completed';
  }

  int get answeredCount => (totalQuestions - unansweredCount).clamp(0, totalQuestions).toInt();
  double get accuracyPercent {
    final answered = answeredCount;
    if (!hasAttempt || answered <= 0) return 0;
    return (correctCount / answered) * 100;
  }

  factory StudentExamLatestResult.noAttempt({
    required int courseId,
    required int examId,
    int attemptsUsed = 0,
    bool canStart = true,
    int? inProgressAttemptId,
  }) {
    return StudentExamLatestResult(
      courseId: courseId,
      examId: examId,
      title: '',
      examType: 'quiz',
      hasAttempt: false,
      attemptId: null,
      inProgressAttemptId: inProgressAttemptId,
      attemptNumber: null,
      status: null,
      startedAt: null,
      submittedAt: null,
      timeSpentSeconds: null,
      scoreEarned: 0,
      totalScore: 0,
      percentageScore: null,
      isPassed: null,
      gradingPending: false,
      totalQuestions: 0,
      correctCount: 0,
      incorrectCount: 0,
      unansweredCount: 0,
      attemptsUsed: attemptsUsed,
      attemptsRemaining: 0,
      canStart: canStart,
      questions: const <StudentExamResultQuestion>[],
    );
  }

  factory StudentExamLatestResult.fromAttemptResult(
    Map<String, dynamic> json, {
    required int courseId,
    StudentExamAttemptSummary? summary,
    int attemptsUsed = 0,
  }) {
    final sections = _asResultSections(json['sections']);
    final questions = sections
        .expand((section) => section.questions)
        .toList(growable: false);

    final fallbackTotalScore = sections.fold<double>(0, (sum, section) => sum + section.sectionScore);
    final totalScore = _asNullableDouble(json['total_score']) ??
        summary?.totalScore ??
        (fallbackTotalScore > 0
            ? fallbackTotalScore
            : questions.fold<double>(0, (sum, question) => sum + question.points));

    final status = _asString(json['status']).isEmpty ? summary?.status : _asString(json['status']);
    final normalizedStatus = (status ?? '').trim().toLowerCase();
    final isFullyGraded = _asBool(json['is_fully_graded'], fallback: normalizedStatus == 'graded');
    final hasPendingAiQuestions = questions.any((question) => question.isAiGradingPending);
    final gradingPending = !isFullyGraded || normalizedStatus == 'submitted' || hasPendingAiQuestions;

    final computedScoreEarned = questions.fold<double>(0, (sum, question) => sum + question.pointsEarned);
    final scoreEarned = _asNullableDouble(json['earned_score']) ?? summary?.earnedScore ?? computedScoreEarned;
    final totalQuestions = questions.length;
    final correctCount = gradingPending
        ? questions.where((question) => question.isCorrectAnswer).length
        : (_asNullableInt(json['correct_count']) ?? questions.where((question) => question.isCorrectAnswer).length);
    final unansweredCount = _asNullableInt(json['unanswered_count']) ?? questions.where((question) => question.isUnanswered).length;
    final incorrectCount = gradingPending
        ? questions.where((question) => question.isIncorrectAnswer).length
        : (_asNullableInt(json['incorrect_count']) ?? questions.where((question) => question.isIncorrectAnswer).length);
    final percentageScore = _asNullableDouble(json['percentage_score']) ??
        (totalScore > 0 ? (scoreEarned / totalScore) * 100 : null);

    return StudentExamLatestResult(
      courseId: courseId,
      examId: _asInt(json['exam_id']),
      title: _asString(json['title']),
      examType: _asString(json['exam_type']).isEmpty ? 'quiz' : _asString(json['exam_type']),
      hasAttempt: true,
      attemptId: _asInt(json['attempt_id']),
      inProgressAttemptId: null,
      attemptNumber: _asInt(json['attempt_number'], fallback: summary?.attemptNumber ?? 1),
      status: status,
      startedAt: _asDate(json['started_at']) ?? summary?.startedAt,
      submittedAt: _asDate(json['submitted_at']) ?? summary?.submittedAt,
      timeSpentSeconds: _asNullableInt(json['time_spent_seconds']),
      scoreEarned: scoreEarned,
      totalScore: totalScore,
      percentageScore: percentageScore,
      isPassed: json.containsKey('is_passed') && json['is_passed'] != null
          ? _asBool(json['is_passed'])
          : summary?.isPassed,
      gradingPending: gradingPending,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unansweredCount: unansweredCount,
      attemptsUsed: attemptsUsed <= 0 ? 1 : attemptsUsed,
      attemptsRemaining: 0,
      canStart: true,
      questions: questions,
    );
  }

  factory StudentExamLatestResult.fromJson(Map<String, dynamic> json) {
    // Backward-compatible path for any old/custom latest-result shape.
    if (json['sections'] is List) {
      return StudentExamLatestResult.fromAttemptResult(json, courseId: _asInt(json['course_id']));
    }

    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => StudentExamResultQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <StudentExamResultQuestion>[];

    final scoreEarned = questions.isEmpty
        ? (_asNullableDouble(json['score_earned']) ?? 0)
        : questions.fold<double>(0, (sum, question) => sum + question.pointsEarned);
    final totalScore = _asNullableDouble(json['total_score']) ??
        questions.fold<double>(0, (sum, question) => sum + question.points);
    final correctCount = questions.isEmpty
        ? _asInt(json['correct_count'])
        : questions.where((question) => question.isCorrectAnswer).length;
    final unansweredCount = questions.isEmpty
        ? _asInt(json['unanswered_count'])
        : questions.where((question) => question.isUnanswered).length;
    final incorrectCount = questions.isEmpty
        ? _asInt(json['incorrect_count'])
        : questions.where((question) => question.isIncorrectAnswer).length;

    return StudentExamLatestResult(
      courseId: _asInt(json['course_id']),
      examId: _asInt(json['exam_id']),
      title: _asString(json['title']),
      examType: _asString(json['exam_type']).isEmpty ? 'quiz' : _asString(json['exam_type']),
      hasAttempt: _asBool(json['has_attempt']),
      attemptId: _asNullableInt(json['attempt_id']),
      inProgressAttemptId: _asNullableInt(json['in_progress_attempt_id']),
      attemptNumber: _asNullableInt(json['attempt_number']),
      status: _asString(json['status']).isEmpty ? null : _asString(json['status']),
      startedAt: _asDate(json['started_at']),
      submittedAt: _asDate(json['submitted_at']),
      timeSpentSeconds: _asNullableInt(json['time_spent_seconds']),
      scoreEarned: scoreEarned,
      totalScore: totalScore,
      percentageScore: totalScore > 0 ? (scoreEarned / totalScore) * 100 : _asNullableDouble(json['percentage_score']),
      isPassed: json.containsKey('is_passed') ? _asBool(json['is_passed']) : null,
      gradingPending: _asBool(json['grading_pending']),
      totalQuestions: _asInt(json['total_questions'], fallback: questions.length),
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unansweredCount: unansweredCount,
      attemptsUsed: _asInt(json['attempts_used']),
      attemptsRemaining: _asInt(json['attempts_remaining']),
      canStart: _asBool(json['can_start'], fallback: true),
      questions: questions,
    );
  }
}

class StudentExamResultSection {
  final int id;
  final String title;
  final int orderIndex;
  final double sectionScore;
  final List<StudentExamResultQuestion> questions;

  const StudentExamResultSection({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.sectionScore,
    required this.questions,
  });

  factory StudentExamResultSection.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => StudentExamResultQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <StudentExamResultQuestion>[];

    return StudentExamResultSection(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      orderIndex: _asInt(json['order_index']),
      sectionScore: _asNullableDouble(json['section_score']) ?? 0,
      questions: questions,
    );
  }
}

List<StudentExamResultSection> _asResultSections(dynamic value) {
  if (value is! List) return const <StudentExamResultSection>[];
  return value
      .whereType<Map>()
      .map((item) => StudentExamResultSection.fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

class StudentExamAnswerDetail {
  final int? selectedOptionIndex;
  final List<int>? selectedOptionIndices;
  final String? answerText;

  const StudentExamAnswerDetail({
    required this.selectedOptionIndex,
    required this.selectedOptionIndices,
    required this.answerText,
  });

  bool get isEmpty {
    return selectedOptionIndex == null &&
        (selectedOptionIndices == null || selectedOptionIndices!.isEmpty) &&
        (answerText ?? '').trim().isEmpty;
  }

  factory StudentExamAnswerDetail.fromJson(dynamic value) {
    if (value is! Map) {
      return const StudentExamAnswerDetail(
        selectedOptionIndex: null,
        selectedOptionIndices: null,
        answerText: null,
      );
    }
    final json = Map<String, dynamic>.from(value);
    return StudentExamAnswerDetail(
      selectedOptionIndex: _asNullableInt(json['selected_option_index']),
      selectedOptionIndices: _asIntList(json['selected_option_indices']),
      answerText: _asString(json['answer_text']).isEmpty ? null : _asString(json['answer_text']),
    );
  }
}

class StudentExamResultQuestion {
  final int examQuestionId;
  final int questionId;
  final int orderIndex;
  final double points;
  final double _backendPointsEarned;
  final String questionText;
  final String type;
  final String difficulty;
  final List<StudentExamQuestionOption> options;
  final StudentExamAnswerDetail studentAnswer;
  final dynamic rawCorrectAnswer;
  final bool? _backendIsCorrect;
  final String? explanation;
  final String? teacherFeedback;
  final int? timeTakenSeconds;

  const StudentExamResultQuestion({
    required this.examQuestionId,
    required this.questionId,
    required this.orderIndex,
    required this.points,
    required double backendPointsEarned,
    required this.questionText,
    required this.type,
    required this.difficulty,
    required this.options,
    required this.studentAnswer,
    required this.rawCorrectAnswer,
    required bool? backendIsCorrect,
    required this.explanation,
    required this.teacherFeedback,
    required this.timeTakenSeconds,
  })  : _backendPointsEarned = backendPointsEarned,
        _backendIsCorrect = backendIsCorrect;

  String get safeText => questionText.trim().isEmpty ? 'Question text is not available.' : questionText.trim();
  bool get isUnanswered => studentAnswer.isEmpty;

  String get normalizedType => type.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

  bool get isWrittenQuestion {
    final value = normalizedType;
    return value == 'short_answer' || value == 'essay' || value.contains('short_answer');
  }

  List<String> get selectedAnswerIds {
    if (studentAnswer.selectedOptionIndices != null && studentAnswer.selectedOptionIndices!.isNotEmpty) {
      return studentAnswer.selectedOptionIndices!
          .map(_optionIdAt)
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (studentAnswer.selectedOptionIndex != null) {
      final id = _optionIdAt(studentAnswer.selectedOptionIndex!);
      if (id.trim().isNotEmpty) return <String>[id];
    }
    return _answerIdsFromDynamic(studentAnswer.answerText);
  }

  List<String> get correctAnswerIds => _answerIdsFromDynamic(rawCorrectAnswer);

  bool get hasAiFeedback => (teacherFeedback ?? '').trim().isNotEmpty;

  bool get isAiGradingPending {
    if (!isWrittenQuestion || isUnanswered) return false;
    if (_backendPointsEarned > 0 || hasAiFeedback) return false;
    // Backend hides the expected answer for essay/short_answer while the
    // attempt is still only submitted and the AI callback has not finished.
    // Some DB schemas default is_correct to false, so correct_answer=null is
    // the reliable pending signal from the result endpoint.
    return rawCorrectAnswer == null;
  }

  bool? get computedIsCorrect {
    if (isUnanswered) return false;

    // Essay and short-answer questions are graded by the backend AI callback.
    // The callback sends points_earned + feedback; the backend stores
    // is_correct as points_earned > 0. Trust that contract and do not compare
    // prose with the model answer as exact text.
    if (isWrittenQuestion) {
      if (isAiGradingPending) return null;
      if (_backendPointsEarned > 0) return true;
      return _backendIsCorrect;
    }

    final selected = selectedAnswerIds.map(_answerCompareKey).where((item) => item.isNotEmpty).toList(growable: false);
    final correct = correctAnswerIds.map(_answerCompareKey).where((item) => item.isNotEmpty).toList(growable: false);
    if (selected.isEmpty || correct.isEmpty) return _backendIsCorrect;
    selected.sort();
    correct.sort();
    if (selected.length != correct.length) return false;
    for (var i = 0; i < selected.length; i++) {
      if (selected[i] != correct[i]) return false;
    }
    return true;
  }

  bool get isCorrectAnswer => computedIsCorrect == true;
  bool get isIncorrectAnswer => !isUnanswered && !isAiGradingPending && computedIsCorrect == false;

  double get pointsEarned {
    if (isWrittenQuestion) return _backendPointsEarned;

    final computed = computedIsCorrect;
    if (computed == true) return points;
    if (computed == false) return 0;
    return _backendPointsEarned;
  }

  bool? get isCorrect => computedIsCorrect;

  String? get selectedAnswerText {
    if (isWrittenQuestion) {
      final fallback = (studentAnswer.answerText ?? '').trim();
      return fallback.isEmpty ? null : fallback;
    }

    if (selectedAnswerIds.isNotEmpty) return selectedAnswerIds.map(_answerLabelForId).join(', ');
    final fallback = (studentAnswer.answerText ?? '').trim();
    return fallback.isEmpty ? null : fallback;
  }

  String? get correctAnswerText {
    if (isWrittenQuestion) {
      final fallback = _asString(rawCorrectAnswer).trim();
      return fallback.isEmpty ? null : fallback;
    }

    final ids = correctAnswerIds;
    if (ids.isNotEmpty) return ids.map(_answerLabelForId).join(', ');
    final fallback = _asString(rawCorrectAnswer).trim();
    return fallback.isEmpty ? null : fallback;
  }

  String _optionIdAt(int index) {
    if (index < 0 || index >= options.length) return '';
    return options[index].id.trim();
  }

  String _answerLabelForId(String rawId) {
    final id = rawId.trim();
    if (id.isEmpty) return '';
    for (final option in options) {
      if (_answerCompareKey(option.id) == _answerCompareKey(id)) {
        final displayId = option.id.trim().isEmpty ? id : option.id.trim();
        return '$displayId. ${option.text.trim()}';
      }
    }
    return id;
  }

  factory StudentExamResultQuestion.fromJson(Map<String, dynamic> json) {
    final backendIsCorrect = json.containsKey('is_correct') && json['is_correct'] != null
        ? _asBool(json['is_correct'])
        : null;
    return StudentExamResultQuestion(
      examQuestionId: _asInt(json['exam_question_id']),
      questionId: _asInt(json['question_id']),
      orderIndex: _asInt(json['order_index']),
      points: _asNullableDouble(json['points']) ?? 0,
      backendPointsEarned: _asNullableDouble(json['points_earned']) ?? 0,
      questionText: _asString(json['question_text']),
      type: _asString(json['type']).isEmpty ? 'question' : _asString(json['type']),
      difficulty: _asString(json['difficulty']).isEmpty ? 'medium' : _asString(json['difficulty']),
      options: _asExamOptions(json['options']),
      studentAnswer: StudentExamAnswerDetail.fromJson(json['student_answer']),
      rawCorrectAnswer: json['correct_answer'],
      backendIsCorrect: backendIsCorrect,
      explanation: _asString(json['explanation']).isEmpty ? null : _asString(json['explanation']),
      teacherFeedback: _asString(json['teacher_feedback']).isEmpty ? null : _asString(json['teacher_feedback']),
      timeTakenSeconds: _asNullableInt(json['time_taken_seconds']),
    );
  }
}

List<int>? _asIntList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map(_asNullableInt).whereType<int>().toList(growable: false);
  }
  if (value is String) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map(_asNullableInt).whereType<int>().toList(growable: false);
      }
    } catch (_) {
      // Fall through to comma-separated parsing.
    }
    return raw
        .split(',')
        .map((item) => _asNullableInt(item.trim()))
        .whereType<int>()
        .toList(growable: false);
  }
  return null;
}

List<String> _answerIdsFromDynamic(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value.map(_asString).map(_cleanAnswerId).where((item) => item.isNotEmpty).toList(growable: false);
  }
  final raw = _asString(value).trim();
  if (raw.isEmpty) return const <String>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map(_asString).map(_cleanAnswerId).where((item) => item.isNotEmpty).toList(growable: false);
    }
    if (decoded is String) {
      final item = _cleanAnswerId(decoded);
      return item.isEmpty ? const <String>[] : <String>[item];
    }
  } catch (_) {
    // Not JSON; parse it as a normal answer id.
  }
  if (raw.contains(',') && !raw.contains('.')) {
    return raw.split(',').map(_cleanAnswerId).where((item) => item.isNotEmpty).toList(growable: false);
  }
  final item = _cleanAnswerId(raw);
  return item.isEmpty ? const <String>[] : <String>[item];
}

String _cleanAnswerId(String value) {
  var output = value.trim();
  while (output.length >= 2 &&
      ((output.startsWith('"') && output.endsWith('"')) ||
          (output.startsWith("'") && output.endsWith("'")))) {
    output = output.substring(1, output.length - 1).trim();
  }
  return output;
}

String _answerCompareKey(String value) {
  return _cleanAnswerId(value).trim().toUpperCase();
}
