import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({required this.getWalletUseCase}) : super(WalletState.initial());

  final GetWalletUseCase getWalletUseCase;

  Future<void> loadWallet({int skip = 0, int take = 20}) async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final wallet = await getWalletUseCase(
        GetWalletParams(skip: skip, take: take),
      );
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, wallet: wallet, clearError: true));
      }
    } on Failure catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, errorMessage: e.message));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to load wallet',
          ),
        );
      }
    }
  }
}
