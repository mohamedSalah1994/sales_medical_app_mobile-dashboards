import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/widgets/auth_form.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen:
          (prev, curr) =>
              prev.isSuccess != curr.isSuccess ||
              prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isSuccess && state.loginResponse != null) {
          BotToast.showText(
            text: l10n.signedInSuccessfully,
            duration: const Duration(seconds: 2),
            contentColor: AppColors.success,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            align: Alignment.bottomCenter,
          );
          // Navigate to home immediately since we're now using the global AuthCubit
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && state.loginResponse != null) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushReplacementNamed('/home');
            }
          });
        } else if (state.errorMessage != null) {
          BotToast.showText(
            text: state.errorMessage!,
            duration: const Duration(seconds: 4),
            contentColor: AppColors.error,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
            align: Alignment.topCenter,
          );
        }
      },
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 20,
              vertical: MediaQuery.of(context).size.width < 360 ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome section with improved styling
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeBack,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                          fontSize:
                              MediaQuery.of(context).size.width < 360 ? 20 : 22,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.signInToContinue,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                ),
                const AuthForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
