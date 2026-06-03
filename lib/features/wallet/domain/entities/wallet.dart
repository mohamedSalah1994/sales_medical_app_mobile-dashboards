import 'package:equatable/equatable.dart';

/// Sales employee wallet, returned by GET /api/Reports/wallet.
///
/// The wallet ties the logged-in salesman to their SAP account/project pair
/// and exposes the running balance plus the underlying transaction lines.
class Wallet extends Equatable {
  const Wallet({
    required this.accountCode,
    required this.projectCode,
    required this.balance,
    this.transactions = const [],
  });

  final String accountCode;
  final String projectCode;
  final double balance;
  final List<WalletTransaction> transactions;

  @override
  List<Object?> get props => [accountCode, projectCode, balance, transactions];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.transId,
    required this.lineId,
    required this.refDate,
    required this.debit,
    required this.credit,
    required this.net,
  });

  final int transId;
  final int lineId;
  final DateTime? refDate;
  final double debit;
  final double credit;
  final double net;

  @override
  List<Object?> get props => [transId, lineId, refDate, debit, credit, net];
}
