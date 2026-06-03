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
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/customer.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/journey_plan.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';

import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plans_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinates_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_model.dart';

abstract class JourneyPlanRepository {
  Future<JourneyPlan> createJourneyPlan(JourneyPlan journeyPlan);
  Future<JourneyPlan> updateJourneyPlan(
    String journeyPlanId,
    JourneyPlan journeyPlan,
  );
  Future<JourneyPlan> getJourneyPlanById(String journeyPlanId);
  Future<JourneyPlan> createStopAndVisit(
    String journeyPlanId,
    CreateStopRequestModel request,
  );
  Future<CreateBulkVisitsResponseModel> createBulkVisits(
    String journeyPlanId,
    CreateBulkVisitsRequestModel request,
  );
  Future<Visit> createVisit(CreateVisitRequestModel request);
  Future<JourneyPlan> updateStop(
    String journeyPlanId,
    String stopId,
    UpdateStopRequestModel request,
  );
  Future<List<Customer>> getCustomers({
    String? search,
    String? state,
    String? city,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  });
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
  });
  Future<SubordinatesResponseModel> getSubordinates(String userId);
  Future<List<SupervisorModel>> getSupervisors();
  Future<void> deleteJourneyPlan(String journeyPlanId);
  Future<void> updateVisitSupervisorAndType(
    String visitId,
    UpdateVisitSupervisorAndTypeRequestModel request,
  );
  Future<void> updateVisit(String visitId, UpdateVisitRequestModel request);
  Future<void> startVisit(String visitId, StartVisitRequestModel request);
  Future<void> checkInVisit(String visitId, CheckInVisitRequestModel request);
  Future<void> checkOutVisit(String visitId, CheckOutVisitRequestModel request);
  Future<void> pauseVisit(String visitId);
  Future<void> resumeVisit(String visitId);
  Future<void> deleteVisit(String visitId);
  Future<Visit> supervisorAttendance(
    String visitId,
    SupervisorAttendanceRequestModel request,
  );
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
  });
  Future<String> postVisitAction(
    String visitId, {
    required String actionCode,
    String? sapDocumentNumber,
    String? sapDocumentId,
  });
}
