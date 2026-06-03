class VatCodeModel {
  const VatCodeModel({
    required this.code,
    this.name,
  });

  final String code;
  final String? name;

  factory VatCodeModel.fromJson(Map<String, dynamic> json) {
    return VatCodeModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String?,
    );
  }
}
