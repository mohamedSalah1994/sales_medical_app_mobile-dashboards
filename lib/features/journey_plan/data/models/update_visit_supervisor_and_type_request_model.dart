class UpdateVisitSupervisorAndTypeRequestModel {
  final String? supervisorId; // Nullable to allow removal
  final int visitType;

  UpdateVisitSupervisorAndTypeRequestModel({
    this.supervisorId,
    required this.visitType,
  });

  Map<String, dynamic> toJson() {
    return {
      if (supervisorId != null && supervisorId!.isNotEmpty)
        'supervisorId': supervisorId,
      'visitType': _visitTypeToSupervisorAndTypeApiValue(visitType),
    };
  }

  String _visitTypeToSupervisorAndTypeApiValue(int visitType) {
    switch (visitType) {
      case 1:
        return 'Individual';
      case 2:
        return 'couching';
      case 3:
        return 'Double';
      default:
        return 'Individual';
    }
  }
}
