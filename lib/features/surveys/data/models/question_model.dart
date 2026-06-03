import 'package:sales_medical_app_mobile/features/surveys/domain/entities/question_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/question_option_model.dart';

class QuestionModel extends QuestionEntity {
  const QuestionModel({
    super.id,
    required super.questionText,
    required super.questionType,
    required super.displayOrder,
    required super.isRequired,
    super.options = const [],
    super.minAnswerLength,
  });

  static int _asInt(dynamic v, [int fallback = 1]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _parseMinAnswerLength(Map<String, dynamic> json) {
    const keys = [
      'minAnswerLength',
      'minLength',
      'minimumLength',
      'minCharacters',
    ];
    for (final key in keys) {
      final v = json[key];
      if (v == null) continue;
      final n = v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()));
      if (n != null && n > 0) return n.clamp(1, 2000);
    }
    return null;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString(),
      questionText: json['questionText']?.toString() ?? '',
      questionType: QuestionType.fromValue(_asInt(json['questionType'], 1)),
      displayOrder: _asInt(json['displayOrder'], 0),
      isRequired: json['isRequired'] as bool? ?? false,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      minAnswerLength: _parseMinAnswerLength(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'questionText': questionText,
      'questionType': questionType.value,
      'displayOrder': displayOrder,
      'isRequired': isRequired,
      if (minAnswerLength != null) 'minCharacters': minAnswerLength,
      'options':
          options.map((e) {
            if (e is QuestionOptionModel) {
              return e.toJson();
            }
            return {'optionText': e.optionText, 'displayOrder': e.displayOrder};
          }).toList(),
    };
  }
}
