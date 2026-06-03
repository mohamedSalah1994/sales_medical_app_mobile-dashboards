import 'package:sales_medical_app_mobile/features/surveys/data/models/survey_model.dart';

class SurveysResponseModel {
  const SurveysResponseModel({
    required this.items,
    this.totalCount,
    this.pageNumber,
    this.pageSize,
  });

  final List<SurveyModel> items;
  final int? totalCount;
  final int? pageNumber;
  final int? pageSize;

  factory SurveysResponseModel.fromJson(Map<String, dynamic> json) {
    return SurveysResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SurveyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int?,
      pageNumber: json['pageNumber'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }
}
