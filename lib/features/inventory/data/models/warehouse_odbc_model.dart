class WarehouseOdbcModel {
  const WarehouseOdbcModel({
    required this.code,
    this.name,
  });

  final String code;
  final String? name;

  factory WarehouseOdbcModel.fromJson(Map<String, dynamic> json) {
    return WarehouseOdbcModel(
      code: (json['code'] as String? ?? '').toString(),
      name: json['name'] as String?,
    );
  }

  String get displayLabel =>
      name != null && name!.isNotEmpty ? '$code — $name' : code;
}
