import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_medical_app_mobile/features/auth/data/models/login_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveLoginData(LoginResponseModel loginResponse, bool rememberMe);
  Future<LoginResponseModel?> getLoginData();
  Future<bool> isRememberMe();
  Future<void> clearLoginData();
  /// Last logged-in user's [User.defaultWarehouseCode], for forms when session is not restored.
  Future<String?> getStoredDefaultWarehouseCode();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyExpiresIn = 'expires_in';
  static const String _keyUserData = 'user_data';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyDefaultWarehouseCode = 'default_warehouse_code';

  @override
  Future<void> saveLoginData(
    LoginResponseModel loginResponse,
    bool rememberMe,
  ) async {
    await sharedPreferences.setString(
      _keyAccessToken,
      loginResponse.accessToken,
    );
    await sharedPreferences.setString(
      _keyRefreshToken,
      loginResponse.refreshToken,
    );
    await sharedPreferences.setInt(_keyExpiresIn, loginResponse.expiresIn);
    await sharedPreferences.setString(
      _keyUserData,
      jsonEncode(loginResponse.toJson()),
    );
    await sharedPreferences.setBool(_keyRememberMe, rememberMe);

    final wh = loginResponse.user.defaultWarehouseCode?.trim();
    if (wh != null && wh.isNotEmpty) {
      await sharedPreferences.setString(_keyDefaultWarehouseCode, wh);
    } else {
      await sharedPreferences.remove(_keyDefaultWarehouseCode);
    }
  }

  @override
  Future<LoginResponseModel?> getLoginData() async {
    final rememberMe = sharedPreferences.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return null;

    final userData = sharedPreferences.getString(_keyUserData);
    if (userData == null) return null;

    try {
      final jsonData = jsonDecode(userData) as Map<String, dynamic>;
      return LoginResponseModel.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isRememberMe() async {
    return sharedPreferences.getBool(_keyRememberMe) ?? false;
  }

  @override
  Future<void> clearLoginData() async {
    await sharedPreferences.remove(_keyAccessToken);
    await sharedPreferences.remove(_keyRefreshToken);
    await sharedPreferences.remove(_keyExpiresIn);
    await sharedPreferences.remove(_keyUserData);
    await sharedPreferences.remove(_keyRememberMe);
    await sharedPreferences.remove(_keyDefaultWarehouseCode);
  }

  @override
  Future<String?> getStoredDefaultWarehouseCode() async {
    final v = sharedPreferences.getString(_keyDefaultWarehouseCode);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }
}
