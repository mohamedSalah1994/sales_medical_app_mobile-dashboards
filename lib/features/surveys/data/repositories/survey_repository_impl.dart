import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/datasources/survey_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/survey_model.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/survey_response_models.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_response_entities.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl({required this.remoteDataSource});

  final SurveyRemoteDataSource remoteDataSource;

  @override
  Future<SurveyEntity> createSurvey(SurveyEntity survey) async {
    try {
      final surveyModel = SurveyModel(
        id: survey.id,
        name: survey.name,
        description: survey.description,
        isActive: survey.isActive,
        validFrom: survey.validFrom,
        validTo: survey.validTo,
        questions: survey.questions,
        createdAt: survey.createdAt,
      );
      final result = await remoteDataSource.createSurvey(surveyModel);
      return result;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<SurveyEntity>> getSurveys({
    bool? isActive,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final response = await remoteDataSource.getSurveys(
        isActive: isActive,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return response.items;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  SurveyResponseEntry _mapResponse(SurveyResponseSummaryModel m) {
    return SurveyResponseEntry(
      id: m.id,
      visitId: m.visitId,
      surveyId: m.surveyId,
      surveyName: m.surveyName,
      userId: m.userId,
      userName: m.userName,
      submittedAt: m.submittedAt,
      answers:
          m.answers
              .where((a) => a.questionId.isNotEmpty)
              .map(
                (a) => SurveyResponseAnswer(
                  id: a.id,
                  questionId: a.questionId,
                  answerText: a.answerText,
                  selectedOptionId: a.selectedOptionId,
                  selectedOptionText: a.selectedOptionText,
                  numericValue: a.numericValue,
                ),
              )
              .toList(),
    );
  }

  @override
  Future<SurveyEntity> getSurveyById(String id) async {
    try {
      return await remoteDataSource.getSurveyById(id);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> submitSurveyResponse({
    required String visitId,
    required String surveyId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      await remoteDataSource.submitSurveyResponse(
        visitId: visitId,
        surveyId: surveyId,
        answers: answers,
      );
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyResponsesLoadResult> getSurveyResponses({
    String? surveyId,
    String? visitId,
    String? userId,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final result = await remoteDataSource.getSurveyResponses(
        surveyId: surveyId,
        visitId: visitId,
        userId: userId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return SurveyResponsesLoadResult(
        items: result.items.map(_mapResponse).toList(),
        totalCount: result.totalCount,
      );
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyResponseEntry> getSurveyResponseById(String id) async {
    try {
      final m = await remoteDataSource.getSurveyResponseById(id);
      return _mapResponse(m);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyEntity> updateSurvey(String id, SurveyEntity survey) async {
    try {
      final surveyModel = SurveyModel(
        id: survey.id,
        name: survey.name,
        description: survey.description,
        isActive: survey.isActive,
        validFrom: survey.validFrom,
        validTo: survey.validTo,
        questions: survey.questions,
        createdAt: survey.createdAt,
      );
      final result = await remoteDataSource.updateSurvey(id, surveyModel);
      return result;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
