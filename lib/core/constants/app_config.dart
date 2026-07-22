/// Konfigurasi environment aplikasi.
///
/// Override saat build/run dengan --dart-define, contoh:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/mobile/v1
///   flutter build apk --dart-define=API_BASE_URL=https://simasjid.yourdomain.com/api/mobile/v1
class AppConfig {
  AppConfig._();

  /// 10.0.2.2 adalah alias localhost bawaan Android emulator.
  /// Untuk device fisik, ganti ke IP LAN mesin dev (mis. http://192.168.1.x:8000/api/mobile/v1).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/mobile/v1',
  );

  /// URL root web SiMasjid, dipakai WebViewScreen untuk halaman non-native.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Radius maksimum (meter) dari titik masjid saat presensi — harus sama dengan
  /// validasi di backend (lihat MobilePresensiController::submit di Laravel).
  static const double presensiMaxRadiusMeters = 500;
}
