class PresentationTargetSection {
  final int topicId;
  final String topicTitle;
  final int pageStart;
  final int pageEnd;

  const PresentationTargetSection({
    required this.topicId,
    required this.topicTitle,
    required this.pageStart,
    required this.pageEnd,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'topic_id': topicId,
        'topic_title': topicTitle,
        'page_start': pageStart,
        'page_end': pageEnd,
      };
}

class GeneratePresentationRequest {
  final int slideCount;
  final List<PresentationTargetSection> targetSections;

  const GeneratePresentationRequest({
    required this.slideCount,
    required this.targetSections,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'slide_count': slideCount,
        'target_sections': targetSections
            .map((PresentationTargetSection section) => section.toJson())
            .toList(),
      };
}

class GeneratePresentationResponse {
  final String status;

  const GeneratePresentationResponse({required this.status});

  bool get isProcessing => status.trim().toLowerCase() == 'processing';

  factory GeneratePresentationResponse.fromJson(Map<String, dynamic> json) {
    return GeneratePresentationResponse(
      status: (json['status'] ?? '').toString(),
    );
  }
}

class PresentationGenerationResult {
  final Map<String, dynamic> deckJson;

  const PresentationGenerationResult({required this.deckJson});

  factory PresentationGenerationResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? deck = _findDeck(json);
    if (deck == null) {
      throw const FormatException(
        'Presentation result does not contain a valid slides array.',
      );
    }
    return PresentationGenerationResult(deckJson: deck);
  }

  static Map<String, dynamic>? _findDeck(Map<String, dynamic> root) {
    if (root['slides'] is List) return Map<String, dynamic>.from(root);

    const wrapperKeys = <String>[
      'body',
      'data',
      'result',
      'response_payload',
      'payload',
    ];

    for (final String key in wrapperKeys) {
      final Object? value = root[key];
      if (value is Map) {
        final Map<String, dynamic>? nested = _findDeck(
          Map<String, dynamic>.from(value),
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }
}
