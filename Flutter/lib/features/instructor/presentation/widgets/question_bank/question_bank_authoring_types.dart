part of 'question_bank_authoring_flow.dart';

enum _WorkspaceMode { manual, ai, review }
enum _WorkspaceExitAction { exit }

enum QuestionAuthoringScopeKind { module, material, topic, subtopic, selection }

class QuestionAuthoringLaunchContext {
  final QuestionAuthoringScopeKind kind;
  final String title;
  final String subtitle;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedTopicId;
  final Set<int> selectedModuleIds;
  final Set<int> selectedMaterialIds;
  final Set<int> selectedTopicIds;
  final List<add_question_sheet.QuestionAuthoringTarget> targetSnapshots;

  const QuestionAuthoringLaunchContext({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.selectedModuleId,
    this.selectedMaterialId,
    this.selectedTopicId,
    this.selectedModuleIds = const <int>{},
    this.selectedMaterialIds = const <int>{},
    this.selectedTopicIds = const <int>{},
    this.targetSnapshots = const <add_question_sheet.QuestionAuthoringTarget>[],
  });

  String get label {
    switch (kind) {
      case QuestionAuthoringScopeKind.module:
        return 'Module scope';
      case QuestionAuthoringScopeKind.material:
        return 'Material scope';
      case QuestionAuthoringScopeKind.topic:
        return 'Topic scope';
      case QuestionAuthoringScopeKind.subtopic:
        return 'Subtopic scope';
      case QuestionAuthoringScopeKind.selection:
        return 'Custom selection';
    }
  }
}
