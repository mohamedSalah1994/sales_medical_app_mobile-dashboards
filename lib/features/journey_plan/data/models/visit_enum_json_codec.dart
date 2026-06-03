/// Parses API visit type (string enum or legacy int) to app value 1–3.
int? visitTypeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    switch (value.trim().toLowerCase()) {
      case 'individual':
      case 'normal':
        return 1;
      case 'coaching':
      case 'coach':
        return 2;
      case 'double':
        return 3;
    }
  }
  return null;
}

/// Serializes app visit type for API requests.
String visitTypeToApiValue(int visitType) {
  switch (visitType) {
    case 1:
      return 'Individual';
    case 2:
      return 'Coaching';
    case 3:
      return 'Double';
    default:
      return 'Individual';
  }
}

/// Parses API visit status (string enum or legacy int) to app value 1–5.
int? visitStatusFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    switch (value.trim().toLowerCase()) {
      case 'open':
      case 'planned':
        return 1;
      case 'inprogress':
      case 'in progress':
        return 2;
      case 'closed':
      case 'completed':
        return 3;
      case 'cancelled':
      case 'canceled':
        return 4;
      case 'noshow':
      case 'no show':
        return 5;
    }
  }
  return null;
}

/// Serializes app visit status for API requests.
String visitStatusToApiValue(int status) {
  switch (status) {
    case 1:
      return 'Open';
    case 2:
      return 'InProgress';
    case 3:
      return 'Closed';
    case 4:
      return 'Cancelled';
    case 5:
      return 'NoShow';
    default:
      return 'Open';
  }
}

/// Parses visit action status (e.g. `"Posted"` or legacy int).
int? visitActionStatusFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return 1;
      case 'inprogress':
      case 'in progress':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
      case 'canceled':
        return 4;
      case 'rejected':
        return 5;
      case 'posted':
        return 6;
    }
  }
  return null;
}
