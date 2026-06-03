import 'dart:async';
import 'dart:ui' as ui;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_medical_app_mobile/core/di/service_locator.dart';
import 'package:sales_medical_app_mobile/core/navigation/app_navigator_key.dart';
import 'package:sales_medical_app_mobile/core/localization/language_cubit.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/routes/app_routes.dart';
import 'package:sales_medical_app_mobile/core/theme/app_theme.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/widgets/active_visit_banner.dart';
import 'package:sales_medical_app_mobile/l10n/app_localizations.dart';

void _showErrorToUser(String message) {
  if (!WidgetsBinding.instance.isRootWidgetAttached) return;
  final ctx = appNavigatorKey.currentContext;
  if (ctx != null && ctx.mounted) {
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }
}

void _handleFlutterError(FlutterErrorDetails details) {
  if (kDebugMode) {
    FlutterError.dumpErrorToConsole(details);
  }
  _showErrorToUser('Something went wrong. Please try again.');
}

void _handleZoneError(Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint('Uncaught (zone/async): $error');
    debugPrintStack(stackTrace: stackTrace, label: 'Stack trace: ');
  }
  _showErrorToUser('Something went wrong. Please try again.');
}

void main() {
  // ensureInitialized must run in the same zone as runApp (see runZonedGuarded below).
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = _handleFlutterError;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please go back or try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    };

    ui.PlatformDispatcher.instance.onError = (
      Object error,
      StackTrace stackTrace,
    ) {
      _handleZoneError(error, stackTrace);
      return true;
    };

    await initServiceLocator();
    runApp(const MyApp());
  }, _handleZoneError);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LanguageCubit>()),
        BlocProvider(
          create:
              (_) => AuthCubit(
                loginUseCase: sl<LoginUseCase>(),
                logoutUseCase: sl<LogoutUseCase>(),
                checkAuthUseCase: sl<CheckAuthUseCase>(),
              )..checkAuth(),
        ),
        BlocProvider<JourneyPlanCubit>(create: (_) => sl<JourneyPlanCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen:
            (prev, curr) => prev.isAuthenticated && !curr.isAuthenticated,
        listener: (context, state) {
          context.read<JourneyPlanCubit>().reset();
        },
        child: _AppView(navigatorKey: appNavigatorKey),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<ApiService>().setOnUnauthorized(_handleUnauthorizedSilently);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On a 401, silently log the user out and return to login — no dialog,
  /// no message.
  void _handleUnauthorizedSilently() {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ctx.mounted) return;
      await ctx.read<AuthCubit>().logout();
      sl<ApiService>().resetUnauthorizedHandling();
      if (ctx.mounted) {
        Navigator.of(ctx).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!mounted) return;
      context.read<JourneyPlanCubit>().persistActiveVisitSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return MaterialApp(
          navigatorKey: widget.navigatorKey,
          title: 'DKT Sales APP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: languageState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale.languageCode) {
                  return supported;
                }
              }
            }
            return const Locale('en');
          },
          onGenerateRoute: AppRoutes.generateRoute,
          home: const _AuthGate(),
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            return Directionality(
              textDirection:
                  languageState.locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child: BotToastInit()(
                context,
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    content,
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: BlocBuilder<AuthCubit, AuthState>(
                        buildWhen:
                            (p, c) => p.isAuthenticated != c.isAuthenticated,
                        builder: (context, authState) {
                          if (!authState.isAuthenticated) {
                            return const SizedBox.shrink();
                          }
                          return SafeArea(
                            bottom: false,
                            child: ActiveVisitBanner(
                              floating: true,
                              onOpen:
                                  () =>
                                      openActiveVisitFromGlobalOverlay(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          navigatorObservers: [BotToastNavigatorObserver()],
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen:
          (previous, current) =>
              previous.isAuthenticated != current.isAuthenticated ||
              previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        // Show loading while checking auth
        if (state.isSubmitting && !state.isAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Navigate based on auth state
        if (state.isAuthenticated && state.loginResponse != null) {
          // User is authenticated, navigate to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated, navigate to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
