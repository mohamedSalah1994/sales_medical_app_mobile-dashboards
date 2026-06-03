import 'package:equatable/equatable.dart';
import 'question_option_entity.dart';

enum QuestionType {
  freeText(1, 'Free Text'),
  multipleChoice(2, 'Multiple Choice');

  final int value;
  final String label;

  const QuestionType(this.value, this.label);

  static QuestionType fromValue(int value) {
    return QuestionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => QuestionType.freeText,
    );
  }
}

class QuestionEntity extends Equatable {
  const QuestionEntity({
    this.id,
    required this.questionText,
    required this.questionType,
    required this.displayOrder,
    required this.isRequired,
    this.options = const [],
    this.minAnswerLength,
  });

  final String? id;
  final String questionText;
  final QuestionType questionType;
  final int displayOrder;
  final bool isRequired;
  final List<QuestionOptionEntity> options;

  /// For [QuestionType.freeText]: minimum characters when set (>0). Null uses the app default on the response form.
  final int? minAnswerLength;

  @override
  List<Object?> get props => [
    id,
    questionText,
    questionType,
    displayOrder,
    isRequired,
    options,
    minAnswerLength,
  ];
}
