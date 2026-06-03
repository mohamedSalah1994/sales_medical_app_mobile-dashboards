/// Human-readable label for ODBC/BP `cardType` in picker dialogs.
/// `C` → Customer, `L` → Lead; empty when unknown or other.
String odbcCardTypeKindLabel(String? cardType) {
  switch (cardType?.trim().toUpperCase()) {
    case 'C':
      return 'Customer';
    case 'L':
      return 'Lead';
    default:
      return '';
  }
}
