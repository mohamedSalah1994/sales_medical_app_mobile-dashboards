import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/entities/wallet.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required this.remoteDataSource});

  final WalletRemoteDataSource remoteDataSource;

  @override
  Future<Wallet> getWallet({int skip = 0, int take = 20}) async {
    try {
      return await remoteDataSource.getWallet(skip: skip, take: take);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
