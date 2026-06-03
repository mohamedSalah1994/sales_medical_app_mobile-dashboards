

import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

class UpdateSurveyParams {
  const UpdateSurveyParams({
    required this.id,
    required this.survey,
  });

  final String id;
  final SurveyEntity survey;
}

class UpdateSurveyUseCase
    implements UseCase<SurveyEntity, UpdateSurveyParams> {
  UpdateSurveyUseCase(this.repository);

  final SurveyRepository repository;

  @override
  Future<SurveyEntity> call(UpdateSurveyParams params) {
    return repository.updateSurvey(params.id, params.survey);
  }
}
