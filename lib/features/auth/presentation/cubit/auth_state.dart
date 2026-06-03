part of 'auth_cubit.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.username,
    required this.password,
    required this.rememberMe,
    required this.isSubmitting,
    this.errorMessage,
    required this.isSuccess,
    required this.isPasswordVisible,
    required this.isAuthenticated,
    this.loginResponse,
  });

  factory AuthState.initial() {
    return const AuthState(
      username: '',
      password: '',
      rememberMe: true,
      isSubmitting: false,
      errorMessage: null,
      isSuccess: false,
      isPasswordVisible: false,
      isAuthenticated: false,
      loginResponse: null,
    );
  }

  final String username;
  final String password;
  final bool rememberMe;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;
  final bool isPasswordVisible;
  final bool isAuthenticated;
  final LoginResponse? loginResponse;

  bool get isValidUsername => username.isNotEmpty && username.length >= 3;
  bool get isValidPassword => password.length >= 6;
  bool get isFormValid => isValidUsername && isValidPassword;

  AuthState copyWith({
    String? username,
    String? password,
    bool? rememberMe,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool? isPasswordVisible,
    bool? isAuthenticated,
    LoginResponse? loginResponse,
    bool clearError = false,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loginResponse: loginResponse ?? this.loginResponse,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    rememberMe,
    isSubmitting,
    errorMessage,
    isSuccess,
    isPasswordVisible,
    isAuthenticated,
    loginResponse,
  ];
}
