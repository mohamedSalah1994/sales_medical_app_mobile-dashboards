
import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

class GetSurveysParams {
  const GetSurveysParams({
    this.isActive,
    this.pageNumber,
    this.pageSize,
  });

  final bool? isActive;
  final int? pageNumber;
  final int? pageSize;
}

class GetSurveysUseCase
    implements UseCase<List<SurveyEntity>, GetSurveysParams> {
  GetSurveysUseCase(this.repository);

  final SurveyRepository repository;

  @override
  Future<List<SurveyEntity>> call(GetSurveysParams params) {
    return repository.getSurveys(
      isActive: params.isActive,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
    );
  }
}
