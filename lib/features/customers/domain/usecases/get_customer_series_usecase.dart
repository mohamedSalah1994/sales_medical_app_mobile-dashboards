import 'package:sales_medical_app_mobile/features/customers/data/models/customer_series_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';

class GetCustomerSeriesUseCase {
  GetCustomerSeriesUseCase({required this.repository});
  final CustomerRepository repository;

  Future<List<CustomerSeriesModel>> call() => repository.getCustomerSeries();
}
