part of '../instructor_presentation_page.dart';

class SlideTemplateRegistry {
  const SlideTemplateRegistry._();

  static const SlideTemplateBuilder _fallback = AdaptiveCardsTemplate();

  static const Map<String, SlideTemplateBuilder> _templates = {
    'title_slide': TitleSlideTemplate(),
    'lecture_objectives': LectureObjectivesTemplate(),
    'section_divider': SectionDividerTemplate(),
    'concept_explanation': ConceptExplanationTemplate(),
    'text_with_image': TextWithImageTemplate(),
    'full_image': FullImageTemplate(),
    'key_points': KeyPointsTemplate(),
    'comparison': ComparisonTemplate(),
    'process_steps': ProcessStepsTemplate(),
    'timeline': TimelineTemplate(),
    'diagram': DiagramTemplate(),
    'table': TableTemplate(),
    'equation_explanation': EquationExplanationTemplate(),
    'equation_derivation': EquationDerivationTemplate(),
    'worked_example': WorkedExampleTemplate(),
    'problem_solution': ProblemSolutionTemplate(),
    'multiple_choice': MultipleChoiceTemplate(),
    'practice_activity': PracticeActivityTemplate(),
    'case_study': CaseStudyTemplate(),
    'quote': QuoteTemplate(),
    'summary': SummaryTemplate(),
    'references': ReferencesTemplate(),
    'adaptive_cards': AdaptiveCardsTemplate(),
    'single_card_center': SingleCardCenterTemplate(),
    'two_card_horizontal': TwoCardHorizontalTemplate(),
    'three_card_horizontal': ThreeCardHorizontalTemplate(),
  };

  static List<PresentationElement> build(PresentationSlide slide) {
    return (_templates[slide.layoutType] ?? _fallback).build(slide);
  }
}
