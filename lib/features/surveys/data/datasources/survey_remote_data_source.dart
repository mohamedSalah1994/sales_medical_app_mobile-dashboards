import 'package:dio/dio.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/survey_model.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/survey_response_models.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/models/surveys_response_model.dart';

abstract class SurveyRemoteDataSource {
  Future<SurveyModel> createSurvey(SurveyModel survey);
  Future<SurveysResponseModel> getSurveys({
    bool? isActive,
    int? pageNumber,
    int? pageSize,
  });
  Future<SurveyModel> getSurveyById(String id);
  Future<void> submitSurveyResponse({
    required String visitId,
    required String surveyId,
    required List<Map<String, dynamic>> answers,
  });
  Future<SurveyResponsesListResult> getSurveyResponses({
    String? surveyId,
    String? visitId,
    String? userId,
    int? pageNumber,
    int? pageSize,
  });
  Future<SurveyResponseSummaryModel> getSurveyResponseById(String id);
  Future<SurveyModel> updateSurvey(String id, SurveyModel survey);
}

class SurveyRemoteDataSourceImpl implements SurveyRemoteDataSource {
  SurveyRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<SurveyModel> createSurvey(SurveyModel survey) async {
    try {
      final response = await apiService.post(
        '/api/Surveys',
        data: survey.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('error')) {
          final errorMessage =
              data['error'] as String? ?? 'Failed to create survey';
          throw ServerFailure(message: errorMessage);
        }
        return SurveyModel.fromJson(data);
      }

      throw ServerFailure(message: 'Invalid response format');
    } on DioException catch (e) {
      String errorMessage = 'Failed to create survey';

      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['error']?.toString() ??
              errorData['message']?.toString() ??
              'Failed to create survey';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw ServerFailure(message: errorMessage);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveysResponseModel> getSurveys({
    bool? isActive,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'isActive': isActive ?? true,
      };
      if (pageNumber != null) {
        queryParameters['pageNumber'] = pageNumber;
      }
      if (pageSize != null) {
        queryParameters['pageSize'] = pageSize;
      }

      final response = await apiService.get(
        '/api/Surveys',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return SurveysResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw ServerFailure(message: 'Invalid response format');
    } on ApiHttpException catch (e) {
      throw ServerFailure(message: e.message);
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch surveys';

      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['error']?.toString() ??
              errorData['message']?.toString() ??
              'Failed to fetch surveys';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw ServerFailure(message: errorMessage);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyModel> getSurveyById(String id) async {
    try {
      final encoded = Uri.encodeComponent(id);
      final response = await apiService.get('/api/Surveys/$encoded');
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return SurveyModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerFailure(message: 'Failed to load survey');
    } on ApiHttpException catch (e) {
      throw ServerFailure(message: e.message);
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
      final response = await apiService.post(
        '/api/Surveys/responses',
        data: {
          'visitId': visitId,
          'surveyId': surveyId,
          'answers': answers,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerFailure(message: 'Failed to submit survey');
    } on ApiHttpException catch (e) {
      throw ServerFailure(message: e.message);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyResponsesListResult> getSurveyResponses({
    String? surveyId,
    String? visitId,
    String? userId,
    int? pageNumber,
    int? pageSize,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (surveyId != null && surveyId.isNotEmpty) {
        query['surveyId'] = surveyId;
      }
      if (visitId != null && visitId.isNotEmpty) {
        query['visitId'] = visitId;
      }
      if (userId != null && userId.isNotEmpty) {
        query['userId'] = userId;
      }
      if (pageNumber != null) {
        query['pageNumber'] = pageNumber;
      }
      if (pageSize != null) {
        query['pageSize'] = pageSize;
      }
      final response = await apiService.get(
        '/api/Surveys/responses',
        queryParameters: query.isEmpty ? null : query,
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return SurveyResponsesListResult.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerFailure(message: 'Failed to load survey responses');
    } on ApiHttpException catch (e) {
      throw ServerFailure(message: e.message);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyResponseSummaryModel> getSurveyResponseById(String id) async {
    try {
      final encoded = Uri.encodeComponent(id);
      final response = await apiService.get('/api/Surveys/responses/$encoded');
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return SurveyResponseSummaryModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw ServerFailure(message: 'Failed to load survey response');
    } on ApiHttpException catch (e) {
      throw ServerFailure(message: e.message);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SurveyModel> updateSurvey(String id, SurveyModel survey) async {
    try {
      final response = await apiService.put(
        '/api/Surveys/$id',
        data: survey.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('error')) {
          final errorMessage =
              data['error'] as String? ?? 'Failed to update survey';
          throw ServerFailure(message: errorMessage);
        }
        return SurveyModel.fromJson(data);
      }

      throw ServerFailure(message: 'Invalid response format');
    } on DioException catch (e) {
      String errorMessage = 'Failed to update survey';

      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['error']?.toString() ??
              errorData['message']?.toString() ??
              'Failed to update survey';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw ServerFailure(message: errorMessage);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
