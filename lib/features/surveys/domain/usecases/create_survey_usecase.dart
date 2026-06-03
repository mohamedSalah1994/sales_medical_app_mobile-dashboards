
import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

class CreateSurveyUseCase implements UseCase<SurveyEntity, SurveyEntity> {
  CreateSurveyUseCase(this.repository);

  final SurveyRepository repository;

  @override
  Future<SurveyEntity> call(SurveyEntity params) {
    return repository.createSurvey(params);
  }
}
