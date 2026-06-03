import 'package:equatable/equatable.dart';

class QuestionOptionEntity extends Equatable {
  const QuestionOptionEntity({
    this.id,
    required this.optionText,
    required this.displayOrder,
  });

  final String? id;
  final String optionText;
  final int displayOrder;

  @override
  List<Object?> get props => [id, optionText, displayOrder];
}
