import 'package:equatable/equatable.dart';

/// One row of the GET /api/Reports/stock-availability response.
///
/// Quantities default to 0 when the API omits a field.
class StockAvailability extends Equatable {
  const StockAvailability({
    required this.itemCode,
    required this.itemName,
    required this.warehouseCode,
    required this.onHand,
    required this.committed,
    required this.onOrder,
    required this.available,
  });

  final String itemCode;
  final String itemName;
  final String warehouseCode;
  final double onHand;
  final double committed;
  final double onOrder;
  final double available;

  @override
  List<Object?> get props => [
        itemCode,
        itemName,
        warehouseCode,
        onHand,
        committed,
        onOrder,
        available,
      ];
}
