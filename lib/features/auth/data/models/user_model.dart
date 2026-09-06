import 'package:sales_medical_app_mobile/core/utils/json_parsing.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.email,
    required super.role,
    required super.subRoles,
    super.territoryId,
    super.territoryName,
    super.supervisorId,
    super.supervisorName,
    super.sapSalesEmployeeCode,
    super.defaultWarehouseCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      subRoles:
          (json['subRoles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      territoryId: parseOptionalString(json['territoryId']),
      territoryName: parseOptionalString(json['territoryName']),
      supervisorId: json['supervisorId'] as String?,
      supervisorName: json['supervisorName'] as String?,
      sapSalesEmployeeCode: json['sapSalesEmployeeCode'] as int?,
      defaultWarehouseCode: json['defaultWarehouseCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'subRoles': subRoles,
      if (territoryId != null) 'territoryId': territoryId,
      if (territoryName != null) 'territoryName': territoryName,
      if (supervisorId != null) 'supervisorId': supervisorId,
      if (supervisorName != null) 'supervisorName': supervisorName,
      if (sapSalesEmployeeCode != null)
        'sapSalesEmployeeCode': sapSalesEmployeeCode,
      if (defaultWarehouseCode != null && defaultWarehouseCode!.isNotEmpty)
        'defaultWarehouseCode': defaultWarehouseCode,
    };
  }
}
