import 'package:sales_medical_app_mobile/features/wallet/domain/entities/wallet.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet({int skip = 0, int take = 20});
}
