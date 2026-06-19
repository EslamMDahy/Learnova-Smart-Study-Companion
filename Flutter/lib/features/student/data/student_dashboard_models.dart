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

String? _extractCoverUrl(Map<String, dynamic> json) {
  final direct = _firstNonEmptyString([
    json['cover_url'],
    json['coverUrl'],
    json['cover_image_url'],
    json['coverImageUrl'],
    json['image_url'],
    json['imageUrl'],
    json['thumbnail_url'],
    json['thumbnailUrl'],
    json['banner_url'],
    json['bannerUrl'],
  ]);
  if (direct != null) return direct;

  for (final key in const ['cover', 'cover_image', 'image', 'thumbnail', 'banner']) {
    final nested = json[key];
    if (nested is Map) {
      final nestedUrl = _firstNonEmptyString([
        nested['url'],
        nested['public_url'],
        nested['publicUrl'],
        nested['cover_url'],
        nested['image_url'],
      ]);
      if (nestedUrl != null) return nestedUrl;
    }
  }

  return null;
}

String? _extractInstructorName(Map<String, dynamic> json) {
  final direct = _firstNonEmptyString([
    json['instructor_name'],
    json['instructorName'],
    json['teacher_name'],
    json['teacherName'],
    json['owner_name'],
    json['ownerName'],
    json['created_by_name'],
    json['createdByName'],
  ]);
  if (direct != null) return direct;

  for (final key in const ['instructor', 'teacher', 'owner', 'creator', 'created_by_user']) {
    final nested = json[key];
    if (nested is Map) {
      final nestedName = _firstNonEmptyString([
        nested['full_name'],
        nested['fullName'],
        nested['name'],
        nested['display_name'],
        nested['displayName'],
        nested['email'],
      ]);
      if (nestedName != null) return nestedName;
    }
  }

  return null;
}

String? _extractInstructorAvatarUrl(Map<String, dynamic> json) {
  final direct = _firstNonEmptyString([
    json['instructor_avatar_url'],
    json['instructorAvatarUrl'],
    json['teacher_avatar_url'],
    json['teacherAvatarUrl'],
    json['owner_avatar_url'],
    json['ownerAvatarUrl'],
    json['avatar_url'],
    json['avatarUrl'],
  ]);
  if (direct != null) return direct;

  for (final key in const ['instructor', 'teacher', 'owner', 'creator', 'created_by_user']) {
    final nested = json[key];
    if (nested is Map) {
      final nestedUrl = _firstNonEmptyString([
        nested['avatar_url'],
        nested['avatarUrl'],
        nested['photo_url'],
        nested['photoUrl'],
        nested['image_url'],
        nested['imageUrl'],
      ]);
      if (nestedUrl != null) return nestedUrl;
    }
  }

  return null;
}

