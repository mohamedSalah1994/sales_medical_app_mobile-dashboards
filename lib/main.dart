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
import 'package:sales_medical_app_mobile/core/network/force_update_gate.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_info.dart';
import 'package:sales_medical_app_mobile/core/routes/app_routes.dart';
import 'package:sales_medical_app_mobile/core/theme/app_theme.dart';
import 'package:sales_medical_app_mobile/core/utils/app_version.dart';
import 'package:sales_medical_app_mobile/core/utils/semver.dart';
import 'package:sales_medical_app_mobile/features/auth/data/models/client_version_policy_model.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_medical_app_mobile/features/auth/presentation/pages/force_update_page.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_state.dart';
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
    await AppVersion.ensureLoaded();
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ForceUpdateGate.isActive) {
        sl<ApiService>().resetUnauthorizedHandling();
        return;
      }
      try {
        final ctx = widget.navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          await ctx.read<AuthCubit>().logout();
        }
        widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      } finally {
        // Always re-arm so a later 401 can redirect again, even if logout or
        // navigation above failed (e.g. navigator not ready yet).
        sl<ApiService>().resetUnauthorizedHandling();
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
          home: const _AppBootstrap(),
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            return Directionality(
              textDirection:
                  languageState.locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child: BotToastInit()(
                context,
                ValueListenableBuilder<ForceUpdateInfo?>(
                  valueListenable: ForceUpdateGate.notifier,
                  builder: (context, forceInfo, _) {
                    if (forceInfo != null) {
                      return ForceUpdatePage(info: forceInfo);
                    }
                    return BlocBuilder<AuthCubit, AuthState>(
                      buildWhen:
                          (p, c) => p.isAuthenticated != c.isAuthenticated,
                      builder: (context, authState) {
                        return BlocBuilder<JourneyPlanCubit, JourneyPlanState>(
                          buildWhen:
                              (prev, curr) =>
                                  prev.visits != curr.visits ||
                                  prev.journeyPlan?.id !=
                                      curr.journeyPlan?.id ||
                                  prev.journeyPlan?.stops !=
                                      curr.journeyPlan?.stops ||
                                  prev.actualStartTimestampMs !=
                                      curr.actualStartTimestampMs ||
                                  prev.activeVisitElapsedSeconds !=
                                      curr.activeVisitElapsedSeconds ||
                                  prev.activeVisitSnapshotTimestampMs !=
                                      curr.activeVisitSnapshotTimestampMs ||
                                  prev.pausedVisitElapsedSeconds !=
                                      curr.pausedVisitElapsedSeconds ||
                                  prev.totalPausedDurationSeconds !=
                                      curr.totalPausedDurationSeconds,
                          builder: (context, journeyState) {
                            final showBanner =
                                authState.isAuthenticated &&
                                activeVisitBannerShouldShow(journeyState);
                            final media = MediaQuery.of(context);
                            // Place banner above the navigator so it never covers
                            // the AppBar hamburger / back actions. Zero top inset
                            // on content while the banner owns the status bar.
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showBanner)
                                  SafeArea(
                                    bottom: false,
                                    child: ActiveVisitBanner(
                                      floating: true,
                                      onOpen:
                                          () =>
                                              openActiveVisitFromGlobalOverlay(
                                                context,
                                              ),
                                    ),
                                  ),
                                Expanded(
                                  child: MediaQuery(
                                    data:
                                        showBanner
                                            ? media.copyWith(
                                              padding: media.padding.copyWith(
                                                top: 0,
                                              ),
                                              viewPadding: media.viewPadding
                                                  .copyWith(top: 0),
                                            )
                                            : media,
                                    child: content,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
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

/// Loads package version, checks GET `/api/auth/client-version`, then auth gate.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _checking = true;
  ForceUpdateInfo? _startupBlock;

  @override
  void initState() {
    super.initState();
    _checkClientVersion();
  }

  Future<void> _checkClientVersion() async {
    await AppVersion.ensureLoaded();
    try {
      final raw = await sl<ApiService>().getClientVersionPolicy();
      if (raw != null) {
        final policy = ClientVersionPolicyModel.fromJson(raw);
        if (policy.enforce && policy.minVersion.isNotEmpty) {
          final local = AppVersion.cachedApiOrFallback;
          if (Semver.isLessThan(local, policy.minVersion)) {
            if (!mounted) return;
            setState(() {
              _startupBlock = ForceUpdateInfo(
                message:
                    'This app version ($local) is no longer supported. '
                    'Please update to ${policy.minVersion} or later.',
                minVersion: policy.minVersion,
                clientVersion: local,
                errorCode: 'CLIENT_VERSION_OUTDATED',
              );
              _checking = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Soft-fail: continue to login if policy cannot be loaded.
    }
    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_startupBlock != null) {
      return ForceUpdatePage(info: _startupBlock!);
    }
    return const _AuthGate();
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
            if (ForceUpdateGate.isActive) return;
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated, navigate to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ForceUpdateGate.isActive) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
