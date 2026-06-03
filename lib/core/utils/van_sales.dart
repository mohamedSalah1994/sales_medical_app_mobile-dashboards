/// Maps ERP `uTrantjov` to Van Sales vs Pre Sales for list display.
bool isVanSalesYes(String? raw) {
  if (raw == null) return false;
  final t = raw.trim().toLowerCase();
  return t == 'yes' || t == 'y' || t == '1' || t == 'true';
}

/// Human-readable ERP sale type label derived from `uTrantjov`.
String salesTypeLabel(String? raw) {
  return isVanSalesYes(raw) ? 'Van Sales' : 'Pre Sales';
}
