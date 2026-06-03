import 'package:sales_medical_app_mobile/features/reports/domain/entities/erp_warehouse.dart';

class ErpWarehouseModel extends ErpWarehouse {
  const ErpWarehouseModel({
    required super.code,
    required super.name,
  });

  factory ErpWarehouseModel.fromJson(Map<String, dynamic> json) {
    return ErpWarehouseModel(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
    );
  }
}
