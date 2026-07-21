/// Request body for POST /api/Erp/customers
class CreateErpCustomerRequestModel {
  const CreateErpCustomerRequestModel({
    this.series,
    this.cardName,
    this.cardType,
    this.cardForeignName,
    this.channelBP,
    this.uNArea,
    this.uZone,
    this.uS,
    this.uC,
    this.uRegion,
    this.uLocPnt,
    this.uGLink,
    this.phone1,
    this.phone2,
    this.address,
    this.uCusTyp,
    this.vatNumber,
  });

  final String? series;
  final String? cardName;
  final String? cardType;
  final String? cardForeignName;
  final String? channelBP;
  /// Maps to JSON `U_N_AREA`
  final String? uNArea;
  /// Maps to JSON `U_ZONE`
  final String? uZone;
  /// Maps to JSON `u_S`
  final String? uS;
  /// Maps to JSON `U_C`
  final String? uC;
  /// Maps to JSON `U_REGION`
  final String? uRegion;
  final String? uLocPnt;
  final String? uGLink;
  final String? phone1;
  final String? phone2;
  final String? address;
  final String? uCusTyp;
  final String? vatNumber;

  /// All attributes included; string fields default to empty string. Location
  /// fields (`U_LOC_PNT`, `U_G_Link`) are sent as JSON `null` when not
  /// provided so the ERP layer can distinguish "no value" from an empty string.
  Map<String, dynamic> toJson() {
    final locPntValue = (uLocPnt == null || uLocPnt!.trim().isEmpty)
        ? null
        : uLocPnt!.trim();
    final gLinkValue = (uGLink == null || uGLink!.trim().isEmpty)
        ? null
        : uGLink!.trim();
    return <String, dynamic>{
      'series': series?.trim().isEmpty ?? true ? '' : series!,
      'cardName': cardName?.trim().isEmpty ?? true ? '' : cardName!,
      'cardType': cardType?.trim().isEmpty ?? true ? '' : cardType!,
      'cardForeignName': cardForeignName?.trim().isEmpty ?? true ? '' : cardForeignName!,
      'channelBP': channelBP?.trim().isEmpty ?? true ? '' : channelBP!,
      'U_N_AREA': uNArea?.trim().isEmpty ?? true ? '' : uNArea!,
      'U_ZONE': uZone?.trim().isEmpty ?? true ? '' : uZone!,
      'u_S': uS?.trim().isEmpty ?? true ? '' : uS!,
      'U_C': uC?.trim().isEmpty ?? true ? '' : uC!,
      'U_REGION': uRegion?.trim().isEmpty ?? true ? '' : uRegion!,
      'U_LOC_PNT': locPntValue,
      'U_G_Link': gLinkValue,
      'phone1': phone1?.trim().isEmpty ?? true ? '' : phone1!,
      'phone2': phone2?.trim().isEmpty ?? true ? '' : phone2!,
      'address': address?.trim().isEmpty ?? true ? '' : address!,
      'U_CUS_TYP': uCusTyp?.trim().isEmpty ?? true ? '' : uCusTyp!,
      'vatNumber': vatNumber?.trim().isEmpty ?? true ? '' : vatNumber!,
    };
  }
}
