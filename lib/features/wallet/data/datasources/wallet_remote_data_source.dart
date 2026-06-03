import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/features/wallet/data/models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  /// GET /api/Reports/wallet — returns the logged-in salesman's account/project
  /// balance plus paginated transaction lines.
  Future<WalletModel> getWallet({int skip = 0, int take = 20});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<WalletModel> getWallet({int skip = 0, int take = 20}) async {
    final response = await apiService.get(
      '/api/Reports/wallet',
      queryParameters: <String, dynamic>{
        'skip': skip,
        'take': take,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return WalletModel.fromJson(data);
    }
    if (data is Map) {
      return WalletModel.fromJson(Map<String, dynamic>.from(data));
    }
    return const WalletModel(
      accountCode: '',
      projectCode: '',
      balance: 0,
    );
  }
}
