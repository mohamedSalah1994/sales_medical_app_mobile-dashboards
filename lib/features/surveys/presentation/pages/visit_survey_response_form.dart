import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/question_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// Loads survey by id, shows **one** [Card] with every question, then
/// `POST /api/Surveys/responses` once with the full [answers] array.
class VisitSurveyResponseForm extends StatefulWidget {
  const VisitSurveyResponseForm({
    super.key,
    required this.visitId,
    required this.surveyId,
    this.onSuccess,
    this.onSurveyLoaded,
  });

  final String visitId;
  final String surveyId;
  final VoidCallback? onSuccess;
  final void Function(String displayName)? onSurveyLoaded;

  @override
  State<VisitSurveyResponseForm> createState() =>
      _VisitSurveyResponseFormState();
}

class _VisitSurveyResponseFormState extends State<VisitSurveyResponseForm> {
  /// When the survey question has no [QuestionEntity.minAnswerLength], free-text answers must be at least this long.
  static const int _kDefaultFreeTextMinLength = 3;

  final _repo = sl<SurveyRepository>();
  SurveyEntity? _survey;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _selectedOptionId = {};
  /// When API options have no id, POST uses [answerText] with selected option label.
  final Map<String, String> _selectedMcAnswerText = {};

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSurvey() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _repo.getSurveyById(widget.surveyId);
      if (!mounted) return;
      final sorted = List<QuestionEntity>.from(s.questions)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final survey = SurveyEntity(
        id: s.id,
        name: s.name,
        description: s.description,
        isActive: s.isActive,
        validFrom: s.validFrom,
        validTo: s.validTo,
        questions: sorted,
        createdAt: s.createdAt,
      );
      for (final q in survey.questions) {
        final id = q.id;
        if (id == null) continue;
        if (q.questionType != QuestionType.multipleChoice) {
          _textControllers.putIfAbsent(id, TextEditingController.new);
        }
      }
      if (!mounted) return;
      if (!survey.isEffectiveActive) {
        setState(() {
          _survey = null;
          _loading = false;
          _error = AppLocalizations.of(context)!.visitSurveyNotActive;
        });
        return;
      }
      setState(() {
        _survey = survey;
        _loading = false;
      });
      widget.onSurveyLoaded?.call(survey.name);
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

  int _minCharsForFreeText(QuestionEntity q) {
    if (q.questionType != QuestionType.freeText) return 0;
    final m = q.minAnswerLength;
    if (m != null && m > 0) return m.clamp(1, 2000);
    return _kDefaultFreeTextMinLength;
  }

  bool _questionHasAnswer(QuestionEntity q) {
    final id = q.id;
    if (id == null || id.isEmpty) return false;
    if (q.questionType == QuestionType.multipleChoice) {
      final hasId = (_selectedOptionId[id] ?? '').isNotEmpty;
      final hasText = (_selectedMcAnswerText[id] ?? '').isNotEmpty;
      return hasId || hasText;
    }
    final t = _textControllers[id]?.text.trim() ?? '';
    if (t.isEmpty) return false;
    return t.length >= _minCharsForFreeText(q);
  }

  bool _validate(AppLocalizations l10n) {
    final survey = _survey;
    if (survey == null) return false;
    final answerable =
        survey.questions.where((q) => q.id != null && q.id!.isNotEmpty).length;
    if (answerable == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitSurveyNoQuestions)),
      );
      return false;
    }
    for (final q in survey.questions) {
      final id = q.id;
      if (id == null || id.isEmpty) continue;
      if (q.questionType == QuestionType.freeText) {
        final t = _textControllers[id]?.text.trim() ?? '';
        if (t.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.visitSurveyAnswerAllQuestions)),
          );
          return false;
        }
        final minLen = _minCharsForFreeText(q);
        if (t.length < minLen) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.visitSurveyFreeTextTooShort(minLen))),
          );
          return false;
        }
        continue;
      }
      if (!_questionHasAnswer(q)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.visitSurveyAnswerAllQuestions)),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validate(l10n)) return;
    final survey = _survey;
    if (survey == null) return;

    final surveyIdForPost = survey.id ?? widget.surveyId;
    final answerable =
        survey.questions.where((q) => q.id != null && q.id!.isNotEmpty).length;

    final answers = <Map<String, dynamic>>[];
    for (final q in survey.questions) {
      final id = q.id;
      if (id == null) continue;
      if (q.questionType == QuestionType.multipleChoice) {
        final opt = _selectedOptionId[id];
        if (opt != null && opt.isNotEmpty) {
          answers.add({'questionId': id, 'selectedOptionId': opt});
        } else {
          final t = _selectedMcAnswerText[id]?.trim() ?? '';
          if (t.isNotEmpty) {
            answers.add({'questionId': id, 'answerText': t});
          }
        }
      } else {
        final text = _textControllers[id]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          answers.add({'questionId': id, 'answerText': text});
        }
      }
    }

    if (answers.length != answerable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitSurveyAnswerAllQuestions)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.submitSurveyResponse(
        visitId: widget.visitId,
        surveyId: surveyIdForPost,
        answers: answers,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.visitSurveySubmitted)));
      widget.onSuccess?.call();
    } on ServerFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<Widget> _surveyQuestionBlocks() {
    final out = <Widget>[];
    final qs = _survey!.questions;
    var index = 0;
    for (final q in qs) {
      final block = _buildQuestionBlock(q);
      if (block != null) {
        if (index > 0) {
          out.add(const SizedBox(height: 20));
          out.add(const Divider(height: 1));
          out.add(const SizedBox(height: 20));
        }
        out.add(block);
        index++;
      }
    }
    return out;
  }

  Widget? _buildQuestionBlock(QuestionEntity q) {
    final id = q.id;
    if (id == null) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* ${q.questionText}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        if (q.questionType == QuestionType.multipleChoice)
          ...q.options.map((opt) {
            final oid = opt.id;
            if (oid == null || oid.isEmpty) {
              final selected =
                  _selectedMcAnswerText[id] == opt.optionText &&
                  opt.optionText.isNotEmpty;
              return InkWell(
                onTap:
                    opt.optionText.isEmpty
                        ? null
                        : () => setState(() {
                          _selectedMcAnswerText[id] = opt.optionText;
                          _selectedOptionId.remove(id);
                        }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color:
                            selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(opt.optionText)),
                    ],
                  ),
                ),
              );
            }
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(opt.optionText),
              value: oid,
              groupValue: _selectedOptionId[id],
              onChanged: (v) => setState(() {
                _selectedOptionId[id] = v;
                _selectedMcAnswerText.remove(id);
              }),
            );
          })
        else
          TextField(
            controller: _textControllers[id],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: AppLocalizations.of(context)!.visitSurveyFreeTextMinHint(
                _minCharsForFreeText(q),
              ),
            ),
            maxLines: 3,
            minLines: 1,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
                onPressed: _loadSurvey,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_survey == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.visitSurveyAnswerAllHint,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              if (_survey!.questions.isNotEmpty &&
                  _survey!.questions.every((q) => q.id == null))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.visitSurveyNoQuestions,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                )
              else if (_survey!.questions.any(
                (q) => q.id != null && q.id!.isNotEmpty,
              ))
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_survey!.description.isNotEmpty) ...[
                          Text(
                            _survey!.description,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                        ],
                        ..._surveyQuestionBlocks(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(l10n.visitSurveySubmit),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
