import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';

/// Builds query parameters for `GET /api/MasterData/customers/odbc`.
///
/// Uses API names including `salesEmpCode` and the documented `forienName`
/// query key (server spelling). `scope` is sent as `Customers` / `Leads` / `All`.
Map<String, dynamic> buildOdbcCustomersMasterDataQuery({
  required int skip,
  required int take,
  int scope = CustomerOdbcScope.all,
  bool? activeOnly,
  String? search,
  String? name,
  String? foreignName,
  String? forienName,
  String? area,
  String? zone,
  String? state,
  String? city,
  String? region,
  int? salesEmpCode,
}) {
  final q = <String, dynamic>{
    'activeOnly': activeOnly ?? true,
    'skip': skip,
    'take': take,
    'scope': _odbcScopeQueryValue(scope),
  };

  void putIfNonEmpty(String key, String? v) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) q[key] = t;
  }

  putIfNonEmpty('search', search);
  putIfNonEmpty('name', name);
  putIfNonEmpty('foreignName', foreignName);
  putIfNonEmpty('forienName', forienName);
  putIfNonEmpty('area', area);
  putIfNonEmpty('zone', zone);
  putIfNonEmpty('state', state);
  putIfNonEmpty('city', city);
  putIfNonEmpty('region', region);
  if (salesEmpCode != null) q['salesEmpCode'] = salesEmpCode;
  return q;
}

String _odbcScopeQueryValue(int scope) {
  switch (scope) {
    case CustomerOdbcScope.customersOnly:
      return 'Customers';
    case CustomerOdbcScope.leadsOnly:
      return 'Leads';
    default:
      return 'All';
  }
}
