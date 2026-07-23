import 'package:sales_medical_app_mobile/features/sales_order/data/models/item_lookup_response_model.dart';

/// GET `/api/erp/inventory-transfer-requests/{docEntry}`
class InventoryTransferDocModel {
  const InventoryTransferDocModel({
    required this.docEntry,
    required this.docNum,
    this.docDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    this.comments,
    this.documentStatus,
    required this.lines,
  });

  final int docEntry;
  final int docNum;
  final String? docDate;
  final String fromWarehouse;
  final String toWarehouse;
  final String? comments;
  final String? documentStatus;
  final List<InventoryTransferLineModel> lines;

  factory InventoryTransferDocModel.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'];
    final lines =
        linesRaw is List
            ? linesRaw
                .whereType<Map<String, dynamic>>()
                .map(InventoryTransferLineModel.fromJson)
                .toList()
            : <InventoryTransferLineModel>[];

    return InventoryTransferDocModel(
      docEntry: (json['docEntry'] as num?)?.toInt() ?? 0,
      docNum: (json['docNum'] as num?)?.toInt() ?? 0,
      docDate: json['docDate'] as String?,
      fromWarehouse: (json['fromWarehouse'] as String? ?? '').toString(),
      toWarehouse: (json['toWarehouse'] as String? ?? '').toString(),
      comments: json['comments'] as String?,
      documentStatus: json['documentStatus'] as String?,
      lines: lines,
    );
  }
}

class InventoryTransferLineModel {
  const InventoryTransferLineModel({
    this.lineNum,
    required this.itemCode,
    this.itemName,
    this.quantity,
    this.uoMEntry,
    this.uoMCode,
  });

  final int? lineNum;
  final String itemCode;
  final String? itemName;
  final num? quantity;
  final int? uoMEntry;
  final String? uoMCode;

  factory InventoryTransferLineModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransferLineModel(
      lineNum: (json['lineNum'] as num?)?.toInt(),
      itemCode: (json['itemCode'] as String? ?? '').toString(),
      itemName: json['itemName'] as String?,
      quantity: json['quantity'] as num?,
      uoMEntry: (json['uoMEntry'] as num?)?.toInt(),
      uoMCode: json['uoMCode'] as String?,
    );
  }
}

/// POST `/api/erp/inventory-transfer-requests`
class CreateInventoryTransferRequestModel {
  const CreateInventoryTransferRequestModel({
    required this.docDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    this.comments,
    required this.stockTransferLines,
  });

  final DateTime docDate;
  final String fromWarehouse;
  final String toWarehouse;
  final String? comments;
  final List<StockTransferLineRequestModel> stockTransferLines;

  Map<String, dynamic> toJson() {
    return {
      'docDate': docDate.toUtc().toIso8601String(),
      'fromWarehouse': fromWarehouse,
      'toWarehouse': toWarehouse,
      'comments': comments ?? '',
      'stockTransferLines': stockTransferLines.map((e) => e.toJson()).toList(),
    };
  }
}

class StockTransferLineRequestModel {
  const StockTransferLineRequestModel({
    required this.itemCode,
    required this.quantity,
    required this.uoMEntry,
  });

  final String itemCode;
  final num quantity;
  final int uoMEntry;

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'quantity': quantity,
      'uoMEntry': uoMEntry,
    };
  }
}

/// One editable line on the create form (from ODBC lookup).
class InventoryLineDraft {
  const InventoryLineDraft({
    required this.itemCode,
    required this.itemName,
    this.onHand,
    this.quantity = 0,
    this.uoMEntry,
    this.uoMCode,
    this.baseUnitOfMeasure,
    this.uoMs = const [],
  });

  final String itemCode;
  final String itemName;
  final num? onHand;
  final num quantity;
  final int? uoMEntry;
  final String? uoMCode;
  /// [ItemProductModel.unitOfMeasure] — shown in table (like sales order default UoM).
  final String? baseUnitOfMeasure;
  final List<ItemUoMModel> uoMs;

  /// Distinct [ItemUoMModel] rows for dropdown (by [ItemUoMModel.uoMCode]).
  List<ItemUoMModel> get uoMsForDropdown {
    final out = <ItemUoMModel>[];
    final seen = <String>{};
    for (final u in uoMs) {
      final c = u.uoMCode.trim();
      if (c.isEmpty) continue;
      if (seen.contains(c)) continue;
      seen.add(c);
      out.add(u);
    }
    return out;
  }

