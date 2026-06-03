import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Customer>> getCustomers({
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
  }) async {
    try {
      final response = await remoteDataSource.getCustomers(
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

      final itemsList = response['items'] as List<dynamic>? ?? [];
      return itemsList
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CustomerSeriesModel>> getCustomerSeries() async {
    return remoteDataSource.getCustomerSeries();
  }

  @override
  Future<Map<String, dynamic>> createCustomer(CreateErpCustomerRequestModel body) async {
    return remoteDataSource.createCustomer(body);
  }

  @override
  Future<List<MasterDataOptionModel>> getAreas() =>
      remoteDataSource.getAreas();

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtZones(String area) =>
      remoteDataSource.getAreaUdtZones(area);

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtStates(String zone) =>
      remoteDataSource.getAreaUdtStates(zone);

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtCities(String state) =>
      remoteDataSource.getAreaUdtCities(state);

  @override
  Future<List<MasterDataOptionModel>> getAreaUdtRegions(String city) =>
      remoteDataSource.getAreaUdtRegions(city);

  @override
  Future<List<MasterDataOptionModel>> getCustomerTypes() =>
      remoteDataSource.getCustomerTypes();
}
