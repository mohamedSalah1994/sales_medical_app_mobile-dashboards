import 'package:sales_medical_app_mobile/features/wallet/domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.accountCode,
    required super.projectCode,
    required super.balance,
    super.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      accountCode: (json['accountCode'] as String?) ?? '',
      projectCode: (json['projectCode'] as String?) ?? '',
      balance: _parseDouble(json['balance']),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) =>
                  WalletTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.transId,
    required super.lineId,
    required super.refDate,
    required super.debit,
    required super.credit,
    required super.net,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      transId: (json['transId'] as num?)?.toInt() ?? 0,
      lineId: (json['lineId'] as num?)?.toInt() ?? 0,
      refDate: _parseDate(json['refDate']),
      debit: _parseDouble(json['debit']),
      credit: _parseDouble(json['credit']),
      net: _parseDouble(json['net']),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}
