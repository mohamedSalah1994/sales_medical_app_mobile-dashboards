import 'package:equatable/equatable.dart';

/// Slim warehouse projection used by the warehouse picker for reports.
///
/// Returned by GET /api/Erp/warehouses (paginated).
class ErpWarehouse extends Equatable {
  const ErpWarehouse({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  String get displayLabel =>
      name.isNotEmpty ? '$code — $name' : code;

  @override
  List<Object?> get props => [code, name];
}
