import 'package:sales_medical_app_mobile/features/customers/data/models/create_erp_customer_request_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';

class CreateErpCustomerUseCase {
  CreateErpCustomerUseCase({required this.repository});
  final CustomerRepository repository;

  Future<Map<String, dynamic>> call(CreateErpCustomerRequestModel body) =>
      repository.createCustomer(body);
}
