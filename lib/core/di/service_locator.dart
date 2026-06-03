import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_medical_app_mobile/core/localization/language_cubit.dart';
import 'package:sales_medical_app_mobile/core/cache/item_lookup_odbc_cache.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/network/connectivity_service.dart';
import 'package:sales_medical_app_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sales_medical_app_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:sales_medical_app_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/datasources/journey_plan_local_data_source.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/datasources/journey_plan_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/repositories/journey_plan_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_bulk_visits_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_stop_and_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/create_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/delete_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/delete_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/post_visit_action_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_customers_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_journey_plan_by_id_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_journey_plans_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_subordinates_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_supervisors_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/get_visits_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_journey_plan_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_stop_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_visit_supervisor_and_type_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/update_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/start_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/check_in_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/check_out_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/pause_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/resume_visit_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/usecases/supervisor_attendance_usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/presentation/cubit/journey_plan_cubit.dart';
import 'package:sales_medical_app_mobile/features/targets/data/datasources/targets_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/targets/data/repositories/targets_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/repositories/targets_repository.dart';
import 'package:sales_medical_app_mobile/features/targets/domain/usecases/get_targets_usecase.dart';
import 'package:sales_medical_app_mobile/features/targets/presentation/cubit/targets_cubit.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/datasources/survey_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/surveys/data/repositories/survey_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/repositories/survey_repository.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/create_survey_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/get_surveys_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/domain/usecases/update_survey_usecase.dart';
import 'package:sales_medical_app_mobile/features/surveys/presentation/cubit/surveys_cubit.dart';
import 'package:sales_medical_app_mobile/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/create_erp_customer_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customer_series_usecase.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_customers_usecase.dart'
    as customer_erp;
