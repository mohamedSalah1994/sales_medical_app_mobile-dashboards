import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/pages/visit_survey_response_form.dart';

/// Full-screen survey response: one card, all answers, single
/// `POST /api/Surveys/responses`.
class VisitSurveyFillPage extends StatefulWidget {
  const VisitSurveyFillPage({
    super.key,
    required this.visitId,
    required this.surveyId,
    required this.surveyTitle,
  });

  final String visitId;
  final String surveyId;
  final String surveyTitle;

  @override
  State<VisitSurveyFillPage> createState() => _VisitSurveyFillPageState();
}

class _VisitSurveyFillPageState extends State<VisitSurveyFillPage> {
  late String _appBarTitle = widget.surveyTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: VisitSurveyResponseForm(
        visitId: widget.visitId,
        surveyId: widget.surveyId,
        onSurveyLoaded: (name) {
          if (mounted) setState(() => _appBarTitle = name);
        },
        onSuccess: () {
          if (mounted) Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
