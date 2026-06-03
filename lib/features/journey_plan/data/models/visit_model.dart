import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit_action.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_action_model.dart';
import 'package:sales_medical_app_mobile/features/journey_plan/data/models/visit_enum_json_codec.dart';

DateTime _parseVisitTimestamp(String value, {bool assumeUtcIfMissing = false}) {
  final parsed = DateTime.parse(value);
  if (parsed.isUtc) return parsed.toLocal();
  final hasTimezone =
      value.endsWith('Z') || RegExp(r'([+-]\d{2}:\d{2})$').hasMatch(value);
  if (hasTimezone) return parsed.toLocal();
  if (assumeUtcIfMissing) {
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }
  return parsed;
}

class VisitModel extends Visit {
  const VisitModel({
    required super.id,
    super.userId,
    super.userName,
    super.loginUsername,
    required super.customerId,
    required super.customerName,
    super.customerCode,
    super.journeyPlanId,
    required super.plannedDateTime,
    super.actualStartDateTime,
    super.actualEndDateTime,
    super.visitType,
    super.status,
    super.supervisorId,
    super.supervisorName,
    super.supervisorCheckInAt,
    super.supervisorCheckOutAt,
    super.supervisorCheckInLatitude,
    super.supervisorCheckInLongitude,
    super.supervisorCheckOutLatitude,
    super.supervisorCheckOutLongitude,
    super.checkInLatitude,
    super.checkInLongitude,
    super.checkOutLatitude,
    super.checkOutLongitude,
    super.notes,
    super.googleMapsLink,
    super.createdAt,
    super.actions,
    super.customerLocationPoint,
    super.customerUGLink,
  });

