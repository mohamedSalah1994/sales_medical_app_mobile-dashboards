import 'package:sales_medical_app_mobile/features/journey_plan/domain/entities/visit_action.dart';

class Visit {
  final String id;
  final String? userId;
  final String? userName;
  final String? loginUsername;
  final String customerId;
  final String customerName;
  final String? customerCode;
  final String? journeyPlanId;
  final DateTime plannedDateTime;
  final DateTime? actualStartDateTime;
  final DateTime? actualEndDateTime;
  final int? visitType;
  final int? status;
  final String? supervisorId;
  final String? supervisorName;
  final DateTime? supervisorCheckInAt;
  final DateTime? supervisorCheckOutAt;
  final double? supervisorCheckInLatitude;
  final double? supervisorCheckInLongitude;
  final double? supervisorCheckOutLatitude;
  final double? supervisorCheckOutLongitude;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? notes;
  final String? googleMapsLink;
  final DateTime? createdAt;
  final List<VisitAction> actions;

  /// Customer location string from ERP (`U_LOC_PNT`), e.g. `(24.40,32.92)`.
  /// Carried on the visit so the UI can derive a maps link as a fallback when
  /// [googleMapsLink] is not set.
  final String? customerLocationPoint;

  /// Customer Google Maps URL from ERP (`U_G_Link`). Used as a secondary
  /// fallback for [effectiveGoogleMapsLink].
  final String? customerUGLink;

  const Visit({
    required this.id,
    this.userId,
    this.userName,
    this.loginUsername,
    required this.customerId,
    required this.customerName,
    this.customerCode,
    this.journeyPlanId,
    required this.plannedDateTime,
    this.actualStartDateTime,
    this.actualEndDateTime,
    this.visitType,
    this.status,
    this.supervisorId,
    this.supervisorName,
    this.supervisorCheckInAt,
    this.supervisorCheckOutAt,
    this.supervisorCheckInLatitude,
    this.supervisorCheckInLongitude,
    this.supervisorCheckOutLatitude,
    this.supervisorCheckOutLongitude,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.notes,
    this.googleMapsLink,
    this.createdAt,
    this.actions = const [],
    this.customerLocationPoint,
    this.customerUGLink,
  });

  /// SAP **cardCode** when present; otherwise [customerId] (matches ERP screen pre-fill).
  String? get erpCustomerCardOrId {
    final c = customerCode?.trim();
    if (c != null && c.isNotEmpty) return c;
    final id = customerId.trim();
    return id.isEmpty ? null : id;
  }

  /// Best-effort Google Maps URL for the visit:
  ///   1. The visit's own [googleMapsLink] when set.
  ///   2. The customer's stored ERP map URL (`U_G_Link`) when set.
  ///   3. A URL derived from the customer's `U_LOC_PNT` when it parses as
  ///      `(lat,lng)` or `lat,lng`.
  String? get effectiveGoogleMapsLink {
    final ownLink = googleMapsLink?.trim();
    if (ownLink != null && ownLink.isNotEmpty) return ownLink;

    final cuLink = customerUGLink?.trim();
    if (cuLink != null && cuLink.isNotEmpty) return cuLink;

    var raw = customerLocationPoint?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    if (raw.startsWith('(') && raw.endsWith(')')) {
      raw = raw.substring(1, raw.length - 1);
    }
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return 'https://www.google.com/maps?q=$lat,$lng';
  }
}
