import 'package:sales_medical_app_mobile/features/auth/domain/entities/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(
    String username,
    String password,
    bool rememberMe, {
    String? version,
  });
  Future<LoginResponse?> getStoredLoginData();
  Future<String?> getStoredDefaultWarehouseCode();
  Future<void> logout();
}
