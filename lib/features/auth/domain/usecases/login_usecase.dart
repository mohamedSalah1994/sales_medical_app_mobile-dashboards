import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/login_response.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({
    required this.username,
    required this.password,
    required this.rememberMe,
  });

  final String username;
  final String password;
  final bool rememberMe;
}

class LoginUseCase implements UseCase<LoginResponse, LoginParams> {
  LoginUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<LoginResponse> call(LoginParams params) {
    return repository.login(
      params.username,
      params.password,
      params.rememberMe,
    );
  }
}
