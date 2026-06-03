import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/error/error_message_helper.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_response_form.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// Lists active surveys so the user can open one and answer it for [visitId].
class VisitSurveyListPage extends StatefulWidget {
  const VisitSurveyListPage({super.key, required this.visitId});

  final String visitId;

  @override
  State<VisitSurveyListPage> createState() => _VisitSurveyListPageState();
}

class _VisitSurveyListPageState extends State<VisitSurveyListPage> {
  final _repo = sl<SurveyRepository>();
  List<SurveyEntity> _surveys = [];
  bool _loading = true;
  String? _error;
  String? _answeringSurveyId;
  String? _answeringSurveyTitle;

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
      final list = await _repo.getSurveys(
        isActive: true,
        pageNumber: 1,
        pageSize: 50,
      );
      if (!mounted) return;
      final activeOnly =
          list.where((s) => s.isEffectiveActive).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _surveys = activeOnly;
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
    final l10n = AppLocalizations.of(context)!;
    final answeringId = _answeringSurveyId;
    final answeringTitle = _answeringSurveyTitle;
    if (answeringId != null &&
        answeringId.isNotEmpty &&
        answeringTitle != null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _answeringSurveyId = null;
                _answeringSurveyTitle = null;
              });
            },
          ),
          title: Text(
            answeringTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: VisitSurveyResponseForm(
          visitId: widget.visitId,
          surveyId: answeringId,
          onSuccess: () {
            if (!mounted) return;
            setState(() {
              _answeringSurveyId = null;
              _answeringSurveyTitle = null;
            });
            _load();
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.visitSurveySelectTitle),
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
              : _surveys.isEmpty
              ? Center(
                child: Text(
                  l10n.visitSurveyNoSurveys,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _surveys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = _surveys[index];
                    final id = s.id;
                    return Card(
                      child: ListTile(
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            s.description.isNotEmpty
                                ? Text(
                                  s.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            id == null || id.isEmpty
                                ? null
                                : () {
                                  setState(() {
                                    _answeringSurveyId = id;
                                    _answeringSurveyTitle = s.name;
                                  });
                                },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
