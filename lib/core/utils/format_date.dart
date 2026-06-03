import 'package:intl/intl.dart';

/// Formats an ISO-8601 date/time string for UI as date only (locale-aware).
String formatIsoDateLocal(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso.trim();
  return DateFormat.yMMMd().format(d.toLocal());
}

/// Parses API date/time strings (e.g. `docDueDate`) for pickers and PATCH bodies.
DateTime? parseIsoDateTime(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  return DateTime.tryParse(iso.trim());
}
