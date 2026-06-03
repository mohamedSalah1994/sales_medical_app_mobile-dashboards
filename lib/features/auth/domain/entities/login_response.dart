import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/user.dart';

class LoginResponse extends Equatable {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn, user];
}

