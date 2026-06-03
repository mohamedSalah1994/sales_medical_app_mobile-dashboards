/// Row from GET /api/MasterData/customer-types (code/name) or plain-string
/// lists from `/api/MasterData/area-udt/*`.
class MasterDataOptionModel {
  const MasterDataOptionModel({
    required this.code,
    required this.name,
    this.parent,
  });

  final String code;
  final String name;
  final String? parent;

  factory MasterDataOptionModel.fromJson(Map<String, dynamic> json) {
    return MasterDataOptionModel(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      parent: json['parent']?.toString(),
    );
  }

  /// GET /api/MasterData/area-udt/* returns a JSON array of plain strings.
  factory MasterDataOptionModel.fromPlainString(String value) {
    final v = value.trim();
    return MasterDataOptionModel(code: v, name: v);
  }
}
