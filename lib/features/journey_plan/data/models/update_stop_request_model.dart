class UpdateStopRequestModel {
  final String visitId;
  final int sequenceNo;
  final DateTime plannedTime;
  final int estimatedDurationMinutes;

  UpdateStopRequestModel({
    required this.visitId,
    required this.sequenceNo,
    required this.plannedTime,
    required this.estimatedDurationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'visitId': visitId,
      'sequenceNo': sequenceNo,
      'plannedTime': plannedTime.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
    };
  }
}
