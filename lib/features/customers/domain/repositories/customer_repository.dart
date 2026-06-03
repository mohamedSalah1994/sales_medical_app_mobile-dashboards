import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/entities/customer.dart';

abstract class CustomerRepository {
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
  });
  Future<List<CustomerSeriesModel>> getCustomerSeries();
  Future<Map<String, dynamic>> createCustomer(CreateErpCustomerRequestModel body);
  Future<List<MasterDataOptionModel>> getAreas();
  Future<List<MasterDataOptionModel>> getAreaUdtZones(String area);
  Future<List<MasterDataOptionModel>> getAreaUdtStates(String zone);
  Future<List<MasterDataOptionModel>> getAreaUdtCities(String state);
  Future<List<MasterDataOptionModel>> getAreaUdtRegions(String city);
  Future<List<MasterDataOptionModel>> getCustomerTypes();
}
