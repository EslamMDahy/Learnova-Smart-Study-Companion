enum CourseType { individual, organization }

enum CourseVisibilityLevel { private, public, unlisted }

class MyCourseItem {
  final int id;
  final String title;
  final String? courseCode;
  final String courseType;
  final int? organizationId;
  final bool isPublic;
  final String visibilityLevel;
  final String status;

  final String? coverImageUrl;
  final String? bannerImageUrl;
  final String? category;

  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final int? enrollmentCount;
  final int? pendingInvites;

  const MyCourseItem({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.courseType,
    required this.organizationId,
    required this.isPublic,
    required this.visibilityLevel,
    required this.status,
    required this.coverImageUrl,
    required this.bannerImageUrl,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.enrollmentCount,
    required this.pendingInvites,
  });

  /// Helpers (UI-friendly)
  String get safeTitle => title.trim().isEmpty ? 'Untitled course' : title.trim();

  String get safeCourseCode {
    final v = (courseCode ?? '').trim();
    return v.isEmpty ? 'CS-$id' : v;
  }

  bool get isPrivate => visibilityLevel.trim().toLowerCase() == 'private';

  MyCourseItem copyWith({
    int? id,
    String? title,
    String? courseCode,
    String? courseType,
    int? organizationId,
    bool? isPublic,
    String? visibilityLevel,
    String? status,
    String? coverImageUrl,
    String? bannerImageUrl,
    String? category,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? enrollmentCount,
    int? pendingInvites,
  }) {
    return MyCourseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      courseType: courseType ?? this.courseType,
      organizationId: organizationId ?? this.organizationId,
      isPublic: isPublic ?? this.isPublic,
      visibilityLevel: visibilityLevel ?? this.visibilityLevel,
      status: status ?? this.status,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      category: category ?? this.category,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      pendingInvites: pendingInvites ?? this.pendingInvites,
    );
  }

  factory MyCourseItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString().trim();

    return MyCourseItem(
      id: (json['id'] as num).toInt(),
      title: s(json['title']),
      courseCode: s(json['course_code']).isEmpty ? null : s(json['course_code']),
      courseType: s(json['course_type']),
      organizationId: json['organization_id'] == null
          ? null
          : (json['organization_id'] as num).toInt(),
      isPublic: (json['is_public'] as bool?) ?? false,
      visibilityLevel: s(json['visibility_level']),
      status: s(json['status']),
      coverImageUrl: json['cover_image_url']?.toString(),
      bannerImageUrl: json['banner_image_url']?.toString(),
      category: json['category']?.toString(),
      createdBy: (json['created_by'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      enrollmentCount: json['enrollment_count'] == null
          ? null
          : (json['enrollment_count'] as num).toInt(),
      pendingInvites: json['pending_invites'] == null
          ? null
          : (json['pending_invites'] as num).toInt(),
    );
  }
}

class MyCoursesResponse {
  final List<MyCourseItem> items;
  final int total;

  const MyCoursesResponse({required this.items, required this.total});

  factory MyCoursesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map((e) => MyCourseItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return MyCoursesResponse(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

class CourseCreateRequest {
  final String courseType; // "individual" | "organization"
  final int? organizationId;

  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? bannerImageUrl;

  final bool isPublic;
  final String visibilityLevel; // "private" | "public" | "unlisted"
  final bool requiresEnrollmentApproval;

  final List<String>? learningOutcomes;
  final List<String>? tags;
  final String? category;

  
  final String? status; // "draft" | "published" | "archived"

  // UI-only fields (NOT sent to backend because backend schema forbids extra fields)
  final String? courseCode;
  final String? academicTerm;
  final String? localStatus;

  const CourseCreateRequest({
    required this.courseType,
    required this.organizationId,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.bannerImageUrl,
    required this.isPublic,
    required this.visibilityLevel,
    required this.requiresEnrollmentApproval,
    required this.learningOutcomes,
    required this.tags,
    required this.category,

    
    this.status,

    this.courseCode,
    this.academicTerm,
    this.localStatus,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'course_type': courseType,
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'banner_image_url': bannerImageUrl,
      'is_public': isPublic,
      'visibility_level': visibilityLevel,
      'requires_enrollment_approval': requiresEnrollmentApproval,
      'learning_outcomes': learningOutcomes,
      'tags': tags,
      'category': category,

      
      'status': status,

      
      'course_code': courseCode,
    };

    map.removeWhere((k, v) => v == null);
    return map;
  }
}