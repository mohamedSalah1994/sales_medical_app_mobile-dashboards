import 'package:equatable/equatable.dart';
import 'question_entity.dart';

class SurveyEntity extends Equatable {
  const SurveyEntity({
    this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.validFrom,
    required this.validTo,
    required this.questions,
    this.createdAt,
  });

  final String? id;
  final String name;
  final String description;
  final bool isActive;
  final DateTime validFrom;
  final DateTime validTo;
  final List<QuestionEntity> questions;
  final DateTime? createdAt;

  /// API [isActive] and current time within [validFrom]..[validTo] (inclusive).
  bool get isEffectiveActive {
    if (!isActive) return false;
    final now = DateTime.now();
    return !now.isBefore(validFrom) && !now.isAfter(validTo);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        validFrom,
        validTo,
        questions,
        createdAt,
      ];
}
