import 'package:sales_medical_app_mobile/features/journey_plan/data/models/subordinate_model.dart';

class SubordinatesResponseModel {
  const SubordinatesResponseModel({
    required this.directSubordinates,
    required this.salesEmployees,
  });

  final List<SubordinateModel> directSubordinates;
  final List<SubordinateModel> salesEmployees;

  factory SubordinatesResponseModel.fromJson(Map<String, dynamic> json) {
    return SubordinatesResponseModel(
      directSubordinates: (json['directSubordinates'] as List<dynamic>?)
              ?.map((e) => SubordinateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      salesEmployees: (json['salesEmployees'] as List<dynamic>?)
              ?.map((e) => SubordinateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'directSubordinates':
          directSubordinates.map((e) => e.toJson()).toList(),
      'salesEmployees': salesEmployees.map((e) => e.toJson()).toList(),
    };
  }
}
