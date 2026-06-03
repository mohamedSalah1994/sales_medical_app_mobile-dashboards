import 'package:sales_medical_app_mobile/features/surveys/domain/entities/question_option_entity.dart';

class QuestionOptionModel extends QuestionOptionEntity {
  const QuestionOptionModel({
    super.id,
    required super.optionText,
    required super.displayOrder,
  });

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id']?.toString(),
      optionText: json['optionText']?.toString() ?? '',
      displayOrder: _asInt(json['displayOrder'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'optionText': optionText,
      'displayOrder': displayOrder,
    };
  }
}
