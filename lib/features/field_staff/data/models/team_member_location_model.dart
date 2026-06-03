import 'package:equatable/equatable.dart';

DateTime? _parseUpdatedAt(dynamic raw) {
  if (raw == null) return null;
  final value = raw.toString();
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed.toLocal();

  final hasTimezone =
      value.endsWith('Z') || RegExp(r'([+-]\d{2}:\d{2})$').hasMatch(value);
  if (hasTimezone) return parsed.toLocal();

  // Backend often sends UTC without timezone suffix.
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

class TeamMemberLocationModel extends Equatable {
  const TeamMemberLocationModel({
    required this.userId,
    required this.fullName,
    this.isOnline,
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.accuracyMeters,
  });

  final String userId;
  final String fullName;
  final bool? isOnline;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;
  final double? accuracyMeters;

  static const Duration _onlineWindow = Duration(minutes: 2);
  static const Duration _futureSkewTolerance = Duration(minutes: 2);

  bool get isCurrentlyOnline {
    final now = DateTime.now();
    final ts = updatedAt;
    if (ts != null) {
      final delta = now.difference(ts.toLocal());
      // "Near now": accept both slightly past and slightly future timestamps.
      if (delta <= _onlineWindow && delta >= -_futureSkewTolerance) {
        return true;
      }
      return false;
    }
    return (isOnline ?? false) && hasCoordinates;
  }

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  factory TeamMemberLocationModel.fromJson(Map<String, dynamic> json) {
    bool? parseOnlineStatus() {
      final direct = json['isOnline'];
      if (direct is bool) return direct;
      final statusRaw =
          json['status'] ?? json['presenceStatus'] ?? json['connectionStatus'];
      if (statusRaw == null) return null;
      final s = statusRaw.toString().trim().toLowerCase();
      if (s == 'online' || s == 'active') return true;
      if (s == 'offline' || s == 'inactive') return false;
      return null;
    }

    return TeamMemberLocationModel(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      isOnline: parseOnlineStatus(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: _parseUpdatedAt(json['updatedAt']),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    fullName,
    isOnline,
    latitude,
    longitude,
    updatedAt,
    accuracyMeters,
  ];
}
