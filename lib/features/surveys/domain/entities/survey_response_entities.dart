/// Read model for GET /api/Surveys/responses and GET /api/Surveys/responses/{id}.
class SurveyResponseAnswer {
  const SurveyResponseAnswer({
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
}

class SurveyResponseEntry {
  const SurveyResponseEntry({
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
  final List<SurveyResponseAnswer> answers;

  /// True if at least one answer carries user input (for list filtering).
  bool get hasAnsweredQuestions {
    for (final a in answers) {
      if (a.answerText != null && a.answerText!.trim().isNotEmpty) {
        return true;
      }
      if (a.selectedOptionId != null && a.selectedOptionId!.trim().isNotEmpty) {
        return true;
      }
      if (a.selectedOptionText != null &&
          a.selectedOptionText!.trim().isNotEmpty) {
        return true;
      }
      if (a.numericValue != null) {
        return true;
      }
    }
    return false;
  }
}

/// Paged result for GET /api/Surveys/responses (includes [totalCount] when provided).
class SurveyResponsesLoadResult {
  const SurveyResponsesLoadResult({
    required this.items,
    this.totalCount,
  });

  final List<SurveyResponseEntry> items;
  final int? totalCount;

  /// Prefer server [totalCount]. If missing, uses [items] length (accurate when
  /// the client requested a large enough [pageSize]).
  int get effectiveResponseCount => totalCount ?? items.length;
}
