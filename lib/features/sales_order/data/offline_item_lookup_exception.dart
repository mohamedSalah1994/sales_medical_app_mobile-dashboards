/// Thrown when item lookup runs offline and no cached ODBC payload exists.
class OfflineItemLookupCacheMiss implements Exception {
  OfflineItemLookupCacheMiss([this.message =
      'Offline: no cached item for this search. Connect while online, search once to cache it, then try again offline.']);

  final String message;

  @override
  String toString() => message;
}
