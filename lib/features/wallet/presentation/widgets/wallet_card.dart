import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

/// Compact wallet panel rendered on the home dashboard for sales employees.
///
/// Surfaces the salesman's running balance from GET /api/Reports/wallet plus
/// the resolved SAP account/project pair so they can sanity-check the source
/// of the figure at a glance.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.isTablet,
    required this.isDesktop,
  });

  final bool isTablet;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final wallet = state.wallet;
        final hasError = state.errorMessage != null && wallet == null;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            isDesktop
                ? 20
                : isTablet
                    ? 18
                    : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.25),
                blurRadius: isDesktop ? 12 : 8,
                offset: Offset(0, isDesktop ? 4 : 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: isDesktop
                      ? 32
                      : isTablet
                          ? 28
                          : 24,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.walletTitle,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (state.isLoading && wallet == null)
                      _buildLoadingIndicator()
                    else if (hasError)
                      Text(
                        l10n.walletLoadFailed,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        _formatBalance(wallet?.balance ?? 0),
                        style: TextStyle(
                          fontSize: isDesktop
                              ? 26
                              : isTablet
                                  ? 24
                                  : 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (wallet != null && _hasContextInfo(wallet)) ...[
                      const SizedBox(height: 6),
                      Text(
                        _contextLabel(l10n, wallet),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.walletRefresh,
                onPressed: state.isLoading
                    ? null
                    : () => context.read<WalletCubit>().loadWallet(),
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  static bool _hasContextInfo(dynamic wallet) {
    final account = (wallet?.accountCode ?? '') as String;
    final project = (wallet?.projectCode ?? '') as String;
    return account.isNotEmpty || project.isNotEmpty;
  }

  static String _contextLabel(AppLocalizations l10n, dynamic wallet) {
    final parts = <String>[];
    final account = (wallet?.accountCode ?? '') as String;
    final project = (wallet?.projectCode ?? '') as String;
    if (account.isNotEmpty) {
      parts.add('${l10n.walletAccount}: $account');
    }
    if (project.isNotEmpty) {
      parts.add('${l10n.walletProject}: $project');
    }
    return parts.join(' • ');
  }

  static String _formatBalance(double balance) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(balance).trim();
  }
}
