import 'package:sales_medical_app_mobile/features/reports/domain/entities/stock_availability.dart';

class StockAvailabilityModel extends StockAvailability {
  const StockAvailabilityModel({
    required super.itemCode,
    required super.itemName,
    required super.warehouseCode,
    required super.onHand,
    required super.committed,
    required super.onOrder,
    required super.available,
  });

  factory StockAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return StockAvailabilityModel(
      itemCode: _string(json['itemCode'] ?? json['ItemCode']),
      itemName: _string(json['itemName'] ?? json['ItemName']),
      warehouseCode: _string(json['warehouseCode'] ?? json['WarehouseCode']),
      onHand: _double(json['onHand'] ?? json['OnHand']),
      committed: _double(json['committed'] ?? json['Committed']),
      onOrder: _double(json['onOrder'] ?? json['OnOrder']),
      available: _double(json['available'] ?? json['Available']),
    );
  }
}

String _string(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

double _double(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}
