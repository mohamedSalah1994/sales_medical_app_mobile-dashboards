import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/question_model.dart';

class SurveyModel extends SurveyEntity {
  const SurveyModel({
    super.id,
    required super.name,
    required super.description,
    required super.isActive,
    required super.validFrom,
    required super.validTo,
    required super.questions,
    super.createdAt,
  });

  static DateTime _parseDate(dynamic v, DateTime fallback) {
    if (v is String) {
      return DateTime.tryParse(v) ?? fallback;
    }
    return fallback;
  }

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SurveyModel(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      validFrom: _parseDate(json['validFrom'], now),
      validTo: _parseDate(json['validTo'], now.add(const Duration(days: 365))),
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'questions':
          questions.map((e) {
            if (e is QuestionModel) {
              return e.toJson();
            }
            return {
              'questionText': e.questionText,
              'questionType': e.questionType.value,
              'displayOrder': e.displayOrder,
              'isRequired': e.isRequired,
              if (e.minAnswerLength != null) 'minCharacters': e.minAnswerLength,
              'options':
                  e.options.map((opt) {
                    return {
                      'optionText': opt.optionText,
                      'displayOrder': opt.displayOrder,
                    };
                  }).toList(),
            };
          }).toList(),
    };
  }
}
