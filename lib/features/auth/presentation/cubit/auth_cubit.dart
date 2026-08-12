import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_gate.dart';
import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/core/utils/app_version.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/login_response.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/logout_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckAuthUseCase checkAuthUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _checkAuthUseCase = checkAuthUseCase,
       super(AuthState.initial());

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthUseCase _checkAuthUseCase;

  void usernameChanged(String value) {
    emit(state.copyWith(username: value, clearError: true, isSuccess: false));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(password: value, clearError: true, isSuccess: false));
  }

  void toggleRemember(bool value) {
    emit(state.copyWith(rememberMe: value));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> login() async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          errorMessage:
              'Please enter a valid username (3+ characters) and a password of 6+ characters.',
          isSuccess: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(isSubmitting: true, clearError: true, isSuccess: false),
    );

    try {
      // Same value as `X-App-Version` header (semver / store build).
      final version = await AppVersion.getApiVersion();
      final loginResponse = await _loginUseCase(
        LoginParams(
          username: state.username,
          password: state.password,
          rememberMe: state.rememberMe,
          version: version,
        ),
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          isAuthenticated: true,
          loginResponse: loginResponse,
        ),
      );
    } catch (e) {
      if (ForceUpdateGate.isActive) {
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: false,
            clearError: true,
          ),
        );
        return;
      }

      String errorMessage = 'An error occurred. Please try again.';

      if (e is ServerFailure) {
        errorMessage = e.message;
      } else if (e is Exception) {
        final errorString = e.toString();
        // Remove "Exception: " prefix if present
        errorMessage = errorString.replaceAll('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      if (errorMessage.trim().isEmpty) {
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: false,
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: false,
          errorMessage: errorMessage,
        ),
      );
    }
  }

  Future<void> checkAuth() async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final loginResponse = await _checkAuthUseCase(NoParams());
      if (loginResponse != null) {
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            isAuthenticated: true,
            loginResponse: loginResponse,
          ),
        );
      } else {
        emit(state.copyWith(isSubmitting: false, isAuthenticated: false));
      }
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, isAuthenticated: false));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _logoutUseCase(NoParams());
      emit(AuthState.initial());
    } catch (e) {
      // Even if logout fails, clear local state
      emit(AuthState.initial());
    }
  }
}