  /// Returns first non-empty trimmed string from the given JSON keys, or null.
  /// Also unwraps a nested `customer` object when present (so callers can use
  /// `customer.U_LOC_PNT` / `customer.U_G_Link` style aliases).
  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    final nested = json['customer'];
    final nestedMap =
        nested is Map<String, dynamic>
            ? nested
            : nested is Map
                ? nested.cast<String, dynamic>()
                : null;
    for (final k in keys) {
      final raw = json[k] ?? nestedMap?[k];
      if (raw == null) continue;
      final s = raw.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List<dynamic>?;
    final actions =
        actionsJson == null
            ? <VisitAction>[]
            : actionsJson
                .map(
                  (e) => VisitActionModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();
    return VisitModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      // Backend renamed `userName` → `assignedUserFullName` and split out
      // `loginUsername` to fix the VisitDto JSON property collision. Read both
      // shapes so the app keeps working against either deployment.
      userName: _pickString(json, ['assignedUserFullName', 'userName']),
      loginUsername: _pickString(json, ['loginUsername', 'username']),
      customerId: (json['customerId'] as String?) ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerCode: json['customerCode'] as String?,
      journeyPlanId: json['journeyPlanId'] as String?,
      plannedDateTime: _parseVisitTimestamp(json['plannedDateTime'] as String),
      actualStartDateTime:
          json['actualStartDateTime'] != null
              ? _parseVisitTimestamp(
                json['actualStartDateTime'] as String,
                assumeUtcIfMissing: true,
              )
              : null,
      actualEndDateTime:
          json['actualEndDateTime'] != null
              ? _parseVisitTimestamp(
                json['actualEndDateTime'] as String,
                assumeUtcIfMissing: true,
              )
              : null,
      visitType: visitTypeFromJson(json['visitType']),
      status: visitStatusFromJson(json['status']),
      supervisorId: json['supervisorId'] as String?,
      supervisorName: json['supervisorName'] as String?,
      supervisorCheckInAt:
          json['supervisorCheckInAt'] != null
              ? _parseVisitTimestamp(
                json['supervisorCheckInAt'] as String,
                assumeUtcIfMissing: true,
              )
              : null,
      supervisorCheckOutAt:
          json['supervisorCheckOutAt'] != null
              ? _parseVisitTimestamp(
                json['supervisorCheckOutAt'] as String,
                assumeUtcIfMissing: true,
              )
              : null,
      supervisorCheckInLatitude:
          (json['supervisorCheckInLatitude'] as num?)?.toDouble(),
      supervisorCheckInLongitude:
          (json['supervisorCheckInLongitude'] as num?)?.toDouble(),
      supervisorCheckOutLatitude:
          (json['supervisorCheckOutLatitude'] as num?)?.toDouble(),
      supervisorCheckOutLongitude:
          (json['supervisorCheckOutLongitude'] as num?)?.toDouble(),
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble(),
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      googleMapsLink:
          (json['googleMapsLink'] as String?)?.isNotEmpty == true
              ? json['googleMapsLink'] as String?
              : null,
      createdAt:
          json['createdAt'] != null
              ? _parseVisitTimestamp(
                json['createdAt'] as String,
                assumeUtcIfMissing: true,
              )
              : null,
      actions: actions,
      // Customer ERP location attributes carried on the visit so the UI can
      // fall back to them when the visit's own googleMapsLink is empty.
      customerLocationPoint: _pickString(json, [
        'customerLocationPoint',
        'customerULocPnt',
        'customerLocPnt',
        'U_LOC_PNT',
        'u_LOC_PNT',
      ]),
      customerUGLink: _pickString(json, [
        'customerUGLink',
        'customerGoogleMapsLink',
        'U_G_Link',
        'u_G_Link',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      // Use API canonical keys only. Do not also emit `userName` and
      // `username`: under ASP.NET case-insensitive JSON they normalize to the
      // same names and trigger VisitDto property collision (400). [fromJson]
      // still reads legacy keys when loading old cache or older API payloads.
      if (userName != null) 'assignedUserFullName': userName,
      if (loginUsername != null) 'loginUsername': loginUsername,
      'customerId': customerId,
      'customerName': customerName,
      if (customerCode != null) 'customerCode': customerCode,
      if (journeyPlanId != null) 'journeyPlanId': journeyPlanId,
      'plannedDateTime': plannedDateTime.toIso8601String(),
      if (actualStartDateTime != null)
        'actualStartDateTime': actualStartDateTime!.toIso8601String(),
      if (actualEndDateTime != null)
        'actualEndDateTime': actualEndDateTime!.toIso8601String(),
      if (visitType != null) 'visitType': visitTypeToApiValue(visitType!),
      if (status != null) 'status': visitStatusToApiValue(status!),
      if (supervisorId != null) 'supervisorId': supervisorId,
      if (supervisorName != null) 'supervisorName': supervisorName,
      if (supervisorCheckInAt != null)
        'supervisorCheckInAt': supervisorCheckInAt!.toIso8601String(),
      if (supervisorCheckOutAt != null)
        'supervisorCheckOutAt': supervisorCheckOutAt!.toIso8601String(),
      if (supervisorCheckInLatitude != null)
        'supervisorCheckInLatitude': supervisorCheckInLatitude,
      if (supervisorCheckInLongitude != null)
        'supervisorCheckInLongitude': supervisorCheckInLongitude,
      if (supervisorCheckOutLatitude != null)
        'supervisorCheckOutLatitude': supervisorCheckOutLatitude,
      if (supervisorCheckOutLongitude != null)
        'supervisorCheckOutLongitude': supervisorCheckOutLongitude,
      if (checkInLatitude != null) 'checkInLatitude': checkInLatitude,
      if (checkInLongitude != null) 'checkInLongitude': checkInLongitude,
      if (checkOutLatitude != null) 'checkOutLatitude': checkOutLatitude,
      if (checkOutLongitude != null) 'checkOutLongitude': checkOutLongitude,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (googleMapsLink != null && googleMapsLink!.isNotEmpty)
        'googleMapsLink': googleMapsLink,
      if (customerLocationPoint != null && customerLocationPoint!.isNotEmpty)
        'customerLocationPoint': customerLocationPoint,
      if (customerUGLink != null && customerUGLink!.isNotEmpty)
        'customerUGLink': customerUGLink,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'actions': actions.map((a) => _visitActionToJson(a)).toList(),
    };
  }

  static Map<String, dynamic> _visitActionToJson(VisitAction a) {
    return {
      'id': a.id,
      'actionCode': a.actionCode,
      if (a.actionName != null) 'actionName': a.actionName,
      if (a.status != null) 'status': a.status,
      if (a.sapDocumentNumber != null) 'sapDocumentNumber': a.sapDocumentNumber,
      if (a.sapDocumentId != null) 'sapDocumentId': a.sapDocumentId,
      if (a.postedAt != null) 'postedAt': a.postedAt!.toIso8601String(),
    };
  }
}
