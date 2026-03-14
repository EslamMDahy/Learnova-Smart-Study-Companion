// ─────────────────────────────────────────────────────────────────────────────
//  Learning Outcomes — data models (with difficulty)
// ─────────────────────────────────────────────────────────────────────────────

enum OutcomeDifficulty { beginner, intermediate, advanced }

extension OutcomeDifficultyX on OutcomeDifficulty {
  String get label {
    switch (this) {
      case OutcomeDifficulty.beginner:     return 'Beginner';
      case OutcomeDifficulty.intermediate: return 'Intermediate';
      case OutcomeDifficulty.advanced:     return 'Advanced';
    }
  }
  static OutcomeDifficulty fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'intermediate': return OutcomeDifficulty.intermediate;
      case 'advanced':     return OutcomeDifficulty.advanced;
      default:             return OutcomeDifficulty.beginner;
    }
  }
}

class LearningOutcome {
  final String id;
  final String code;        // e.g. "LO1"
  final String description;
  final OutcomeDifficulty difficulty;

  const LearningOutcome({
    required this.id,
    required this.code,
    required this.description,
    this.difficulty = OutcomeDifficulty.beginner,
  });

  LearningOutcome copyWith({
    String? id,
    String? code,
    String? description,
    OutcomeDifficulty? difficulty,
  }) => LearningOutcome(
    id: id ?? this.id,
    code: code ?? this.code,
    description: description ?? this.description,
    difficulty: difficulty ?? this.difficulty,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'difficulty': difficulty.label.toLowerCase(),
  };

  factory LearningOutcome.fromJson(Map<String, dynamic> json) => LearningOutcome(
    id: json['id']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    difficulty: OutcomeDifficultyX.fromString(json['difficulty']?.toString()),
  );

  static String codeForIndex(int idx) => 'LO${idx + 1}';
}
