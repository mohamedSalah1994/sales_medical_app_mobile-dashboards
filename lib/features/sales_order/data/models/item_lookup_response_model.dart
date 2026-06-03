/// Page size for `GET /api/MasterData/items/lookup-odbc` (`take` query).
const int kOdbcItemLookupTake = 10;

/// ODBC / SAP JSON often sends `code` / `productCode` as int; normalize for lookups.
String itemLookupStringField(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  return value.toString().trim();
}

/// `stock` array on an ODBC lookup row or root object.
List<Map<String, dynamic>>? parseItemLookupStockRows(dynamic raw) {
  if (raw is! List) return null;
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map) {
      out.add(Map<String, dynamic>.from(e));
    }
  }
  return out.isEmpty ? null : out;
}

/// Quantity from a `stock[]` row for display and [ItemProductModel.onHand].
/// Prefers `onHand` / `inStock` over `available` or `value` when the API sends multiple.
num? itemLookupStockDisplayQuantity(Map<String, dynamic> row) {
  for (final key in ['onHand', 'inStock', 'available', 'value']) {
    final v = row[key];
    if (v == null) continue;
    if (v is num) return v;
    if (v is String) {
      final parsed = num.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

ItemProductModel itemProductWithWarehouseStock(
  ItemProductModel base, {
  required num? onHandOverride,
  required String? warehouseOverride,
}) {
  return ItemProductModel(
    code: base.code,
    name: base.name,
    barcode: base.barcode,
    category: base.category,
    unitOfMeasure: base.unitOfMeasure,
    tracksBatches: base.tracksBatches,
    isActive: base.isActive,
    defaultPrice: base.defaultPrice,
    onHand: onHandOverride ?? base.onHand,
    onHandWarehouseCode: warehouseOverride ?? base.onHandWarehouseCode,
  );
}

/// One UoM option from lookup response uoMs array.
class ItemUoMModel {
  const ItemUoMModel({this.uoMEntry, required this.uoMCode, this.name});

  final int? uoMEntry;
  final String uoMCode;
  final String? name;

  factory ItemUoMModel.fromJson(Map<String, dynamic> json) {
    return ItemUoMModel(
      uoMEntry: json['uoMEntry'] as int?,
      uoMCode: (json['uoMCode'] as String? ?? '').toString(),
      name: json['name'] as String?,
    );
  }
}

/// One row from ODBC lookup (product + that row's uoMs / price).
class ItemLookupRowBundle {
  const ItemLookupRowBundle({
    required this.product,
    this.uoMs,
    this.price,
    this.stockRows,
  });

  final ItemProductModel product;
  final List<ItemUoMModel>? uoMs;
  final num? price;

  /// Per-warehouse lines from `stock` on the same ODBC object (optional).
  final List<Map<String, dynamic>>? stockRows;

  /// One bundle per distinct `warehouseCode` when [stockRows] has multiple
  /// warehouses; otherwise a single bundle with merged availability.
  List<ItemLookupRowBundle> expandForWarehousePick() {
    final stocks = stockRows;
    if (stocks == null || stocks.isEmpty) {
      return [this];
    }
    final groups = <String, Map<String, dynamic>>{};
    for (final e in stocks) {
      final wh = itemLookupStringField(e['warehouseCode']);
      final key = wh.isEmpty ? '_' : wh;
      groups.putIfAbsent(key, () => e);
    }
    if (groups.length <= 1) {
      final entry = groups.values.first;
      final qty = itemLookupStockDisplayQuantity(entry);
      final whRaw = itemLookupStringField(entry['warehouseCode']);
      final wh = whRaw.isEmpty ? null : whRaw;
      return [
        ItemLookupRowBundle(
          product: itemProductWithWarehouseStock(
            product,
            onHandOverride: qty,
            warehouseOverride: wh,
          ),
          uoMs: uoMs,
          price: price,
          stockRows: null,
        ),
      ];
    }
    return groups.entries.map((e) {
      final entry = e.value;
      final qty = itemLookupStockDisplayQuantity(entry);
      final whRaw = itemLookupStringField(entry['warehouseCode']);
      final wh = whRaw.isEmpty ? null : whRaw;
      return ItemLookupRowBundle(
        product: itemProductWithWarehouseStock(
          product,
          onHandOverride: qty,
          warehouseOverride: wh,
        ),
        uoMs: uoMs,
        price: price,
        stockRows: null,
      );
    }).toList();
  }

  factory ItemLookupRowBundle.fromRowJson(Map<String, dynamic> json) {
    final uoMsRaw = json['uoMs'];
    final uoMsList =
        uoMsRaw is List
            ? uoMsRaw
                .whereType<Map<String, dynamic>>()
                .map((e) => ItemUoMModel.fromJson(e))
                .toList()
            : <ItemUoMModel>[];
    final pRaw = json['product'];
    if (pRaw is! Map) {
      throw ArgumentError('Item lookup row missing product');
    }
    final product = ItemProductModel.fromJson(Map<String, dynamic>.from(pRaw));
    return ItemLookupRowBundle(
      product: product,
      uoMs: uoMsList.isEmpty ? null : uoMsList,
      price: ItemLookupResponseModel.parseLookupPrice(json['price']),
      stockRows: parseItemLookupStockRows(json['stock']),
    );
  }
}

class ItemLookupResponseModel {
  const ItemLookupResponseModel({
    this.product,
    this.products,
    this.rows,
    this.batches,
    this.stock,
    this.price,
    this.uoMs,
  });

  final ItemProductModel? product;

  /// When API returns multiple matches (`products[]`) inside one object.
  final List<ItemProductModel>? products;

  /// ODBC list response: one bundle per array element; or single-map response.
  final List<ItemLookupRowBundle>? rows;
  final dynamic batches;
  final dynamic stock;
  final num? price;
  final List<ItemUoMModel>? uoMs;

  /// ODBC may return `price` as a number or `{ "price": n, ... }`.
  static num? parseLookupPrice(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    if (raw is Map) {
      final v = raw['price'];
      if (v is num) return v;
    }
    return null;
  }

  factory ItemLookupResponseModel.fromJson(Map<String, dynamic> json) {
    final uoMsRaw = json['uoMs'];
    final uoMsList =
        uoMsRaw is List
            ? uoMsRaw
                .whereType<Map<String, dynamic>>()
                .map((e) => ItemUoMModel.fromJson(e))
                .toList()
            : <ItemUoMModel>[];
    List<ItemProductModel>? productsList;
    final pr = json['products'];
    if (pr is List) {
      productsList =
          pr
              .whereType<Map<String, dynamic>>()
              .map(ItemProductModel.fromJson)
              .toList();
    }
    final parsedPrice = parseLookupPrice(json['price']);
    final product =
        json['product'] != null
            ? ItemProductModel.fromJson(json['product'] as Map<String, dynamic>)
            : null;

    List<ItemLookupRowBundle>? rowBundles;
    if (productsList != null && productsList.isNotEmpty) {
      rowBundles = null;
    } else if (product != null) {
      rowBundles = [
        ItemLookupRowBundle(
          product: product,
          uoMs: uoMsList.isEmpty ? null : uoMsList,
          price: parsedPrice,
        ),
      ];
    }

    return ItemLookupResponseModel(
      product: product,
      products: productsList,
      rows: rowBundles,
      batches: json['batches'],
      stock: json['stock'],
      price: parsedPrice,
      uoMs: uoMsList.isEmpty ? null : uoMsList,
    );
  }

  factory ItemLookupResponseModel.fromOdbcList(List<dynamic> list) {
    final rows = <ItemLookupRowBundle>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        rows.add(ItemLookupRowBundle.fromRowJson(Map<String, dynamic>.from(e)));
      } catch (_) {
        continue;
      }
    }
    return ItemLookupResponseModel(
      rows: rows,
      product: null,
      products: null,
      batches: null,
      stock: null,
      price: null,
      uoMs: null,
    );
  }

  /// Handles array body `[{ product, uoMs, ... }, ...]` or single object map.
  factory ItemLookupResponseModel.fromOdbcAny(dynamic data) {
    if (data is List) {
      return ItemLookupResponseModel.fromOdbcList(data);
    }
    if (data is Map) {
      return ItemLookupResponseModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid item lookup response');
  }

  /// Rows returned by the API for the current page (for `skip` / `take`), before
  /// warehouse expansion.
  int rawMatchCountForPagination() {
    if (rows != null && rows!.isNotEmpty) return rows!.length;
    if (products != null && products!.isNotEmpty) return products!.length;
    if (product != null) return 1;
    return 0;
  }

  /// Rows to show in the item picker or add as a line: expands each ODBC row by
  /// distinct `stock[].warehouseCode` when needed. Single bundle → add directly.
  List<ItemLookupRowBundle> expandedLinePickBundles() {
    if (rows != null && rows!.isNotEmpty) {
      final out = <ItemLookupRowBundle>[];
      for (final r in rows!) {
        out.addAll(r.expandForWarehousePick());
      }
      return out;
    }
    if (products != null && products!.isNotEmpty) {
      return products!
          .map(
            (p) => ItemLookupRowBundle(
              product: p,
              uoMs: uoMs,
              price: price,
              stockRows: null,
            ),
          )
          .toList();
    }
    if (product != null) {
      final bundle = ItemLookupRowBundle(
        product: product!,
        uoMs: uoMs,
        price: price,
        stockRows: parseItemLookupStockRows(stock),
      );
      return bundle.expandForWarehousePick();
    }
    return [];
  }

  ItemLookupRowBundle? rowForProductCode(String code) {
    if (rows == null) return null;
    for (final r in rows!) {
      if (r.product.code == code) return r;
    }
    return null;
  }

  /// Same as [pickableProducts] but at most one entry per non-empty [ItemProductModel.code]
  /// (first occurrence wins). Use this to decide single-row add vs multi-picker dialog.
  List<ItemProductModel> pickableProductsDistinctByCode() {
    final flat = pickableProducts();
    final byCode = <String, ItemProductModel>{};
    for (final p in flat) {
      final c = p.code.trim();
      if (c.isEmpty) continue;
      byCode.putIfAbsent(c, () => p);
    }
    return byCode.values.toList();
  }

  /// First [ItemLookupRowBundle] per distinct product code from [rows] (stable order).
  List<ItemLookupRowBundle> distinctLookupRowBundles() {
    if (rows == null || rows!.isEmpty) return [];
    final seen = <String>{};
    final out = <ItemLookupRowBundle>[];
    for (final r in rows!) {
      final c = r.product.code.trim();
      if (c.isEmpty || seen.contains(c)) continue;
      seen.add(c);
      out.add(r);
    }
    return out;
  }

  /// Candidates to add as a line: ODBC [rows], API `products`, stock rows, or single [product].
  List<ItemProductModel> pickableProducts() {
    if (rows != null && rows!.isNotEmpty) {
      return rows!.map((r) => r.product).toList();
    }
    if (products != null && products!.isNotEmpty) {
      return List<ItemProductModel>.from(products!);
    }
    final fromStock = _pickableFromDistinctStock();
    if (fromStock.length > 1) {
      return fromStock;
    }
    if (product != null) {
      return [product!];
    }
    if (fromStock.length == 1) {
      return fromStock;
    }
    return [];
  }

  List<ItemProductModel> _pickableFromDistinctStock() {
    if (stock is! List) return [];
    final firstRowByCode = <String, Map<String, dynamic>>{};
    for (final e in stock as List) {
      if (e is! Map<String, dynamic>) continue;
      final pc = itemLookupStringField(e['productCode']);
      if (pc.isEmpty) continue;
      firstRowByCode.putIfAbsent(pc, () => e);
    }
    if (firstRowByCode.length < 2) {
      return [];
    }
    return firstRowByCode.entries.map((e) {
      final row = e.value;
      final qty = itemLookupStockDisplayQuantity(row);
      final isMain = product != null && product!.code == e.key;
      return ItemProductModel(
        code: e.key,
        name: isMain ? (product!.name ?? e.key) : e.key,
        barcode: isMain ? product!.barcode : null,
        category: isMain ? product!.category : null,
        unitOfMeasure: isMain ? product!.unitOfMeasure : null,
        tracksBatches: isMain ? product!.tracksBatches : null,
        isActive: isMain ? product!.isActive : null,
        defaultPrice: isMain ? product!.defaultPrice : null,
        onHand: isMain ? (product!.onHand ?? qty) : qty,
        onHandWarehouseCode: isMain ? product!.onHandWarehouseCode : null,
      );
    }).toList();
  }
}

class ItemProductModel {
  const ItemProductModel({
    required this.code,
    this.name,
    this.barcode,
    this.category,
    this.unitOfMeasure,
    this.tracksBatches,
    this.isActive,
    this.defaultPrice,
    this.onHand,
    this.onHandWarehouseCode,
  });

  final String code;
  final String? name;
  final String? barcode;
  final String? category;
  final String? unitOfMeasure;
  final bool? tracksBatches;
  final bool? isActive;
  final num? defaultPrice;

  /// Present on ODBC item lookup (`/api/MasterData/items/lookup-odbc`).
  final num? onHand;
  final String? onHandWarehouseCode;

  factory ItemProductModel.fromJson(Map<String, dynamic> json) {
    return ItemProductModel(
      code: itemLookupStringField(json['code']),
      name: json['name'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unitOfMeasure: json['unitOfMeasure'] as String?,
      tracksBatches: json['tracksBatches'] as bool?,
      isActive: json['isActive'] as bool?,
      defaultPrice: json['defaultPrice'] as num?,
      onHand:
          itemLookupStockDisplayQuantity(Map<String, dynamic>.from(json)) ??
          json['onHand'] as num?,
      onHandWarehouseCode: json['onHandWarehouseCode'] as String?,
    );
  }
}
