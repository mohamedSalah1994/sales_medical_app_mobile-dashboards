import 'package:sales_medical_app_mobile/features/journey_plan/domain/repositories/journey_plan_repository.dart';

class PostVisitActionUseCase {
  PostVisitActionUseCase({required this.repository});

  final JourneyPlanRepository repository;

  Future<String> call(
    String visitId, {
    required String actionCode,
    String? sapDocumentNumber,
    String? sapDocumentId,
  }) async {
    return repository.postVisitAction(
      visitId,
      actionCode: actionCode,
      sapDocumentNumber: sapDocumentNumber,
      sapDocumentId: sapDocumentId,
    );
  }
}
