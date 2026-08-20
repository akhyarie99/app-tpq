import '../../config/flavor_config.dart';

/// Konfigurasi environment aplikasi.
///
/// Untuk dev lokal (emulator/device fisik), override tetap bisa lewat
/// --dart-define, contoh:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/mobile/v1
///
/// Kalau --dart-define tidak diisi, fallback ke apiBaseUrl/webBaseUrl milik
/// flavor yang aktif (FlavorConfig.instance) — jadi build rilis per lembaga
/// otomatis arah ke subdomain masing-masing tanpa perlu --dart-define manual.
class AppConfig {
  AppConfig._();

  /// 10.0.2.2 adalah alias localhost bawaan Android emulator.
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _webBaseUrlOverride = String.fromEnvironment('WEB_BASE_URL');

  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : FlavorConfig.instance.apiBaseUrl;

  /// URL root web SiMasjid, dipakai WebViewScreen untuk halaman non-native.
  static String get webBaseUrl =>
      _webBaseUrlOverride.isNotEmpty ? _webBaseUrlOverride : FlavorConfig.instance.webBaseUrl;

  /// Radius maksimum (meter) dari titik masjid saat presensi — harus sama dengan
  /// validasi di backend (lihat MobilePresensiController::submit di Laravel).
  static const double presensiMaxRadiusMeters = 500;
}
