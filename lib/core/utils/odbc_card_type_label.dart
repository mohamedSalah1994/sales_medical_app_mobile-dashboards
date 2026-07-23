/// Normalizes ERP/ODBC `cardType` values such as `C`, `cCustomer`, `L`, `cLid`.
String normalizeOdbcCardType(String? cardType) {
  final raw = cardType?.trim().toUpperCase() ?? '';
  if (raw.isEmpty) return '';
  if (raw == 'C' || raw == 'CCUSTOMER' || raw.contains('CUSTOMER')) {
    return 'C';
  }
  if (raw == 'L' ||
      raw == 'CLID' ||
      raw == 'CLEAD' ||
      raw.contains('LEAD') ||
      raw.contains('LID')) {
    return 'L';
  }
  return raw;
}

bool isOdbcCustomerCardType(String? cardType) {
  final n = normalizeOdbcCardType(cardType);
  // Empty type treated as customer for Channel BP picker compatibility.
  return n.isEmpty || n == 'C';
}

bool isOdbcLeadCardType(String? cardType) {
  return normalizeOdbcCardType(cardType) == 'L';
}

/// Human-readable label for ODBC/BP `cardType` in picker dialogs.
/// `C` / `cCustomer` → Customer, `L` / `cLid` → Lead; empty when unknown.
String odbcCardTypeKindLabel(String? cardType) {
  switch (normalizeOdbcCardType(cardType)) {
    case 'C':
      return 'Customer';
    case 'L':
      return 'Lead';
    default:
      return '';
  }
}
