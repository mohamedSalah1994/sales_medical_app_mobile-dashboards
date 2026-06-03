import 'package:sales_medical_app_mobile/core/utils/json_parsing.dart';

class SubordinateModel {
  const SubordinateModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.roleId,
    required this.roleName,
    required this.supervisorId,
    required this.supervisorName,
    required this.sapSalesEmployeeCode,
    this.territoryId,
    required this.territoryName,
    required this.isAssigned,
    required this.subRoles,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final bool isActive;
  final String roleId;
  final String roleName;
  final String supervisorId;
  final String supervisorName;
  final int sapSalesEmployeeCode;
  final int? territoryId;
  final String territoryName;
  final bool isAssigned;
  final List<String> subRoles;
  final DateTime createdAt;

  factory SubordinateModel.fromJson(Map<String, dynamic> json) {
    return SubordinateModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      roleId: json['roleId'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      supervisorId: json['supervisorId'] as String? ?? '',
      supervisorName: json['supervisorName'] as String? ?? '',
      sapSalesEmployeeCode: json['sapSalesEmployeeCode'] as int? ?? 0,
      territoryId: parseOptionalInt(json['territoryId']),
      territoryName: json['territoryName'] as String? ?? '',
      isAssigned: json['isAssigned'] as bool? ?? false,
      subRoles:
          (json['subRoles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'roleId': roleId,
      'roleName': roleName,
      'supervisorId': supervisorId,
      'supervisorName': supervisorName,
      'sapSalesEmployeeCode': sapSalesEmployeeCode,
      if (territoryId != null) 'territoryId': territoryId,
      'territoryName': territoryName,
      'isAssigned': isAssigned,
      'subRoles': subRoles,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
