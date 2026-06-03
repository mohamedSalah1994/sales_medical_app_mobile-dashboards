import 'package:sales_medical_app_mobile/core/usecases/usecase.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/supervisor_attendance_request_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class SupervisorAttendanceParams {
  const SupervisorAttendanceParams({
    required this.visitId,
    required this.request,
  });

  final String visitId;
  final SupervisorAttendanceRequestModel request;
}

class SupervisorAttendanceUseCase
    implements UseCase<Visit, SupervisorAttendanceParams> {
  SupervisorAttendanceUseCase({required this.repository});

  final JourneyPlanRepository repository;

  @override
  Future<Visit> call(SupervisorAttendanceParams params) async {
    return repository.supervisorAttendance(params.visitId, params.request);
  }
}
