/// Maps ERP `uTrantjov` to Van Sales vs Pre Sales for list display.
///
/// API convention: `"No"` → Van Sales, `"Yes"` → Pre Sales.
bool isVanSalesYes(String? raw) {
  if (raw == null) return false;
  final t = raw.trim().toLowerCase();
  return t == 'no' || t == 'n' || t == '0' || t == 'false';
}

/// Human-readable ERP sale type label derived from `uTrantjov`.
String salesTypeLabel(String? raw) {
  return isVanSalesYes(raw) ? 'Van Sales' : 'Pre Sales';
}
