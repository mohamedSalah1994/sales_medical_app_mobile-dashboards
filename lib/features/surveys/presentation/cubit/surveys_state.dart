import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';

class SurveysState extends Equatable {
  const SurveysState({
    this.surveys = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.showCreateForm = false,
    this.editingSurvey,
    this.pageNumber = 1,
    this.pageSize = 20,
    this.hasMore = true,
  });

  final List<SurveyEntity> surveys;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final bool isSuccess;
  final bool showCreateForm;
  final SurveyEntity? editingSurvey;
  final int pageNumber;
  final int pageSize;
  final bool hasMore;

  SurveysState copyWith({
    List<SurveyEntity>? surveys,
    bool? isLoading,
    String? error,
    bool? clearError,
    bool? isSubmitting,
    bool? isSuccess,
    bool? showCreateForm,
    SurveyEntity? editingSurvey,
    int? pageNumber,
    int? pageSize,
    bool? hasMore,
  }) {
    return SurveysState(
      surveys: surveys ?? this.surveys,
      isLoading: isLoading ?? this.isLoading,
      error: clearError == true ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      showCreateForm: showCreateForm ?? this.showCreateForm,
      editingSurvey: editingSurvey,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        surveys,
        isLoading,
        error,
        isSubmitting,
        isSuccess,
        showCreateForm,
        editingSurvey,
        pageNumber,
        pageSize,
        hasMore,
      ];
}
