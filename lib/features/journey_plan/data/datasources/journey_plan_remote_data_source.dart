import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sales_medical_app_mobile/core/constants/customer_odbc_scope.dart';
import 'package:sales_medical_app_mobile/core/network/api_service.dart';
import 'package:sales_medical_app_mobile/core/utils/odbc_customers_master_data_query.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plan_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_bulk_visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/create_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_stop_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_supervisor_and_type_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/update_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/start_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_in_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/check_out_visit_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_attendance_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/customer_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/customers_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/journey_plans_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinates_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visits_response_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_action_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

abstract class JourneyPlanRemoteDataSource {
  Future<JourneyPlanModel> createJourneyPlan(JourneyPlanModel journeyPlan);
  Future<JourneyPlanModel> updateJourneyPlan(
    String journeyPlanId,
    JourneyPlanModel journeyPlan,
  );
  Future<JourneyPlanModel> getJourneyPlanById(String journeyPlanId);
  Future<JourneyPlanModel> createStopAndVisit(
    String journeyPlanId,
    CreateStopRequestModel request,
  );
  Future<CreateBulkVisitsResponseModel> createBulkVisits(
    String journeyPlanId,
    CreateBulkVisitsRequestModel request,
  );
  Future<VisitModel> createVisit(CreateVisitRequestModel request);
  Future<JourneyPlanModel> updateStop(
    String journeyPlanId,
    String stopId,
    UpdateStopRequestModel request,
  );
  Future<CustomersResponseModel> getCustomers({
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
  Future<VisitModel> supervisorAttendance(
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
    String visitId,
    VisitActionRequestModel request,
  );
}

/// True if [s] looks like a UUID (API expects userId/supervisorId/createdById as UUID).
bool _isValidUuid(String? s) {
  if (s == null || s.isEmpty) return false;
  if (s.length != 36) return false;
  return s[8] == '-' && s[13] == '-' && s[18] == '-' && s[23] == '-';
}

class JourneyPlanRemoteDataSourceImpl implements JourneyPlanRemoteDataSource {
  JourneyPlanRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  /// Safely converts response data to a JSON object map.
  /// Handles both pre-parsed JSON ([Map]) and raw [String] responses.
  Map<String, dynamic> _toJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      if (kDebugMode) {
        print('⚠️ Response data is String, decoding JSON manually');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    } else {
      throw FormatException(
        'Unexpected response data type: ${data.runtimeType}',
      );
    }
  }

  @override
  Future<JourneyPlanModel> createJourneyPlan(
    JourneyPlanModel journeyPlan,
  ) async {
    final response = await apiService.post(
      '/api/journey-plans',
      data: journeyPlan.toCreateJson(),
    );

    return JourneyPlanModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<JourneyPlanModel> updateJourneyPlan(
    String journeyPlanId,
    JourneyPlanModel journeyPlan,
  ) async {
    final response = await apiService.put(
      '/api/journey-plans/$journeyPlanId',
      data: journeyPlan.toUpdateJson(),
    );

    return JourneyPlanModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<JourneyPlanModel> getJourneyPlanById(String journeyPlanId) async {
    final response = await apiService.get('/api/journey-plans/$journeyPlanId');

    return JourneyPlanModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<JourneyPlanModel> createStopAndVisit(
    String journeyPlanId,
    CreateStopRequestModel request,
  ) async {
    final requestData = request.toJson();

    // Debug: Log the request data to verify googleMapsLink is included
    if (kDebugMode) {
      print('📤 Creating stop with visit - Request data: $requestData');
      print('📤 googleMapsLink in request: ${requestData['googleMapsLink']}');
    }

    final response = await apiService.post(
      '/api/journey-plans/$journeyPlanId/stops/create-visit',
      data: requestData,
    );

    final responseData = _toJsonMap(response.data);

    // Debug: Log the response to verify googleMapsLink is in the response
    if (kDebugMode) {
      print('📥 Response received');
      if (responseData['stops'] != null) {
        final stops = responseData['stops'] as List;
        if (stops.isNotEmpty) {
          // Check the last stop (the newly created one)
          final lastStop = stops[stops.length - 1] as Map<String, dynamic>;
          if (lastStop['visit'] != null) {
            final visit = lastStop['visit'] as Map<String, dynamic>;
            print('📥 Last stop visit ID: ${visit['id']}');
            print(
              '📥 googleMapsLink in response visit: ${visit['googleMapsLink']}',
            );
            print('📥 All visit fields: ${visit.keys.toList()}');
          } else {
            print('⚠️ Last stop has no visit');
          }
        } else {
          print('⚠️ No stops in response');
        }
      } else {
        print('⚠️ No stops field in response');
      }
    }

    return JourneyPlanModel.fromJson(responseData);
  }

  @override
  Future<CreateBulkVisitsResponseModel> createBulkVisits(
    String journeyPlanId,
    CreateBulkVisitsRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/journey-plans/$journeyPlanId/stops/create-visits',
      data: request.toJson(),
    );

    return CreateBulkVisitsResponseModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<VisitModel> createVisit(CreateVisitRequestModel request) async {
    final response = await apiService.post(
      '/api/Visits',
      data: request.toJson(),
    );
    final responseData = _toJsonMap(response.data);
    return VisitModel.fromJson(responseData);
  }

  @override
  Future<JourneyPlanModel> updateStop(
    String journeyPlanId,
    String stopId,
    UpdateStopRequestModel request,
  ) async {
    final response = await apiService.put(
      '/api/journey-plans/$journeyPlanId/stops/$stopId',
      data: request.toJson(),
    );

    return JourneyPlanModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<CustomersResponseModel> getCustomers({
    String? search,
    String? state,
    String? city,
    bool? activeOnly,
    int? salesEmployeeCode,
    int pageNumber = 1,
    int pageSize = 10,
    int scope = CustomerOdbcScope.all,
  }) async {
    // GET /api/MasterData/customers/odbc (see Swagger: salesEmpCode, area, zone, …)
    final queryParams = buildOdbcCustomersMasterDataQuery(
      skip: (pageNumber - 1) * pageSize,
      take: pageSize,
      scope: scope,
      activeOnly: activeOnly,
      search: search,
      state: state,
      city: city,
      salesEmpCode: salesEmployeeCode,
    );

    final response = await apiService.get(
      '/api/MasterData/customers/odbc',
      queryParameters: queryParams,
    );

    // Response is a direct array: [{ code, name, address, city, phone, email, ... }]
    final rawData = response.data;
    final decoded = rawData is String ? jsonDecode(rawData) : null;
    final List<dynamic> list =
        rawData is List<dynamic>
            ? rawData
            : (rawData is String
                ? (decoded is List<dynamic> ? decoded : <dynamic>[])
                : (_toJsonMap(rawData).containsKey('items')
                    ? (_toJsonMap(rawData)['items'] as List<dynamic>?) ?? []
                    : <dynamic>[]));
    final items =
        list
            .map(
              (e) => CustomerModel.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
    return CustomersResponseModel(
      items: items,
      totalCount: items.length,
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalPages: items.length < pageSize ? 1 : pageNumber + 1,
      hasPreviousPage: pageNumber > 1,
      hasNextPage: items.length >= pageSize,
    );
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
    // Build query parameters - always include pageNumber and pageSize
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    // API expects userId, createdById, supervisorId as UUIDs; omit if not valid (e.g. Erp sales-employee code "1")
    if (userId != null && userId.isNotEmpty && _isValidUuid(userId)) {
      queryParams['userId'] = userId;
    }
    if (createdById != null &&
        createdById.isNotEmpty &&
        _isValidUuid(createdById)) {
      queryParams['createdById'] = createdById;
    }
    if (supervisorId != null &&
        supervisorId.isNotEmpty &&
        _isValidUuid(supervisorId)) {
      queryParams['supervisorId'] = supervisorId;
    }
    if (customerId != null && customerId.isNotEmpty) {
      queryParams['customerId'] = customerId;
    }
    if (planType != null) {
      queryParams['planType'] = journeyPlanTypeToApiValue(planType);
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await apiService.get(
      '/api/journey-plans',
      queryParameters: queryParams,
    );

    return JourneyPlansResponseModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<SubordinatesResponseModel> getSubordinates(String userId) async {
    // GET /api/Users/{id}/subordinates — id is the logged-in user (supervisor) UUID
    if (!_isValidUuid(userId)) {
      return const SubordinatesResponseModel(
        directSubordinates: [],
        salesEmployees: [],
      );
    }
    final response = await apiService.get('/api/Users/$userId/subordinates');
    final data = _toJsonMap(response.data);
    return SubordinatesResponseModel.fromJson(data);
  }

  @override
  Future<List<SupervisorModel>> getSupervisors() async {
    final response = await apiService.get('/api/Users/supervisors');

    final dynamic rawData =
        response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
    final list = rawData as List<dynamic>;
    return list
        .map((e) => SupervisorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteJourneyPlan(String journeyPlanId) async {
    await apiService.delete('/api/journey-plans/$journeyPlanId');
  }

  @override
  Future<void> updateVisitSupervisorAndType(
    String visitId,
    UpdateVisitSupervisorAndTypeRequestModel request,
  ) async {
    await apiService.put(
      '/api/Visits/$visitId/supervisor-and-type',
      data: request.toJson(),
    );
  }

  @override
  Future<void> updateVisit(
    String visitId,
    UpdateVisitRequestModel request,
  ) async {
    await apiService.put('/api/Visits/$visitId', data: request.toJson());
  }

  @override
  Future<void> startVisit(
    String visitId,
    StartVisitRequestModel request,
  ) async {
    await apiService.put('/api/Visits/$visitId/start', data: request.toJson());
  }

  @override
  Future<void> checkInVisit(
    String visitId,
    CheckInVisitRequestModel request,
  ) async {
    await apiService.post(
      '/api/Visits/$visitId/check-in',
      data: request.toJson(),
    );
  }

  @override
  Future<void> checkOutVisit(
    String visitId,
    CheckOutVisitRequestModel request,
  ) async {
    await apiService.post(
      '/api/Visits/$visitId/check-out',
      data: request.toJson(),
    );
  }

  @override
  Future<void> pauseVisit(String visitId) async {
    await apiService.post('/api/Visits/$visitId/pause');
  }

  @override
  Future<void> resumeVisit(String visitId) async {
    await apiService.post('/api/Visits/$visitId/resume');
  }

  @override
  Future<void> deleteVisit(String visitId) async {
    await apiService.delete('/api/Visits/$visitId');
  }

  @override
  Future<VisitModel> supervisorAttendance(
    String visitId,
    SupervisorAttendanceRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/Visits/$visitId/supervisor-attendance',
      data: request.toJson(),
    );
    return VisitModel.fromJson(_toJsonMap(response.data));
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
    // Build query parameters - always include pageNumber and pageSize
    final queryParams = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    // Add optional parameters only if provided
    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }
    if (customerId != null && customerId.isNotEmpty) {
      queryParams['customerId'] = customerId;
    }
    if (customerCode != null && customerCode.isNotEmpty) {
      queryParams['customerCode'] = customerCode;
    }
    if (supervisorId != null && supervisorId.isNotEmpty) {
      queryParams['supervisorId'] = supervisorId;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().substring(0, 10);
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().substring(0, 10);
    }
    if (status != null) {
      queryParams['status'] = visitStatusToApiValue(status);
    }

    final response = await apiService.get(
      standaloneOnly ? '/api/Visits/standalone' : '/api/Visits',
      queryParameters: queryParams,
    );

    return VisitsResponseModel.fromJson(_toJsonMap(response.data));
  }

  @override
  Future<String> postVisitAction(
    String visitId,
    VisitActionRequestModel request,
  ) async {
    final response = await apiService.post(
      '/api/Visits/$visitId/actions',
      data: request.toJson(),
    );
    final data = _toJsonMap(response.data);
    final message = data['message'] as String?;
    if (message != null && message.isNotEmpty) return message;
    if (data['id'] != null || data['actionCode'] != null) {
      return 'Action completed successfully.';
    }
    final actionName = data['actionName'] as String?;
    if (actionName != null && actionName.isNotEmpty) return actionName;
    return 'Action completed successfully.';
  }
}
