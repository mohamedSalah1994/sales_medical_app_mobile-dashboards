import 'package:sales_medical_app_mobile/features/customers/data/models/master_data_option_model.dart';
import 'package:sales_medical_app_mobile/features/customers/domain/repositories/customer_repository.dart';

enum MasterDataSection {
  areas,
  areaUdtZones,
  areaUdtStates,
  areaUdtCities,
  areaUdtRegions,
  customerTypes,
}

class GetMasterDataOptionsUseCase {
  GetMasterDataOptionsUseCase({required this.repository});

  final CustomerRepository repository;

  Future<List<MasterDataOptionModel>> call({
    required MasterDataSection section,
    String? parentTerritoryId,
  }) {
    final parent = parentTerritoryId?.trim() ?? '';
    switch (section) {
      case MasterDataSection.areas:
        return repository.getAreas();
      case MasterDataSection.areaUdtZones:
        return repository.getAreaUdtZones(parent);
      case MasterDataSection.areaUdtStates:
        return repository.getAreaUdtStates(parent);
      case MasterDataSection.areaUdtCities:
        return repository.getAreaUdtCities(parent);
      case MasterDataSection.areaUdtRegions:
        return repository.getAreaUdtRegions(parent);
      case MasterDataSection.customerTypes:
        return repository.getCustomerTypes();
    }
  }
}
