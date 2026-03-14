// ─────────────────────────────────────────────────────────────────────────────
//  Topics — extended models with material context and instructor metadata
// ─────────────────────────────────────────────────────────────────────────────

enum TopicSource { ai, manual }

enum TopicDifficulty { beginner, intermediate, advanced }

enum TopicReadiness { draft, review, ready }

extension TopicDifficultyX on TopicDifficulty {
  String get label {
    switch (this) {
      case TopicDifficulty.beginner:
        return 'Beginner';
      case TopicDifficulty.intermediate:
        return 'Intermediate';
      case TopicDifficulty.advanced:
        return 'Advanced';
    }
  }

  static TopicDifficulty fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'intermediate':
        return TopicDifficulty.intermediate;
      case 'advanced':
        return TopicDifficulty.advanced;
      default:
        return TopicDifficulty.beginner;
    }
  }
}

extension TopicSourceX on TopicSource {
  String get label => this == TopicSource.ai ? 'AI' : 'Manual';

  static TopicSource fromString(String? s) {
    return (s ?? '').toLowerCase() == 'manual'
        ? TopicSource.manual
        : TopicSource.ai;
  }
}

extension TopicReadinessX on TopicReadiness {
  String get label {
    switch (this) {
      case TopicReadiness.draft:
        return 'Draft';
      case TopicReadiness.review:
        return 'Needs Review';
      case TopicReadiness.ready:
        return 'Ready';
    }
  }

  static TopicReadiness fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'ready':
        return TopicReadiness.ready;
      case 'review':
      case 'needs_review':
      case 'needs review':
        return TopicReadiness.review;
      default:
        return TopicReadiness.draft;
    }
  }
}

class TopicItem {
  final int id;
  final int moduleId;
  final int? materialId;
  final String title;
  final String? description;
  final int orderIndex;
  final int? parentTopicId;
  final int? estimatedDurationMinutes;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  final TopicSource source;
  final TopicDifficulty difficulty;

  /// Legacy single-link field kept for compatibility with older responses.
  final String? linkedOutcomeId;

  /// Current frontend mapping: a topic may align to multiple LOs.
  final List<String> linkedOutcomeIds;

  /// Instructor-authored planning notes for this topic.
  final String? instructorNotes;

  /// Readiness in the instructor workflow.
  final TopicReadiness readiness;

  const TopicItem({
    required this.id,
    required this.moduleId,
    this.materialId,
    required this.title,
    this.description,
    required this.orderIndex,
    this.parentTopicId,
    this.estimatedDurationMinutes,
    this.isRequired = true,
    required this.createdAt,
    required this.updatedAt,
    this.source = TopicSource.ai,
    this.difficulty = TopicDifficulty.beginner,
    this.linkedOutcomeId,
    this.linkedOutcomeIds = const [],
    this.instructorNotes,
    this.readiness = TopicReadiness.draft,
  });

  TopicItem copyWith({
    int? id,
    int? moduleId,
    int? materialId,
    String? title,
    String? description,
    int? orderIndex,
    int? parentTopicId,
    int? estimatedDurationMinutes,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
    TopicSource? source,
    TopicDifficulty? difficulty,
    String? linkedOutcomeId,
    List<String>? linkedOutcomeIds,
    String? instructorNotes,
    TopicReadiness? readiness,
  }) {
    return TopicItem(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      materialId: materialId ?? this.materialId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      parentTopicId: parentTopicId ?? this.parentTopicId,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      difficulty: difficulty ?? this.difficulty,
      linkedOutcomeId: linkedOutcomeId ?? this.linkedOutcomeId,
      linkedOutcomeIds: linkedOutcomeIds ?? this.linkedOutcomeIds,
      instructorNotes: instructorNotes ?? this.instructorNotes,
      readiness: readiness ?? this.readiness,
    );
  }

  factory TopicItem.fromJson(Map<String, dynamic> json) {
    DateTime dt(dynamic v) =>
        DateTime.tryParse((v ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final linkedIds = ((json['linked_outcome_ids'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final legacyLinked = json['linked_outcome_id']?.toString();
    if (linkedIds.isEmpty && legacyLinked != null && legacyLinked.trim().isNotEmpty) {
      linkedIds.add(legacyLinked.trim());
    }

    return TopicItem(
      id: (json['id'] as num).toInt(),
      moduleId: (json['module_id'] as num).toInt(),
      materialId: json['material_id'] == null
          ? null
          : (json['material_id'] as num).toInt(),
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
      source: TopicSourceX.fromString(json['source']?.toString()),
      difficulty: TopicDifficultyX.fromString(json['difficulty']?.toString()),
      linkedOutcomeId: legacyLinked,
      linkedOutcomeIds: linkedIds,
      instructorNotes: json['instructor_notes']?.toString(),
      readiness: TopicReadinessX.fromString(json['readiness']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        if (materialId != null) 'material_id': materialId,
        'title': title,
        if (description != null) 'description': description,
        'order_index': orderIndex,
        if (parentTopicId != null) 'parent_topic_id': parentTopicId,
        if (estimatedDurationMinutes != null)
          'estimated_duration_minutes': estimatedDurationMinutes,
        'is_required': isRequired,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'source': source.label.toLowerCase(),
        'difficulty': difficulty.label.toLowerCase(),
        if (linkedOutcomeId != null) 'linked_outcome_id': linkedOutcomeId,
        if (linkedOutcomeIds.isNotEmpty) 'linked_outcome_ids': linkedOutcomeIds,
        if (instructorNotes != null) 'instructor_notes': instructorNotes,
        'readiness': readiness.name,
      };
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

class TopicCreateRequest {
  final String title;
  final String? description;
  final TopicSource source;
  final TopicDifficulty difficulty;
  final String? linkedOutcomeId;
  final List<String> linkedOutcomeIds;

  const TopicCreateRequest({
    required this.title,
    this.description,
    this.source = TopicSource.manual,
    this.difficulty = TopicDifficulty.beginner,
    this.linkedOutcomeId,
    this.linkedOutcomeIds = const [],
  });

  Map<String, dynamic> toJson() {
    final outcomeIds = <String>{
      ...linkedOutcomeIds.where((e) => e.trim().isNotEmpty),
      if (linkedOutcomeId != null && linkedOutcomeId!.trim().isNotEmpty)
        linkedOutcomeId!.trim(),
    }.toList();

    final m = <String, dynamic>{
      'title': title,
      'source': source.label.toLowerCase(),
      'difficulty': difficulty.label.toLowerCase(),
    };
    if (description != null && description!.trim().isNotEmpty) {
      m['description'] = description;
    }
    if (linkedOutcomeId != null) m['linked_outcome_id'] = linkedOutcomeId;
    if (outcomeIds.isNotEmpty) m['linked_outcome_ids'] = outcomeIds;
    return m;
  }
}
