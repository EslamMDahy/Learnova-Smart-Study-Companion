// ─────────────────────────────────────────────────────────────────────────────
//  Modules — data models (updated to support sharing across courses)
// ─────────────────────────────────────────────────────────────────────────────

class ModuleItem {
  final int id;
  final int courseId; // primary course this module belongs to
  final String title;
  final String? description;
  final int orderIndex;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New: a module may be linked to multiple courses
  final List<int> sharedWithCourseIds;

  const ModuleItem({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.sharedWithCourseIds = const [],
  });

  ModuleItem copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    int? orderIndex,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? sharedWithCourseIds,
  }) {
    return ModuleItem(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sharedWithCourseIds: sharedWithCourseIds ?? this.sharedWithCourseIds,
    );
  }

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    final shared = (json['shared_with_course_ids'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [];
    return ModuleItem(
      id: (json['id'] as num).toInt(),
      courseId: (json['course_id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      isPublished: (json['is_published'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sharedWithCourseIds: shared,
    );
  }

  /// Whether this module is shared (used in multiple courses)
  bool get isShared => sharedWithCourseIds.isNotEmpty;
}

class ModuleListResponse {
  final int courseId;
  final List<ModuleItem> modules;

  const ModuleListResponse({required this.courseId, required this.modules});

  factory ModuleListResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['modules'] as List?) ?? const [];
    return ModuleListResponse(
      courseId: (json['course_id'] as num).toInt(),
      modules: raw
          .whereType<Map>()
          .map((e) => ModuleItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ModuleCreateRequest {
  final String title;
  final String? description;

  const ModuleCreateRequest({required this.title, this.description});

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'title': title};
    if (description != null && description!.trim().isNotEmpty) {
      m['description'] = description;
    }
    return m;
  }
}

/// Request to link an existing module to another course
class ModuleLinkRequest {
  final int moduleId;
  final int targetCourseId;

  const ModuleLinkRequest({required this.moduleId, required this.targetCourseId});

  Map<String, dynamic> toJson() => {
        'module_id': moduleId,
        'target_course_id': targetCourseId,
      };
}
