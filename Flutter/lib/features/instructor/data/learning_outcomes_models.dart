// ─────────────────────────────────────────────────────────────────────────────
//  Learning Outcomes — assessment-criteria backend model
//
//  Backend shape:
//    LO group:  title, description?, parent_learning_outcome_id=null, level=null
//    Criterion: title, description?, parent_learning_outcome_id=<LO id>,
//               level in {foundational, intermediate, advanced}
//
//  UI wording uses LO + Pass / Merit / Distinction criteria.
//  Backend enum values remain foundational / intermediate / advanced.
// ─────────────────────────────────────────────────────────────────────────────

enum OutcomeDifficulty { beginner, intermediate, advanced }

extension OutcomeDifficultyX on OutcomeDifficulty {
  String get label {
    switch (this) {
      case OutcomeDifficulty.beginner:
        return 'Pass';
      case OutcomeDifficulty.intermediate:
        return 'Merit';
      case OutcomeDifficulty.advanced:
        return 'Distinction';
    }
  }

  String get shortLabel {
    switch (this) {
      case OutcomeDifficulty.beginner:
        return 'P';
      case OutcomeDifficulty.intermediate:
        return 'M';
      case OutcomeDifficulty.advanced:
        return 'D';
    }
  }

  String get arabicLabel {
    switch (this) {
      case OutcomeDifficulty.beginner:
        return 'Pass';
      case OutcomeDifficulty.intermediate:
        return 'Merit';
      case OutcomeDifficulty.advanced:
        return 'Distinction';
    }
  }

  /// Backend enum value.
  String get backendLevel {
    switch (this) {
      case OutcomeDifficulty.beginner:
        return 'foundational';
      case OutcomeDifficulty.intermediate:
        return 'intermediate';
      case OutcomeDifficulty.advanced:
        return 'advanced';
    }
  }

  static OutcomeDifficulty fromString(String? s) {
    switch ((s ?? '').trim().toLowerCase()) {
      case 'foundational':
      case 'beginner':
      case 'easy':
      case 'pass':
      case 'p':
      case 'سهل':
        return OutcomeDifficulty.beginner;
      case 'intermediate':
      case 'medium':
      case 'merit':
      case 'm':
      case 'متوسط':
        return OutcomeDifficulty.intermediate;
      case 'advanced':
      case 'hard':
      case 'distinction':
      case 'd':
      case 'صعب':
        return OutcomeDifficulty.advanced;
      default:
        return OutcomeDifficulty.beginner;
    }
  }
}

class LearningOutcome {
  final int id;
  final int? courseId;
  final String title;
  final String? description;
  final String? level;
  final int? parentLearningOutcomeId;
  final bool isAiGenerated;
  final bool isReviewed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // UI-only helpers.
  final String code;
  final OutcomeDifficulty difficulty;

  const LearningOutcome({
    required this.id,
    this.courseId,
    required this.title,
    this.description,
    this.level,
    this.parentLearningOutcomeId,
    this.isAiGenerated = false,
    this.isReviewed = false,
    this.createdAt,
    this.updatedAt,
    this.code = '',
    this.difficulty = OutcomeDifficulty.beginner,
  });

  bool get isParentOutcome => parentLearningOutcomeId == null;
  bool get isSubOutcome => parentLearningOutcomeId != null;

  /// Safe non-null value for UI/cache usage. Parent LOs still send null to the
  /// backend because the current create/update services reject parent levels.
  String get backendSafeLevel => normalizeBackendLevel(level, fallback: difficulty);

