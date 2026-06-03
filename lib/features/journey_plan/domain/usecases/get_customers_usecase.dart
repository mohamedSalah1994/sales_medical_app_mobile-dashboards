import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class GetCustomersParams {
  final String? search;
  final String? state;
  final String? city;
  final bool? activeOnly;
  final int pageNumber;
  final int pageSize;
  final int scope;

  GetCustomersParams({
    this.search,
    this.state,
    this.city,
    this.activeOnly,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.scope = CustomerOdbcScope.all,
  });
}

class GetCustomersUseCase implements UseCase<List<Customer>, GetCustomersParams> {
  GetCustomersUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<List<Customer>> call(GetCustomersParams params) async {
    return await repository.getCustomers(
      search: params.search,
      state: params.state,
      city: params.city,
      activeOnly: params.activeOnly,
      pageNumber: params.pageNumber,
      pageSize: params.pageSize,
      scope: params.scope,
    );
  }
}
