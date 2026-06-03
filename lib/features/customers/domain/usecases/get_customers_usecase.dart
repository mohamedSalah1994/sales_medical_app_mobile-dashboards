import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  Future<List<Customer>> call({
    String? search,
    String? name,
    String? foreignName,
    String? forienName,
    String? area,
    String? zone,
    String? stateFilter,
    String? city,
    String? region,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  }) {
    return repository.getCustomers(
      search: search,
      name: name,
      foreignName: foreignName,
      forienName: forienName,
      area: area,
      zone: zone,
      stateFilter: stateFilter,
      city: city,
      region: region,
      activeOnly: activeOnly,
      salesEmployeeCode: salesEmployeeCode,
      pageNumber: pageNumber,
      pageSize: pageSize,
      scope: scope,
    );
  }
}