  static String normalizeBackendLevel(
    String? value, {
    OutcomeDifficulty fallback = OutcomeDifficulty.beginner,
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback.backendLevel;
    return OutcomeDifficultyX.fromString(trimmed).backendLevel;
  }

  LearningOutcome copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    Object? level = _sentinel,
    Object? parentLearningOutcomeId = _sentinel,
    bool? isAiGenerated,
    bool? isReviewed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? code,
    OutcomeDifficulty? difficulty,
  }) {
    return LearningOutcome(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      level: identical(level, _sentinel) ? this.level : level as String?,
      parentLearningOutcomeId: identical(parentLearningOutcomeId, _sentinel)
          ? this.parentLearningOutcomeId
          : parentLearningOutcomeId as int?,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isReviewed: isReviewed ?? this.isReviewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      code: code ?? this.code,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toCreateJson({List<int>? topicIds}) {
    final m = <String, dynamic>{
      'title': title.trim(),
      // Backend service currently requires the level key, but rejects a
      // non-null level for parent LOs.
      'level': parentLearningOutcomeId == null ? null : backendSafeLevel,
    };
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) m['description'] = desc;

    if (parentLearningOutcomeId != null) {
      m['parent_learning_outcome_id'] = parentLearningOutcomeId;
    }

    if (topicIds != null && topicIds.isNotEmpty) m['topic_ids'] = topicIds;
    return m;
  }

  Map<String, dynamic> toUpdateJson({List<int>? topicIds}) {
    final m = <String, dynamic>{'title': title.trim()};
    if (description != null) m['description'] = description!.trim();
    if (parentLearningOutcomeId != null) {
      m['level'] = backendSafeLevel;
      m['parent_learning_outcome_id'] = parentLearningOutcomeId;
    }
    if (topicIds != null) m['topic_ids'] = topicIds;
    return m;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        // Keep parent LO level as null. The FastAPI create/update service
        // distinguishes parent rows by parent_learning_outcome_id == null and
        // requires level to be null for those rows.
        'level': level,
        'parent_learning_outcome_id': parentLearningOutcomeId,
        'is_ai_generated': isAiGenerated,
        'is_reviewed': isReviewed,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'code': code,
      };

  factory LearningOutcome.fromJson(Map<String, dynamic> json) {
    int? intOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString().trim());
    }

    final rawId = json['id'];
    final id = intOrNull(rawId) ?? 0;
    final rawLevel = json['level']?.toString();
    final parentId = intOrNull(json['parent_learning_outcome_id']);
    final difficulty = OutcomeDifficultyX.fromString(rawLevel);
    // Do not synthesize a backend level for parent LOs. The uploaded FastAPI
    // service requires parent rows to keep level == null, while child criteria
    // must carry one of the enum values.
    final level = parentId == null && (rawLevel == null || rawLevel.trim().isEmpty)
        ? null
        : normalizeBackendLevel(rawLevel, fallback: difficulty);

    return LearningOutcome(
      id: id,
      courseId: intOrNull(json['course_id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      level: level,
      parentLearningOutcomeId: parentId,
      isAiGenerated: (json['is_ai_generated'] as bool?) ?? false,
      isReviewed: (json['is_reviewed'] as bool?) ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      code: json['code']?.toString() ?? '',
      difficulty: difficulty,
    );
  }

  static String codeForIndex(int idx) => 'LO${idx + 1}';
  static String subCodeForIndex(String parentCode, OutcomeDifficulty difficulty, int idx) {
    // The level is shown visually by its P / M / D badge and by the column
    // header, so criterion chips do not repeat Pass / Merit / Distinction.
    return '${idx + 1}';
  }
}


class LearningOutcomeTitleConflictException implements Exception {
  final String attemptedTitle;
  final LearningOutcome existing;

  const LearningOutcomeTitleConflictException({
    required this.attemptedTitle,
    required this.existing,
  });

  @override
  String toString() => 'Learning outcome title already exists: $attemptedTitle';
}

const Object _sentinel = Object();

class LearningOutcomeListResponse {
  final int courseId;
  final List<LearningOutcome> outcomes;

  const LearningOutcomeListResponse({
    required this.courseId,
    required this.outcomes,
  });

  factory LearningOutcomeListResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['learning_outcomes'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => LearningOutcome.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return LearningOutcomeListResponse(
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      outcomes: assignLearningOutcomeCodes(items),
    );
  }
}

List<LearningOutcome> assignLearningOutcomeCodes(List<LearningOutcome> input) {
  final items = [...input];
  items.sort((a, b) {
    final parentCompare = (a.parentLearningOutcomeId ?? a.id)
        .compareTo(b.parentLearningOutcomeId ?? b.id);
    if (parentCompare != 0) return parentCompare;
    return a.id.compareTo(b.id);
  });

  final parents = items.where((o) => o.isParentOutcome).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final parentCodes = <int, String>{};
  final coded = <LearningOutcome>[];

  for (var i = 0; i < parents.length; i++) {
    final code = LearningOutcome.codeForIndex(i);
    parentCodes[parents[i].id] = code;
    coded.add(parents[i].copyWith(code: code));
  }

  for (final parent in parents) {
    final parentCode = parentCodes[parent.id] ?? 'LO${parent.id}';
    for (final difficulty in OutcomeDifficulty.values) {
      final children = items
          .where((o) => o.parentLearningOutcomeId == parent.id && o.difficulty == difficulty)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      for (var i = 0; i < children.length; i++) {
        coded.add(children[i].copyWith(
          code: LearningOutcome.subCodeForIndex(parentCode, difficulty, i),
        ));
      }
    }
  }

  final parentIds = parentCodes.keys.toSet();
  final orphans = items
      .where((o) => o.isSubOutcome && !parentIds.contains(o.parentLearningOutcomeId))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final orphan in orphans) {
    coded.add(orphan.copyWith(code: orphan.code.isNotEmpty ? orphan.code : 'SLO${orphan.id}'));
  }

  return coded;
}

Map<int, List<LearningOutcome>> groupSubOutcomesByParent(List<LearningOutcome> outcomes) {
  final grouped = <int, List<LearningOutcome>>{};
  for (final outcome in outcomes) {
    final parentId = outcome.parentLearningOutcomeId;
    if (parentId == null) continue;
    grouped.putIfAbsent(parentId, () => <LearningOutcome>[]).add(outcome);
  }
  for (final list in grouped.values) {
    list.sort((a, b) {
      final levelCompare = a.difficulty.index.compareTo(b.difficulty.index);
      if (levelCompare != 0) return levelCompare;
      return a.id.compareTo(b.id);
    });
  }
  return grouped;
}
