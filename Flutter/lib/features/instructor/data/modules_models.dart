// ─────────────────────────────────────────────────────────────────────────────
//  Modules — data models (mirrors backend schemas exactly)
// ─────────────────────────────────────────────────────────────────────────────

class ModuleItem {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final int orderIndex;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModuleItem({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
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
    );
  }
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
