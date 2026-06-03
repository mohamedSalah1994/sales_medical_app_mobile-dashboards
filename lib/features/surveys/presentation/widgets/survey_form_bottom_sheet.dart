import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/question_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/question_option_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/entities/survey_entity.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_cubit.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_state.dart';


class SurveyFormBottomSheet extends StatefulWidget {
  const SurveyFormBottomSheet({super.key, this.survey});

  final SurveyEntity? survey;

  @override
  State<SurveyFormBottomSheet> createState() => _SurveyFormBottomSheetState();
}

class _SurveyFormBottomSheetState extends State<SurveyFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validTo;
  final List<QuestionEntity> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.survey != null) {
      _nameController = TextEditingController(text: widget.survey!.name);
      _descriptionController =
          TextEditingController(text: widget.survey!.description);
      _isActive = widget.survey!.isActive;
      _validFrom = widget.survey!.validFrom;
      _validTo = widget.survey!.validTo;
      _questions.addAll(widget.survey!.questions);
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _validFrom = DateTime.now();
      _validTo = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_validFrom == null || _validTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select valid dates'),
          ),
        );
        return;
      }
      if (_questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one question')),
        );
        return;
      }

      final ordered = <QuestionEntity>[];
      for (var i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        ordered.add(
          QuestionEntity(
            id: q.id,
            questionText: q.questionText,
            questionType: q.questionType,
            displayOrder: i,
            isRequired: q.isRequired,
            options: q.options,
            minAnswerLength: q.minAnswerLength,
          ),
        );
      }

      final survey = SurveyEntity(
        id: widget.survey?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        validFrom: _validFrom!,
        validTo: _validTo!,
        questions: ordered,
        createdAt: widget.survey?.createdAt,
      );

      context.read<SurveysCubit>().createOrUpdateSurvey(survey);
    }
  }

  Future<void> _openAddQuestion() async {
    final created = await showDialog<QuestionEntity?>(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        initial: null,
        defaultDisplayOrder: _questions.length,
      ),
    );
    if (created != null) {
      setState(() => _questions.add(created));
    }
  }

  Future<void> _openEditQuestion(int index) async {
    final updated = await showDialog<QuestionEntity?>(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        initial: _questions[index],
        defaultDisplayOrder: _questions[index].displayOrder,
      ),
    );
    if (updated != null) {
      setState(() => _questions[index] = updated);
    }
  }

  void _deleteQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<SurveysCubit, SurveysState>(
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.of(context).pop();
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<SurveysCubit, SurveysState>(
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Text(
                              widget.survey == null
                                  ? l10n.createSurvey
                                  : l10n.editSurvey,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.surveyName,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.pleaseEnterSurveyName;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Description
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: l10n.description,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              // Active Toggle
                              SwitchListTile(
                                title: Text(l10n.isActive),
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              // Valid From
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _validFrom ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _validFrom = date;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.validFrom,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _validFrom != null
                                        ? DateFormat('MMM dd, yyyy')
                                            .format(_validFrom!)
                                        : l10n.selectDate,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Valid To
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _validTo ?? DateTime.now(),
                                    firstDate: _validFrom ?? DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _validTo = date;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.validTo,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _validTo != null
                                        ? DateFormat('MMM dd, yyyy')
                                            .format(_validTo!)
                                        : l10n.selectDate,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Questions Section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.questions,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _openAddQuestion,
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.addQuestion),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_questions.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'Add at least one question (free text or multiple choice).',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _questions.length;
                                      i++
                                    ) ...[
                                      _QuestionRow(
                                        index: i + 1,
                                        question: _questions[i],
                                        onEdit: () => _openEditQuestion(i),
                                        onDelete: () => _deleteQuestion(i),
                                      ),
                                      if (i != _questions.length - 1)
                                        const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 16),
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      state.isSubmitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: state.isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          widget.survey == null
                                              ? l10n.create
                                              : l10n.update,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Compact card showing one question in the survey author form, with edit /
/// delete actions. Free-text questions surface their `minCharacters` (the
/// validation the response form will enforce); multiple-choice questions
/// surface a count of options.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final QuestionEntity question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isFreeText = question.questionType == QuestionType.freeText;
    final typeLabel = question.questionType.label;
    final subtitleParts = <String>[typeLabel];
    if (isFreeText) {
      final m = question.minAnswerLength ?? 0;
      subtitleParts.add(
        m > 0
            ? 'Min $m characters'
            : 'No min length',
      );
    } else {
      subtitleParts.add('${question.options.length} options');
    }
    if (question.isRequired) subtitleParts.add('Required');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' • '),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Add / edit a single survey question. For [QuestionType.freeText] surfaces
/// a `minCharacters` field which is what the response form enforces (`length
/// >= minCharacters`). For [QuestionType.multipleChoice] manages the option
/// list inline.
class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({
    required this.initial,
    required this.defaultDisplayOrder,
  });

  final QuestionEntity? initial;
  final int defaultDisplayOrder;

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late TextEditingController _minCharsController;
  late QuestionType _type;
  late bool _isRequired;
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _textController = TextEditingController(text: init?.questionText ?? '');
    _type = init?.questionType ?? QuestionType.freeText;
    _isRequired = init?.isRequired ?? true;
    _minCharsController = TextEditingController(
      text:
          (init != null && init.minAnswerLength != null && init.minAnswerLength! > 0)
              ? init.minAnswerLength.toString()
              : '0',
    );
    _optionControllers = (init?.options.isNotEmpty == true)
        ? init!.options
            .map((o) => TextEditingController(text: o.optionText))
            .toList()
        : <TextEditingController>[
            TextEditingController(),
            TextEditingController(),
          ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _minCharsController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final text = _textController.text.trim();
    int? minChars;
    if (_type == QuestionType.freeText) {
      final raw = _minCharsController.text.trim();
      final n = int.tryParse(raw) ?? 0;
      minChars = n > 0 ? n : null;
    }

    final options = <QuestionOptionEntity>[];
    if (_type == QuestionType.multipleChoice) {
      for (var i = 0; i < _optionControllers.length; i++) {
        final t = _optionControllers[i].text.trim();
        if (t.isEmpty) continue;
        options.add(
          QuestionOptionEntity(
            id: (i < (widget.initial?.options.length ?? 0))
                ? widget.initial!.options[i].id
                : null,
            optionText: t,
            displayOrder: i,
          ),
        );
      }
    }

    final result = QuestionEntity(
      id: widget.initial?.id,
      questionText: text,
      questionType: _type,
      displayOrder: widget.initial?.displayOrder ?? widget.defaultDisplayOrder,
      isRequired: _isRequired,
      minAnswerLength: minChars,
      options: options,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Question text',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter the question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<QuestionType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Question type',
                    border: OutlineInputBorder(),
                  ),
                  items: QuestionType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 12),
                if (_type == QuestionType.freeText)
                  TextFormField(
                    controller: _minCharsController,
                    decoration: const InputDecoration(
                      labelText: 'Min characters',
                      helperText:
                          'Response must be at least this many characters. 0 = no minimum.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) return null;
                      final n = int.tryParse(raw);
                      if (n == null || n < 0) {
                        return 'Enter a non-negative number';
                      }
                      if (n > 2000) return 'Max 2000';
                      return null;
                    },
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Options',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _optionControllers.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${i + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (i < 2 && t.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: _optionControllers.length > 2
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          onPressed: _optionControllers.length > 2
                              ? () => _removeOption(i)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                      label: const Text('Add option'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Required'),
                  contentPadding: EdgeInsets.zero,
                  value: _isRequired,
                  onChanged: (v) => setState(() => _isRequired = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