import 'package:sales_medical_app_mobile/features/customers/domain/usecases/get_master_data_options_usecase.dart';
import 'package:sales_medical_app_mobile/core/field_staff/field_staff_location_tracker.dart';
import 'package:sales_medical_app_mobile/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:sales_medical_app_mobile/features/field_staff/data/field_staff_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sales_medical_app_mobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/datasources/sales_order_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/sales_order/data/repositories/sales_order_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/sales_order/domain/repositories/sales_order_repository.dart';
import 'package:sales_medical_app_mobile/features/sales_order/presentation/cubit/sales_order_cubit.dart';
import 'package:sales_medical_app_mobile/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:sales_medical_app_mobile/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:sales_medical_app_mobile/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/repositories/reports_repository.dart';
import 'package:sales_medical_app_mobile/features/reports/domain/usecases/get_target_achievement_usecase.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/stock_availability_cubit.dart';
import 'package:sales_medical_app_mobile/features/reports/presentation/cubit/target_achievement_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<LanguageCubit>(() => LanguageCubit());

  // Auth
  sl
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        apiService: sl(),
      ),
    )
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => CheckAuthUseCase(sl()));

  // Journey Plan
  sl
    ..registerLazySingleton<JourneyPlanRemoteDataSource>(
      () => JourneyPlanRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<JourneyPlanLocalDataSource>(
      () => JourneyPlanLocalDataSourceImpl(preferences: sl()),
    )
    ..registerLazySingleton<JourneyPlanRepository>(
      () => JourneyPlanRepositoryImpl(
        remoteDataSource: sl(),
        authLocalDataSource: sl(),
      ),
    )
    ..registerLazySingleton(() => CreateJourneyPlanUseCase(repository: sl()))
    ..registerLazySingleton(() => UpdateJourneyPlanUseCase(repository: sl()))
    ..registerLazySingleton(() => GetJourneyPlanByIdUseCase(repository: sl()))
    ..registerLazySingleton(() => CreateBulkVisitsUseCase(repository: sl()))
    ..registerLazySingleton(() => CreateStopAndVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => CreateVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => UpdateStopUseCase(repository: sl()))
    ..registerLazySingleton(
      () => UpdateVisitSupervisorAndTypeUseCase(repository: sl()),
    )
    ..registerLazySingleton(() => UpdateVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => CheckInVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => CheckOutVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => PauseVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => ResumeVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => SupervisorAttendanceUseCase(repository: sl()))
    ..registerLazySingleton(() => DeleteVisitUseCase(repository: sl()))
    ..registerLazySingleton(() => PostVisitActionUseCase(repository: sl()))
    ..registerLazySingleton(() => DeleteJourneyPlanUseCase(repository: sl()))
    ..registerLazySingleton(() => GetCustomersUseCase(repository: sl()))
    ..registerLazySingleton(() => GetJourneyPlansUseCase(repository: sl()))
    ..registerLazySingleton(() => GetSubordinatesUseCase(repository: sl()))
    ..registerLazySingleton(() => GetSupervisorsUseCase(repository: sl()))
    ..registerLazySingleton(() => GetVisitsUseCase(repository: sl()))
    ..registerLazySingleton(() => StartVisitUseCase(repository: sl()))
    ..registerLazySingleton(
      () => JourneyPlanCubit(
        createJourneyPlanUseCase: sl(),
        updateJourneyPlanUseCase: sl(),
        getJourneyPlanByIdUseCase: sl(),
        createBulkVisitsUseCase: sl(),
        createStopAndVisitUseCase: sl(),
        createVisitUseCase: sl(),
        updateStopUseCase: sl(),
        getCustomersUseCase: sl(),
        getJourneyPlansUseCase: sl(),
        getSubordinatesUseCase: sl(),
        getSupervisorsUseCase: sl(),
        deleteJourneyPlanUseCase: sl(),
        updateVisitSupervisorAndTypeUseCase: sl(),
        updateVisitUseCase: sl(),
        getVisitsUseCase: sl(),
        startVisitUseCase: sl(),
        checkInVisitUseCase: sl(),
        checkOutVisitUseCase: sl(),
        pauseVisitUseCase: sl(),
        resumeVisitUseCase: sl(),
        supervisorAttendanceUseCase: sl(),
        deleteVisitUseCase: sl(),
        postVisitActionUseCase: sl(),
        connectivityService: sl(),
        localDataSource: sl(),
      ),
    );

  // Targets
  sl
    ..registerLazySingleton<TargetsRemoteDataSource>(
      () => TargetsRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<TargetsRepository>(
      () => TargetsRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton(() => GetTargetsUseCase(repository: sl()))
    ..registerFactory(() => TargetsCubit(getTargetsUseCase: sl()));

  // Surveys
  sl
    ..registerLazySingleton<SurveyRemoteDataSource>(
      () => SurveyRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<SurveyRepository>(
      () => SurveyRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton(() => GetSurveysUseCase(sl()))
    ..registerLazySingleton(() => CreateSurveyUseCase(sl()))
    ..registerLazySingleton(() => UpdateSurveyUseCase(sl()))
    ..registerFactory(
      () => SurveysCubit(
        getSurveysUseCase: sl(),
        createSurveyUseCase: sl(),
        updateSurveyUseCase: sl(),
      ),
    );

  // Customers (ERP - POST /api/Erp/customers, GET /api/Erp/customers/series)
  sl
    ..registerLazySingleton<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSourceImpl(apiService: sl<ApiService>()),
    )
    ..registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(
        remoteDataSource: sl<CustomerRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<GetCustomerSeriesUseCase>(
      () => GetCustomerSeriesUseCase(repository: sl<CustomerRepository>()),
    )
    ..registerLazySingleton<customer_erp.GetCustomersUseCase>(
      () => customer_erp.GetCustomersUseCase(sl<CustomerRepository>()),
    )
    ..registerLazySingleton<CreateErpCustomerUseCase>(
      () => CreateErpCustomerUseCase(repository: sl<CustomerRepository>()),
    )
    ..registerLazySingleton<GetMasterDataOptionsUseCase>(
      () => GetMasterDataOptionsUseCase(repository: sl<CustomerRepository>()),
    )
    ..registerFactory(
      () => CustomersCubit(
        getCustomersUseCase: sl<customer_erp.GetCustomersUseCase>(),
        getCustomerSeriesUseCase: sl<GetCustomerSeriesUseCase>(),
        createErpCustomerUseCase: sl<CreateErpCustomerUseCase>(),
        getMasterDataOptionsUseCase: sl<GetMasterDataOptionsUseCase>(),
      ),
    );

  // Field staff — POST /api/FieldStaff/location, GET /api/FieldStaff/team-locations
  sl
    ..registerLazySingleton<FieldStaffRemoteDataSource>(
      () => FieldStaffRemoteDataSourceImpl(apiService: sl<ApiService>()),
    )
    ..registerLazySingleton<FieldStaffLocationTracker>(
      () => FieldStaffLocationTracker(apiService: sl<ApiService>()),
    );

  // Sales Order (GET/POST /api/erp/sales-orders, ODBC customers via CustomerRepository, GET /api/MasterData/items/lookup)
  sl
    ..registerLazySingleton<ItemLookupOdbcCache>(
      () => ItemLookupOdbcCache(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<SalesOrderRemoteDataSource>(
      () => SalesOrderRemoteDataSourceImpl(
        apiService: sl(),
        itemLookupCache: sl<ItemLookupOdbcCache>(),
      ),
    )
    ..registerLazySingleton<SalesOrderRepository>(
      () => SalesOrderRepositoryImpl(
        remoteDataSource: sl(),
        connectivityService: sl<ConnectivityService>(),
        itemLookupCache: sl<ItemLookupOdbcCache>(),
      ),
    )
    ..registerFactory(
      () => SalesOrderCubit(
        repository: sl(),
        authRepository: sl(),
        getOdbcCustomersUseCase: sl<customer_erp.GetCustomersUseCase>(),
      ),
    );

  // Inventory (GET/POST /api/erp/inventory-transfer-requests, ODBC warehouses & item lookup)
  sl
    ..registerLazySingleton<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerFactory(() => InventoryCubit(repository: sl()));

  // Wallet (GET /api/Reports/wallet) — sales employee balance summary on home.
  sl
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSourceImpl(apiService: sl()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton(() => GetWalletUseCase(repository: sl()))
    ..registerFactory(() => WalletCubit(getWalletUseCase: sl()));

  // Reports — stock availability + warehouses dialog (admin/supervisor).
  // Sales reps auto-load using their default warehouse; admin/supervisor pick
  // from /api/Erp/warehouses with paginated scroll.
  sl
    ..registerLazySingleton<ReportsRemoteDataSource>(
      () => ReportsRemoteDataSourceImpl(apiService: sl<ApiService>()),
    )
    ..registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(remoteDataSource: sl<ReportsRemoteDataSource>()),
    )
    ..registerFactory<StockAvailabilityCubit>(
      () => StockAvailabilityCubit(repository: sl<ReportsRepository>()),
    )
    ..registerLazySingleton(
      () => GetTargetAchievementUseCase(repository: sl<ReportsRepository>()),
    )
    ..registerFactory(
      () => TargetAchievementCubit(
        getTargetAchievementUseCase: sl<GetTargetAchievementUseCase>(),
      ),
    );
}
