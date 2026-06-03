/// Same key as Android `com.google.android.geo.API_KEY`, iOS, and `web/index.html`.
/// Enable **Geocoding API** in Google Cloud for reverse address lookup.
/// Override at build time: `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
const String kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyBQmdDok73WKd0Yj5y3Zbw09odqLzj4Igo',
);
