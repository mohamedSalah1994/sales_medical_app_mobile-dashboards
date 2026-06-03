class Customer {
  final String id;
  final String customerCode;
  final String name;
  /// Arabic / alternate name from API when present (`cardForeignName` / `foreignName`).
  final String foreignName;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String locationPoint;
  /// ERP Google Maps URL from ODBC (`U_G_Link`).
  final String? uGLink;
  final double latitude;
  final double longitude;
  final int status;
  final String externalId;
  final DateTime createdAt;

  /// ODBC/BP `cardType`: `C` = customer, `L` = lead.
  final String cardType;

  const Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    this.foreignName = '',
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.locationPoint,
    this.uGLink,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.externalId,
    required this.createdAt,
    this.cardType = '',
  });

  String? get googleMapsLink {
    final link = uGLink?.trim();
    if (link != null && link.isNotEmpty) return link;

    var raw = locationPoint.trim();
    if (raw.isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }
      if (raw.startsWith('(') && raw.endsWith(')')) {
        raw = raw.substring(1, raw.length - 1);
      }
      final parts = raw.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          return 'https://www.google.com/maps?q=$lat,$lng';
        }
      }
    }
    if (latitude != 0.0 || longitude != 0.0) {
      return 'https://www.google.com/maps?q=$latitude,$longitude';
    }
    return null;
  }

  /// Text for the visit "Google Maps link" field when the user selects this customer.
  ///
  /// Uses ERP [uGLink] when set; otherwise the raw [locationPoint] (`U_LOC_PNT`,
  /// e.g. `(24.407456053716043,32.92586009949446)`), not a converted `https://` URL.
  /// If only [latitude]/[longitude] are known, formats them the same way.
  String? get visitGoogleMapsFieldValue {
    final link = uGLink?.trim();
    if (link != null && link.isNotEmpty) {
      return link;
    }
    final loc = locationPoint.trim();
    if (loc.isNotEmpty) {
      return loc;
    }
    if (latitude != 0.0 || longitude != 0.0) {
      return '($latitude,$longitude)';
    }
    return null;
  }

  /// `name (code)` with foreign name appended when distinct (filters, dropdowns).
  String get displayLabelWithCode {
    final f = foreignName.trim();
    final n = name.trim();
    final base =
        customerCode.isNotEmpty ? '$n ($customerCode)' : n;
    if (f.isNotEmpty && f != n) return '$base · $f';
    return base;
  }

  /// Second line for pickers when [foreignName] differs from [name].
  String? get distinctForeignNameLine {
    final f = foreignName.trim();
    final n = name.trim();
    if (f.isEmpty || f == n) return null;
    return f;
  }
}
