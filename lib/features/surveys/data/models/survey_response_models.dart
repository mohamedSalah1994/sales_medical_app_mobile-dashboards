class SurveyResponseAnswerModel {
  const SurveyResponseAnswerModel({
    this.id,
    required this.questionId,
    this.answerText,
    this.selectedOptionId,
    this.selectedOptionText,
    this.numericValue,
  });

  final String? id;
  final String questionId;
  final String? answerText;
  final String? selectedOptionId;
  final String? selectedOptionText;
  final num? numericValue;

  factory SurveyResponseAnswerModel.fromJson(Map<String, dynamic> json) {
    return SurveyResponseAnswerModel(
      id: json['id']?.toString(),
      questionId: json['questionId']?.toString() ?? '',
      answerText: json['answerText'] as String?,
      selectedOptionId: json['selectedOptionId'] as String?,
      selectedOptionText: json['selectedOptionText'] as String?,
      numericValue: json['numericValue'] as num?,
    );
  }
}

class SurveyResponseSummaryModel {
  const SurveyResponseSummaryModel({
    required this.id,
    required this.visitId,
    required this.surveyId,
    required this.surveyName,
    this.userId,
    this.userName,
    this.submittedAt,
    this.answers = const [],
  });

  final String id;
  final String visitId;
  final String surveyId;
  final String surveyName;
  final String? userId;
  final String? userName;
  final DateTime? submittedAt;
  final List<SurveyResponseAnswerModel> answers;

  factory SurveyResponseSummaryModel.fromJson(Map<String, dynamic> json) {
    final submitted = json['submittedAt'] as String?;
    return SurveyResponseSummaryModel(
      id: json['id']?.toString() ?? '',
      visitId: json['visitId']?.toString() ?? '',
      surveyId: json['surveyId']?.toString() ?? '',
      surveyName: json['surveyName'] as String? ?? '',
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      submittedAt: submitted != null ? DateTime.tryParse(submitted) : null,
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map(
                (e) => SurveyResponseAnswerModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class SurveyResponsesListResult {
  const SurveyResponsesListResult({
    required this.items,
    this.totalCount,
    this.pageNumber,
    this.pageSize,
  });

  final List<SurveyResponseSummaryModel> items;
  final int? totalCount;
  final int? pageNumber;
  final int? pageSize;

  factory SurveyResponsesListResult.fromJson(Map<String, dynamic> json) {
    return SurveyResponsesListResult(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => SurveyResponseSummaryModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      totalCount: json['totalCount'] as int?,
      pageNumber: json['pageNumber'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }
}
