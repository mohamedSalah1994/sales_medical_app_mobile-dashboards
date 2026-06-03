import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_cubit.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_state.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/widgets/survey_form_bottom_sheet.dart';

class SurveysPage extends StatelessWidget {
  const SurveysPage({super.key, this.showScaffold = false});

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final content = BlocProvider(
      create: (context) => context.read<SurveysCubit>()..loadSurveys(),
      child: const _SurveysContent(),
    );

    if (showScaffold) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.surveys)),
        body: content,
      );
    }

    return content;
  }
}

class _SurveysContent extends StatelessWidget {
  const _SurveysContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurveysCubit, SurveysState>(
      builder: (context, state) {
        if (state.showCreateForm) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder:
                  (sheetContext) => BlocProvider.value(
                    value: context.read<SurveysCubit>(),
                    child: SurveyFormBottomSheet(survey: state.editingSurvey),
                  ),
            ).then((_) {
              context.read<SurveysCubit>().hideCreateForm();
            });
          });
        }

        return Container(
          color: AppColors.surface,
          child:
              state.isLoading && state.surveys.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.surveys.isEmpty
                  ? _EmptyState()
                  : _SurveysList(state: state),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSurveys,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createYourFirstSurvey,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SurveysList extends StatelessWidget {
  const _SurveysList({required this.state});

  final SurveysState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SurveysCubit>().loadSurveys();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.surveys.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.surveys.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final survey = state.surveys[index];
          return _SurveyCard(survey: survey);
        },
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.survey});

  final SurveyEntity survey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive =
        survey.isActive &&
        DateTime.now().isAfter(survey.validFrom) &&
        DateTime.now().isBefore(survey.validTo);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: () {
          context.read<SurveysCubit>().startEditing(survey);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      survey.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? l10n.active : l10n.inactive,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (survey.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  survey.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(survey.validFrom)} - ${dateFormat.format(survey.validTo)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${survey.questions.length} ${l10n.questions}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
