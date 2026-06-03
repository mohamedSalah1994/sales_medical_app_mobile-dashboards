import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

class BulkVisitCustomerRequestModel {
  final String customerCode;
  final String customerName;
  final int visitType;

  BulkVisitCustomerRequestModel({
    required this.customerCode,
    required this.customerName,
    required this.visitType,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerCode': customerCode,
      'customerName': customerName,
      'visitType': visitTypeToApiValue(visitType),
    };
  }
}

class CreateBulkVisitsRequestModel {
  final List<BulkVisitCustomerRequestModel> customers;

  CreateBulkVisitsRequestModel({required this.customers});

  Map<String, dynamic> toJson() {
    return {
      'customers': customers.map((customer) => customer.toJson()).toList(),
    };
  }
}
