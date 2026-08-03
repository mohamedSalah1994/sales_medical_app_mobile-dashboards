import 'package:dio/dio.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/auth/data/models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(
    String username,
    String password, {
    String? version,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<LoginResponseModel> login(
    String username,
    String password, {
    String? version,
  }) async {
    try {
      final data = <String, dynamic>{
        'username': username,
        'password': password,
      };
      final v = version?.trim();
      if (v != null && v.isNotEmpty) {
        data['version'] = v;
      }
      final response = await apiService.post(
        '/api/Auth/login',
        data: data,
      );

      // Check if response contains error field (even if status is 200)
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // If response has 'error' field, extract and throw it
        if (data.containsKey('error')) {
          final errorMessage = data['error'] as String? ?? 'Login failed';
          throw ServerFailure(message: errorMessage);
        }

        // If response doesn't have required fields for login, it might be an error
        if (!data.containsKey('accessToken') || !data.containsKey('user')) {
          final errorMessage =
              data['error'] ?? data['message'] ?? 'Login failed';
          throw ServerFailure(message: errorMessage.toString());
        }
      }

      final loginResponse = LoginResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Save token after successful login
      await apiService.saveToken(loginResponse.accessToken);

      return loginResponse;
    } on ApiHttpException catch (e) {
      var message = e.message.trim();
      if (message.isEmpty || message == 'An error occurred') {
        message =
            e.statusCode == 401
                ? 'Invalid username or password.'
                : 'Login failed. Please try again.';
      }
      throw ServerFailure(message: message);
    } on DioException catch (e) {
      // Handle DioException and extract error message from response
      String errorMessage = 'Login failed';

      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['error']?.toString() ??
              errorData['message']?.toString() ??
              errorData['ErrorMessage']?.toString() ??
              errorData['errorMessage']?.toString() ??
              'Login failed';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid username or password.';
      }

      throw ServerFailure(message: errorMessage);
    } on ServerFailure {
      // Re-throw ServerFailure to preserve the error message
      rethrow;
    } catch (e) {
      // For any other exception, wrap it
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiService.post('/api/Auth/logout');
    } on DioException catch (e) {
      String errorMessage = 'Logout failed';

      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          errorMessage =
              errorData['error']?.toString() ??
              errorData['message']?.toString() ??
              'Logout failed';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw ServerFailure(message: errorMessage);
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
