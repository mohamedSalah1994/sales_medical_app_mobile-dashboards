import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_response_entities.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';

/// GET /api/Surveys/responses/{id}
class VisitSurveyResponseDetailPage extends StatefulWidget {
  const VisitSurveyResponseDetailPage({super.key, required this.responseId});

  final String responseId;

  @override
  State<VisitSurveyResponseDetailPage> createState() =>
      _VisitSurveyResponseDetailPageState();
}

class _VisitSurveyResponseDetailPageState
    extends State<VisitSurveyResponseDetailPage> {
  final _repo = sl<SurveyRepository>();
  SurveyResponseEntry? _entry;
  Map<String, String> _questionTextById = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final e = await _repo.getSurveyResponseById(widget.responseId);
      Map<String, String> questionTextById = const {};
      if (e.surveyId.isNotEmpty) {
        try {
          final survey = await _repo.getSurveyById(e.surveyId);
          questionTextById = {
            for (final q in survey.questions)
              if (q.id != null && q.id!.isNotEmpty) q.id!: q.questionText,
          };
        } catch (_) {
          // Keep fallback label when survey questions cannot be loaded.
        }
      }
      if (!mounted) return;
      setState(() {
        _entry = e;
        _questionTextById = questionTextById;
        _loading = false;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyErrorMessage(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFriendlyErrorMessage(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          e?.surveyName ?? 'Survey response',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : e == null
              ? const SizedBox.shrink()
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (e.userName != null && e.userName!.isNotEmpty)
                    Text(
                      e.userName!,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  if (e.submittedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(e.submittedAt!),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...e.answers.map(_answerBlock),
                ],
              ),
    );
  }

  Widget _answerBlock(SurveyResponseAnswer a) {
    final lines = <String>[];
    if (a.answerText != null && a.answerText!.trim().isNotEmpty) {
      lines.add(a.answerText!.trim());
    }
    if (a.selectedOptionText != null &&
        a.selectedOptionText!.trim().isNotEmpty) {
      lines.add(a.selectedOptionText!.trim());
    } else if (a.selectedOptionId != null &&
        a.selectedOptionId!.isNotEmpty) {
      lines.add('Option: ${a.selectedOptionId}');
    }
    if (a.numericValue != null) {
      lines.add('${a.numericValue}');
    }
    final body = lines.isEmpty ? '—' : lines.join('\n');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _questionTextById[a.questionId] ?? 'Question ${a.questionId}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
