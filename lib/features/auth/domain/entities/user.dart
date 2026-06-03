import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.subRoles,
    this.territoryId,
    this.territoryName,
    this.supervisorId,
    this.supervisorName,
    this.sapSalesEmployeeCode,
    this.defaultWarehouseCode,
  });

  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final List<String> subRoles;
  final int? territoryId;
  final String? territoryName;
  final String? supervisorId;
  final String? supervisorName;

  /// SAP sales employee code; used as salesEmployeeCode when calling GET /api/Erp/customers.
  final int? sapSalesEmployeeCode;

  /// Default warehouse from login; persisted for stock transfer "from" warehouse.
  final String? defaultWarehouseCode;

  @override
  List<Object?> get props => [
    id,
    username,
    fullName,
    email,
    role,
    subRoles,
    territoryId,
    territoryName,
    supervisorId,
    supervisorName,
    sapSalesEmployeeCode,
    defaultWarehouseCode,
  ];
}
