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
    this.compact = false,
  });

  final bool isTablet;
  final bool isDesktop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final wallet = state.wallet;
        final hasError = state.errorMessage != null && wallet == null;

        final padding = compact
            ? 10.0
            : (isDesktop
                ? 20.0
                : isTablet
                    ? 18.0
                    : 16.0);
        final radius = compact ? 10.0 : (isDesktop ? 16.0 : 12.0);
        final iconBoxPadding = compact ? 6.0 : (isDesktop ? 12.0 : 10.0);
        final iconSize = compact
            ? 18.0
            : (isDesktop
                ? 32.0
                : isTablet
                    ? 28.0
                    : 24.0);
        final titleSize = compact ? 10.0 : (isTablet ? 13.0 : 12.0);
        final balanceSize = compact
            ? 18.0
            : (isDesktop
                ? 26.0
                : isTablet
                    ? 24.0
                    : 22.0);
        final contextSize = compact ? 9.0 : 11.0;
        final rowGap = compact ? 8.0 : (isDesktop ? 16.0 : 12.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.22),
                blurRadius: compact ? 6 : (isDesktop ? 12 : 8),
                offset: Offset(0, compact ? 2 : (isDesktop ? 4 : 3)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconBoxPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(compact ? 8 : (isDesktop ? 12 : 10)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: rowGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.walletTitle,
                      style: TextStyle(
                        fontSize: titleSize,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    if (state.isLoading && wallet == null)
                      _buildLoadingIndicator(compact: compact)
                    else if (hasError)
                      Text(
                        l10n.walletLoadFailed,
                        style: TextStyle(
                          fontSize: compact ? 10 : (isTablet ? 13 : 12),
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
                          fontSize: balanceSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (wallet != null && _hasContextInfo(wallet)) ...[
                      SizedBox(height: compact ? 3 : 6),
                      Text(
                        _contextLabel(l10n, wallet),
                        style: TextStyle(
                          fontSize: contextSize,
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
                padding: compact ? EdgeInsets.zero : null,
                constraints: compact
                    ? const BoxConstraints(minWidth: 32, minHeight: 32)
                    : null,
                visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                onPressed: state.isLoading
                    ? null
                    : () => context.read<WalletCubit>().loadWallet(),
                icon: Icon(
                  Icons.refresh,
                  size: compact ? 18 : 24,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator({bool compact = false}) {
    final size = compact ? 16.0 : 22.0;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: compact ? 1.8 : 2,
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