  /// Selected UoM code for UI — matches [SalesOrderPage] dropdown `value` / `selectedItemBuilder`.
  String? get effectiveUoMCode {
    final rows = uoMsForDropdown;
    if (rows.isEmpty) {
      final c = uoMCode?.trim();
      if (c != null && c.isNotEmpty) return c;
      final b = baseUnitOfMeasure?.trim();
      if (b != null && b.isNotEmpty) return b;
      return null;
    }
    final sel = uoMCode?.trim();
    if (sel != null && sel.isNotEmpty && rows.any((u) => u.uoMCode == sel)) {
      return sel;
    }
    if (uoMEntry != null) {
      for (final u in rows) {
        if (u.uoMEntry == uoMEntry) return u.uoMCode;
      }
    }
    return rows.first.uoMCode;
  }

  /// SAP [uoMEntry] for POST — resolved from [effectiveUoMCode].
  int? get resolvedUoMEntry {
    final code = effectiveUoMCode;
    if (code != null) {
      for (final u in uoMs) {
        if (u.uoMCode == code && u.uoMEntry != null) return u.uoMEntry;
      }
    }
    final withEntry = uoMs.where((u) => u.uoMEntry != null).toList();
    if (withEntry.isEmpty) return null;
    if (uoMEntry != null &&
        withEntry.any((u) => u.uoMEntry == uoMEntry)) {
      return uoMEntry;
    }
    return withEntry.first.uoMEntry;
  }

  InventoryLineDraft copyWith({
    String? itemCode,
    String? itemName,
    num? onHand,
    num? quantity,
    int? uoMEntry,
    String? uoMCode,
    String? baseUnitOfMeasure,
    List<ItemUoMModel>? uoMs,
  }) {
    return InventoryLineDraft(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      onHand: onHand ?? this.onHand,
      quantity: quantity ?? this.quantity,
      uoMEntry: uoMEntry ?? this.uoMEntry,
      uoMCode: uoMCode ?? this.uoMCode,
      baseUnitOfMeasure: baseUnitOfMeasure ?? this.baseUnitOfMeasure,
      uoMs: uoMs ?? this.uoMs,
    );
  }

  /// Same UoM merge/default rules as [SalesOrderCubit.itemLookupResultFromProduct].
  static InventoryLineDraft fromProductAndUoMs(
    ItemProductModel product,
    List<ItemUoMModel>? uoMs,
  ) {
    var list = List<ItemUoMModel>.from(uoMs ?? <ItemUoMModel>[]);
    final defaultUom = product.unitOfMeasure?.trim().isNotEmpty == true
        ? product.unitOfMeasure!.trim()
        : null;

    if (defaultUom != null && list.isNotEmpty) {
      final hasProductUom = list.any((u) => u.uoMCode == defaultUom);
      if (!hasProductUom) {
        list = [
          ItemUoMModel(uoMEntry: null, uoMCode: defaultUom, name: null),
          ...list,
        ];
      }
    }

    ItemUoMModel? selected;
    if (list.isNotEmpty) {
      if (defaultUom != null) {
        final withEntry =
            list.where((u) => u.uoMCode == defaultUom && u.uoMEntry != null).toList();
        if (withEntry.isNotEmpty) {
          selected = withEntry.first;
        } else {
          final any = list.where((u) => u.uoMCode == defaultUom).toList();
          if (any.isNotEmpty) selected = any.first;
        }
      }
      selected ??=
          list.where((u) => u.uoMEntry != null).firstOrNull ?? list.first;
    }

    final selPick = selected;
    if (selPick != null && selPick.uoMEntry == null) {
      final real =
          list
              .where(
                (u) => u.uoMEntry != null && u.uoMCode == selPick.uoMCode,
              )
              .toList();
      if (real.isNotEmpty) {
        selected = real.first;
      } else {
        final fb = list.where((u) => u.uoMEntry != null).firstOrNull;
        if (fb != null) selected = fb;
      }
    }

    return InventoryLineDraft(
      itemCode: product.code,
      itemName: product.name ?? product.code,
      onHand: product.onHand,
      quantity: 0,
      uoMEntry: selected?.uoMEntry,
      uoMCode: selected?.uoMCode ?? defaultUom,
      baseUnitOfMeasure: defaultUom,
      uoMs: list,
    );
  }
}

extension _FirstOrNullIterable<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
