import 'package:sales_medical_app_mobile/core/utils/json_parsing.dart';

class SupervisorModel {
  const SupervisorModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.roleName,
    required this.subordinatesCount,
    this.territoryId,
    this.territoryName,
  });

  final String id;
  final String fullName;
  final String username;
  final String roleName;
  final int subordinatesCount;
  final int? territoryId;
  final String? territoryName;

  factory SupervisorModel.fromJson(Map<String, dynamic> json) {
    return SupervisorModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      subordinatesCount: json['subordinatesCount'] as int? ?? 0,
      territoryId: parseOptionalInt(json['territoryId']),
      territoryName: json['territoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'roleName': roleName,
      'subordinatesCount': subordinatesCount,
      if (territoryId != null) 'territoryId': territoryId,
      if (territoryName != null) 'territoryName': territoryName,
    };
  }
}
