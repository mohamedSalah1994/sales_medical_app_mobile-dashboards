import 'package:bloc/bloc.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/create_survey_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/get_surveys_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/update_survey_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_state.dart';


class SurveysCubit extends Cubit<SurveysState> {
  SurveysCubit({
    required GetSurveysUseCase getSurveysUseCase,
    required CreateSurveyUseCase createSurveyUseCase,
    required UpdateSurveyUseCase updateSurveyUseCase,
  })  : _getSurveysUseCase = getSurveysUseCase,
        _createSurveyUseCase = createSurveyUseCase,
        _updateSurveyUseCase = updateSurveyUseCase,
        super(const SurveysState());

  final GetSurveysUseCase _getSurveysUseCase;
  final CreateSurveyUseCase _createSurveyUseCase;
  final UpdateSurveyUseCase _updateSurveyUseCase;

  Future<void> loadSurveys({bool? isActive, bool loadMore = false}) async {
    if (state.isLoading) return;

    final pageNumber = loadMore ? state.pageNumber + 1 : 1;

    emit(state.copyWith(
      isLoading: true,
      error: null,
      pageNumber: pageNumber,
    ));

    try {
      final surveys = await _getSurveysUseCase.call(
        GetSurveysParams(
          isActive: isActive,
          pageNumber: pageNumber,
          pageSize: state.pageSize,
        ),
      );

      emit(state.copyWith(
        surveys: loadMore ? [...state.surveys, ...surveys] : surveys,
        isLoading: false,
        hasMore: surveys.length >= state.pageSize,
      ));
    } on ServerFailure catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void showCreateForm() {
    emit(state.copyWith(
      showCreateForm: true,
      editingSurvey: null,
      error: null,
    ));
  }

  void hideCreateForm() {
    emit(state.copyWith(
      showCreateForm: false,
      editingSurvey: null,
      error: null,
    ));
  }

  void startEditing(SurveyEntity survey) {
    emit(state.copyWith(
      showCreateForm: true,
      editingSurvey: survey,
      error: null,
    ));
  }

  Future<void> createOrUpdateSurvey(SurveyEntity survey) async {
    emit(state.copyWith(isSubmitting: true, error: null, isSuccess: false));

    try {
      SurveyEntity result;
      if (survey.id != null && survey.id!.isNotEmpty) {
        result = await _updateSurveyUseCase.call(
          UpdateSurveyParams(id: survey.id!, survey: survey),
        );
      } else {
        result = await _createSurveyUseCase.call(survey);
      }

      // Update the surveys list
      final updatedSurveys = List<SurveyEntity>.from(state.surveys);
      final index = updatedSurveys.indexWhere((s) => s.id == result.id);
      if (index != -1) {
        updatedSurveys[index] = result;
      } else {
        updatedSurveys.insert(0, result);
      }

      emit(state.copyWith(
        surveys: updatedSurveys,
        isSubmitting: false,
        isSuccess: true,
        showCreateForm: false,
        editingSurvey: null,
      ));
    } on ServerFailure catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }
}
