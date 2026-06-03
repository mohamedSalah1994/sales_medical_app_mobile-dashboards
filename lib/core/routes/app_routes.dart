import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';
import 'package:sales_medical_app_mobile/core/theme/app_colors.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:sales_medical_app_mobile/features/home/presentation/pages/home_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (context) => const AuthPage());

      case home:
        return MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) async {
              if (didPop) return;
              final l10n = AppLocalizations.of(context);
              final exit = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n?.exitApp ?? 'Exit app?'),
                  content: Text(
                    l10n?.exitAppConfirmation ??
                        'Are you sure you want to exit?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        l10n?.exit ?? 'Exit',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (exit == true && context.mounted) {
                SystemNavigator.pop();
              }
            },
            child: const HomePage(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
