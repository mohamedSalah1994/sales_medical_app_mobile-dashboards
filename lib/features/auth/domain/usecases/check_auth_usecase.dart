import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/login_response.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthUseCase implements UseCase<LoginResponse?, NoParams> {
  CheckAuthUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<LoginResponse?> call(NoParams params) {
    return repository.getStoredLoginData();
  }
}
