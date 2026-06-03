import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/error/failure.dart';
import 'package:sales_medical_app_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/datasources/journey_plan_remote_data_source.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_supervisor_and_type_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/start_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_in_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_out_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_attendance_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_action_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plan_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plans_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinates_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class JourneyPlanRepositoryImpl implements JourneyPlanRepository {
  JourneyPlanRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  final JourneyPlanRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  @override
  Future<JourneyPlan> createJourneyPlan(JourneyPlan journeyPlan) async {
    try {
      final journeyPlanModel = journeyPlan as JourneyPlanModel;
      return await remoteDataSource.createJourneyPlan(journeyPlanModel);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<JourneyPlan> updateJourneyPlan(
    String journeyPlanId,
    JourneyPlan journeyPlan,
  ) async {
    try {
      final journeyPlanModel = journeyPlan as JourneyPlanModel;
      return await remoteDataSource.updateJourneyPlan(
        journeyPlanId,
        journeyPlanModel,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<JourneyPlan> getJourneyPlanById(String journeyPlanId) async {
    try {
      return await remoteDataSource.getJourneyPlanById(journeyPlanId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<JourneyPlan> createStopAndVisit(
    String journeyPlanId,
    CreateStopRequestModel request,
  ) async {
    try {
      return await remoteDataSource.createStopAndVisit(journeyPlanId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<CreateBulkVisitsResponseModel> createBulkVisits(
    String journeyPlanId,
    CreateBulkVisitsRequestModel request,
  ) async {
    try {
      return await remoteDataSource.createBulkVisits(journeyPlanId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Visit> createVisit(CreateVisitRequestModel request) async {
    try {
      return await remoteDataSource.createVisit(request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<JourneyPlan> updateStop(
    String journeyPlanId,
    String stopId,
    UpdateStopRequestModel request,
  ) async {
    try {
      return await remoteDataSource.updateStop(journeyPlanId, stopId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<Customer>> getCustomers({
    String? search,
    String? state,
    String? city,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  }) async {
    try {
      // Use saved sapSalesEmployeeCode from login when not explicitly passed
      int? effectiveSalesEmployeeCode = salesEmployeeCode;
      if (effectiveSalesEmployeeCode == null) {
        final loginData = await authLocalDataSource.getLoginData();
        effectiveSalesEmployeeCode = loginData?.user.sapSalesEmployeeCode;
      }

      final response = await remoteDataSource.getCustomers(
        search: search,
        state: state,
        city: city,
        activeOnly: activeOnly,
        salesEmployeeCode: effectiveSalesEmployeeCode,
        pageNumber: pageNumber,
        pageSize: pageSize,
        scope: scope,
      );
      return response.items;
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<JourneyPlansResponseModel> getJourneyPlans({
    String? userId,
    String? createdById,
    String? supervisorId,
    String? customerId,
    int? planType,
    DateTime? startDate,
    DateTime? endDate,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await remoteDataSource.getJourneyPlans(
        userId: userId,
        createdById: createdById,
        supervisorId: supervisorId,
        customerId: customerId,
        planType: planType,
        startDate: startDate,
        endDate: endDate,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<SubordinatesResponseModel> getSubordinates(String userId) async {
    try {
      return await remoteDataSource.getSubordinates(userId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<SupervisorModel>> getSupervisors() async {
    try {
      return await remoteDataSource.getSupervisors();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteJourneyPlan(String journeyPlanId) async {
    try {
      return await remoteDataSource.deleteJourneyPlan(journeyPlanId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> updateVisitSupervisorAndType(
    String visitId,
    UpdateVisitSupervisorAndTypeRequestModel request,
  ) async {
    try {
      return await remoteDataSource.updateVisitSupervisorAndType(
        visitId,
        request,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> updateVisit(
    String visitId,
    UpdateVisitRequestModel request,
  ) async {
    try {
      return await remoteDataSource.updateVisit(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> startVisit(
    String visitId,
    StartVisitRequestModel request,
  ) async {
    try {
      return await remoteDataSource.startVisit(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> checkInVisit(
    String visitId,
    CheckInVisitRequestModel request,
  ) async {
    try {
      return await remoteDataSource.checkInVisit(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> checkOutVisit(
    String visitId,
    CheckOutVisitRequestModel request,
  ) async {
    try {
      return await remoteDataSource.checkOutVisit(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> pauseVisit(String visitId) async {
    try {
      return await remoteDataSource.pauseVisit(visitId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> resumeVisit(String visitId) async {
    try {
      return await remoteDataSource.resumeVisit(visitId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteVisit(String visitId) async {
    try {
      return await remoteDataSource.deleteVisit(visitId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Visit> supervisorAttendance(
    String visitId,
    SupervisorAttendanceRequestModel request,
  ) async {
    try {
      return await remoteDataSource.supervisorAttendance(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<VisitsResponseModel> getVisits({
    String? userId,
    String? customerId,
    String? customerCode,
    String? supervisorId,
    DateTime? startDate,
    DateTime? endDate,
    int? status,
    bool standaloneOnly = false,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      return await remoteDataSource.getVisits(
        userId: userId,
        customerId: customerId,
        customerCode: customerCode,
        supervisorId: supervisorId,
        startDate: startDate,
        endDate: endDate,
        status: status,
        standaloneOnly: standaloneOnly,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<String> postVisitAction(
    String visitId, {
    required String actionCode,
    String? sapDocumentNumber,
    String? sapDocumentId,
  }) async {
    try {
      final request = VisitActionRequestModel(
        actionCode: actionCode,
        sapDocumentNumber: sapDocumentNumber,
        sapDocumentId: sapDocumentId,
      );
      return await remoteDataSource.postVisitAction(visitId, request);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
