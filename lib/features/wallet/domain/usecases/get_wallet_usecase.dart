import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/entities/wallet.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/repositories/wallet_repository.dart';

class GetWalletParams {
  const GetWalletParams({this.skip = 0, this.take = 20});

  final int skip;
  final int take;
}

class GetWalletUseCase {
  GetWalletUseCase({required this.repository});

  final WalletRepository repository;

  Future<Wallet> call(GetWalletParams params) async {
    try {
      return await repository.getWallet(skip: params.skip, take: params.take);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
