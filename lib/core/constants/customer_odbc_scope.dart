/// `scope` query parameter for `GET /api/MasterData/customers/odbc`.
///
/// Server default is typically full scope (`2` = [all]). Call sites that need
/// only rows for one kind should pass [customersOnly] or [leadsOnly] explicitly.
class CustomerOdbcScope {
  CustomerOdbcScope._();

  /// Customers only.
  static const int customersOnly = 0;

  /// Leads only.
  static const int leadsOnly = 1;

  /// Customers and leads (full scope).
  static const int all = 2;
}
