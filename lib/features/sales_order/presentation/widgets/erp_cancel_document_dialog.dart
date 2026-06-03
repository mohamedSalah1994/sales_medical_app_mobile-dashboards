import 'package:flutter/material.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/models/sales_order_response_model.dart';

/// Shows a confirm dialog for cancelling an ERP document (sales order /
/// delivery), runs [action], then displays the API result as a success / error
/// popup.
///
/// Returns the parsed [SalesOrderResponseModel] when the user confirmed and
/// the action completed (success or failure). Returns `null` when the user
/// dismisses the confirm step.
Future<SalesOrderResponseModel?> showErpCancelDocumentDialog(
  BuildContext context, {
  required String documentLabel,
  required String? docNumberLabel,
  required Future<SalesOrderResponseModel> Function() action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Cancel $documentLabel'),
        content: Text(
          'Are you sure you want to cancel this $documentLabel'
          '${docNumberLabel != null && docNumberLabel.isNotEmpty ? ' ($docNumberLabel)' : ''}?'
          ' This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel $documentLabel'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return null;

  // Note: We intentionally do NOT show a modal spinner here. The calling page
  // already toggles its own loading overlay (cubit's `isSubmitting` for sales
  // order, or local `_isSubmitting` for delivery), which renders a single
  // CircularProgressIndicator in the brand color. Showing another spinner in
  // a dialog on top would result in two stacked loaders.
  SalesOrderResponseModel response;
  try {
    response = await action();
  } catch (e) {
    response = SalesOrderResponseModel(
      success: false,
      errorMessage: e.toString().replaceFirst('Exception: ', ''),
    );
  }

  if (context.mounted) {
    await _showResultDialog(
      context,
      documentLabel: documentLabel,
      response: response,
    );
  }
  return response;
}

Future<void> _showResultDialog(
  BuildContext context, {
  required String documentLabel,
  required SalesOrderResponseModel response,
}) async {
  final isSuccess = response.success;
  final title = isSuccess
      ? '$documentLabel cancelled'
      : 'Cancel failed';

  String body;
  if (isSuccess) {
    final docNum = response.documentNumber?.trim();
    body = (docNum != null && docNum.isNotEmpty)
        ? 'Document #$docNum was cancelled successfully.'
        : 'The document was cancelled successfully.';
  } else {
    final msg = response.errorMessage?.trim();
    final code = response.errorCode?.trim();
    final parts = <String>[];
    if (msg != null && msg.isNotEmpty) parts.add(msg);
    if (code != null && code.isNotEmpty) parts.add('Code: $code');
    body = parts.isEmpty
        ? 'The cancel request did not succeed. Please try again.'
        : parts.join('\n');
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? AppColors.success : AppColors.error,
          size: 36,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
