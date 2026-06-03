import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sales_medical_app_mobile/core/pdf/erp_document_pdf.dart';

/// Build the PDF for [builder] and open the system share sheet.
///
/// Uses [Share.shareXFiles] with in-memory PDF bytes (no `printing` plugin),
/// avoiding `MissingPluginException` for `sharePdf` when native plugins are not
/// registered.
///
/// Shows a short snackbar while the PDF is being assembled. Returns `true` if
/// sharing was invoked without throwing.
Future<bool> shareErpDocumentPdf(
  BuildContext context, {
  required ErpDocumentPdfBuilder builder,
  String? filename,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(
      content: Text('Generating PDF…'),
      duration: Duration(seconds: 2),
    ),
  );

  try {
    final bytes = await builder.build();
    final safeName =
        (filename ?? '${builder.title}_${builder.docNum ?? builder.docEntry ?? ''}')
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '');
    final fname = safeName.isEmpty ? 'document.pdf' : '$safeName.pdf';

    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: fname,
        mimeType: 'application/pdf',
      ),
    ]);
    return true;
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Could not generate PDF: $e'),
        backgroundColor: Colors.red.shade600,
      ),
    );
    return false;
  }
}
