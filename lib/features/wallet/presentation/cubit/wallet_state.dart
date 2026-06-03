import 'package:equatable/equatable.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/entities/wallet.dart';

class WalletState extends Equatable {
  const WalletState({
    required this.isLoading,
    this.wallet,
    this.errorMessage,
  });

  final bool isLoading;
  final Wallet? wallet;
  final String? errorMessage;

  factory WalletState.initial() {
    return const WalletState(isLoading: false);
  }

  WalletState copyWith({
    bool? isLoading,
    Wallet? wallet,
    String? errorMessage,
    bool clearError = false,
    bool clearWallet = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      wallet: clearWallet ? null : (wallet ?? this.wallet),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, wallet, errorMessage];
}
