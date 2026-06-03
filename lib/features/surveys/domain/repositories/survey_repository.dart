import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_response_entities.dart';

abstract class SurveyRepository {
  Future<SurveyEntity> createSurvey(SurveyEntity survey);
  Future<List<SurveyEntity>> getSurveys({
    bool? isActive,
    int? pageNumber,
    int? pageSize,
  });
  Future<SurveyEntity> getSurveyById(String id);
  Future<void> submitSurveyResponse({
    required String visitId,
    required String surveyId,
    required List<Map<String, dynamic>> answers,
  });
  Future<SurveyResponsesLoadResult> getSurveyResponses({
    String? surveyId,
    String? visitId,
    String? userId,
    int? pageNumber,
    int? pageSize,
  });
  Future<SurveyResponseEntry> getSurveyResponseById(String id);
  Future<SurveyEntity> updateSurvey(String id, SurveyEntity survey);
}
