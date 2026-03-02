// ─────────────────────────────────────────────────────────────────────────────
//  Topics — data models (mirrors backend Topic table)
// ─────────────────────────────────────────────────────────────────────────────

class TopicItem {
  final int id;
  final int moduleId;
  final String title;
  final String? description;
  final int orderIndex;
  final int? parentTopicId;
  final int? estimatedDurationMinutes;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TopicItem({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    required this.orderIndex,
    this.parentTopicId,
    this.estimatedDurationMinutes,
    this.isRequired = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    DateTime dt(dynamic v) =>
        DateTime.tryParse((v ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return TopicItem(
      id: (json['id'] as num).toInt(),
      moduleId: (json['module_id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      parentTopicId: json['parent_topic_id'] == null
          ? null
          : (json['parent_topic_id'] as num).toInt(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] == null
          ? null
          : (json['estimated_duration_minutes'] as num).toInt(),
      isRequired: (json['is_required'] as bool?) ?? true,
      createdAt: dt(json['created_at']),
      updatedAt: dt(json['updated_at']),
    );
  }
}

class TopicListResponse {
  final int moduleId;
  final List<TopicItem> topics;

  const TopicListResponse({required this.moduleId, required this.topics});

  factory TopicListResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['topics'] as List?) ?? const [];
    return TopicListResponse(
      moduleId: (json['module_id'] as num).toInt(),
      topics: raw
          .whereType<Map>()
          .map((e) => TopicItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
