import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sales_medical_app_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/login_response.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.apiService,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final ApiService apiService;

  @override
  Future<LoginResponse> login(
    String username,
    String password,
    bool rememberMe, {
    String? version,
  }) async {
    try {
      final response = await remoteDataSource.login(
        username,
        password,
        version: version,
      );
      // Save login data locally first
      await localDataSource.saveLoginData(response, rememberMe);
      // Ensure token is set in API service after saving to preferences
      await apiService.saveToken(response.accessToken);
      // Return response only after everything is saved
      return response;
    } on ServerFailure {
      // Re-throw ServerFailure to preserve the error message
      rethrow;
    } catch (e) {
      // For any other exception, wrap it in ServerFailure
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<String?> getStoredDefaultWarehouseCode() {
    return localDataSource.getStoredDefaultWarehouseCode();
  }

  @override
  Future<LoginResponse?> getStoredLoginData() async {
    try {
      final loginResponse = await localDataSource.getLoginData();
      // Restore token to API service
      if (loginResponse != null) {
        await apiService.saveToken(loginResponse.accessToken);
      }
      return loginResponse;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Call remote logout endpoint
      await remoteDataSource.logout();
    } catch (e) {
      // Continue to clear local data even if remote logout fails
    } finally {
      // Always clear local data and token
      await localDataSource.clearLoginData();
      await apiService.clearToken();
    }
  }
}
