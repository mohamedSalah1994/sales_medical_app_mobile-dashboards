/// ERP customer from GET /api/Erp/customers (for cardCode dropdown).
class ErpCustomerModel {
  const ErpCustomerModel({
    required this.code,
    this.name,
    this.foreignName,
    this.address,
    this.city,
    this.phone,
    this.email,
    this.balance,
    this.cardType = '',
  });

  final String code;
  final String? name;
  final String? foreignName;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;

  /// Account balance when the API provides it (AR/credit).
  final double? balance;

  /// ODBC/BP `cardType`: `C` = customer, `L` = lead.
  final String cardType;

  static double? _parseBalance(Map<String, dynamic> json) {
    const keys = [
      'balance',
      'currentBalance',
      'cardBalance',
      'openBalance',
      'accountBalance',
    ];
    for (final key in keys) {
      final v = json[key];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
    }
    return null;
  }

  factory ErpCustomerModel.fromJson(Map<String, dynamic> json) {
    return ErpCustomerModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String?,
      foreignName: (json['cardForeignName'] ?? json['foreignName']) as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      balance: _parseBalance(json),
      cardType: json['cardType']?.toString() ?? '',
    );
  }
}