class StudentDashboardCourse {
  final int id;
  final String title;
  final String? courseCode;
  final String? category;
  final String? coverImageUrl;
  final String? instructorName;
  final String? instructorAvatarUrl;
  final String status;
  final String courseType;
  final int createdBy;
  final int? enrollmentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentDashboardCourse({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.category,
    required this.coverImageUrl,
    required this.instructorName,
    required this.instructorAvatarUrl,
    required this.status,
    required this.courseType,
    required this.createdBy,
    required this.enrollmentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  String get safeTitle => title.isEmpty ? 'Untitled course' : title;
  String get safeCode {
    final code = (courseCode ?? '').trim();
    return code.isEmpty ? 'COURSE-$id' : code;
  }

  String get safeCategory {
    final value = (category ?? '').trim();
    return value.isEmpty ? 'General' : value;
  }

  String get safeInstructorName {
    final value = (instructorName ?? '').trim();
    return value.isEmpty ? 'Course instructor' : value;
  }

  bool get isActive {
    final normalized = status.toLowerCase();
    return normalized == 'published' || normalized == 'active';
  }

  factory StudentDashboardCourse.fromJson(Map<String, dynamic> json) {
    return StudentDashboardCourse(
      id: _asInt(json['id']),
      title: _asString(json['title']),
      courseCode: _asString(json['course_code']).isEmpty
          ? null
          : _asString(json['course_code']),
      category: _asString(json['category']).isEmpty
          ? null
          : _asString(json['category']),
      coverImageUrl: _extractCoverUrl(json),
      instructorName: _extractInstructorName(json),
      instructorAvatarUrl: _extractInstructorAvatarUrl(json),
      status: _asString(json['status']).isEmpty ? 'unknown' : _asString(json['status']),
      courseType: _asString(json['course_type']).isEmpty
          ? 'individual'
          : _asString(json['course_type']),
      createdBy: _asInt(json['created_by']),
      enrollmentCount: _asNullableInt(json['enrollment_count']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }
}

class StudentDashboardExam {
  final int id;
  final int courseId;
  final String courseTitle;
  final String courseCode;
  final String title;
  final String? description;
  final String examType;
  final int? durationMinutes;
  final int maxAttempts;
  final double? passingScore;
  final int totalQuestions;
  final double totalScore;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isAvailable;

  const StudentDashboardExam({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.examType,
    required this.durationMinutes,
    required this.maxAttempts,
    required this.passingScore,
    required this.totalQuestions,
    required this.totalScore,
    required this.availableFrom,
    required this.availableTo,
    required this.isAvailable,
  });

  DateTime? get deadline => availableTo ?? availableFrom;

  bool get hasDeadline => deadline != null;

  bool get isUpcoming {
    final due = deadline;
    if (due == null) return false;
    return due.isAfter(DateTime.now());
  }

  String get safeTitle => title.trim().isEmpty ? 'Untitled exam' : title.trim();
  String get safeType => examType.trim().isEmpty ? 'exam' : examType.trim();

  factory StudentDashboardExam.fromJson(
    Map<String, dynamic> json, {
    required StudentDashboardCourse course,
  }) {
    return StudentDashboardExam(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id'], fallback: course.id),
      courseTitle: course.safeTitle,
      courseCode: course.safeCode,
      title: _asString(json['title']),
      description: _asString(json['description']).isEmpty
          ? null
          : _asString(json['description']),
      examType: _asString(json['exam_type']).isEmpty ? 'exam' : _asString(json['exam_type']),
      durationMinutes: _asNullableInt(json['duration_minutes']),
      maxAttempts: _asInt(json['max_attempts'], fallback: 1),
      passingScore: _asNullableDouble(json['passing_score']),
      totalQuestions: _asInt(json['total_questions']),
      totalScore: _asNullableDouble(json['total_score']) ?? 0,
      availableFrom: _asDate(json['available_from']),
      availableTo: _asDate(json['available_to']),
      isAvailable: _asBool(json['is_available']),
    );
  }
}

class StudentDashboardData {
  final List<StudentDashboardCourse> courses;
  final List<StudentDashboardExam> exams;
  final int failedExamCourseLoads;

  const StudentDashboardData({
    required this.courses,
    required this.exams,
    required this.failedExamCourseLoads,
  });

  int get activeCoursesCount => courses.where((course) => course.isActive).length;

  int get totalPublishedExams => exams.length;

  int get totalQuestionCount => exams.fold<int>(
        0,
        (total, exam) => total + exam.totalQuestions,
      );

  List<StudentDashboardExam> get availableExams {
    final items = exams.where((exam) => exam.isAvailable).toList();
    items.sort((a, b) => _compareNullableDates(a.deadline, b.deadline));
    return items;
  }

  List<StudentDashboardExam> get upcomingExams {
    final now = DateTime.now();
    final items = exams.where((exam) {
      final deadline = exam.deadline;
      return deadline != null && deadline.isAfter(now);
    }).toList();
    items.sort((a, b) => _compareNullableDates(a.deadline, b.deadline));
    return items;
  }

  List<StudentDashboardExam> get deadlineExams {
    final items = exams.where((exam) => exam.deadline != null).toList();
    items.sort((a, b) => _compareNullableDates(a.deadline, b.deadline));
    return items;
  }

  List<StudentDashboardExam> get recentlyClosedExams {
    final now = DateTime.now();
    final items = exams.where((exam) {
      final deadline = exam.deadline;
      return deadline != null && deadline.isBefore(now);
    }).toList();
    items.sort((a, b) => _compareNullableDates(b.deadline, a.deadline));
    return items;
  }
}

int _compareNullableDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
