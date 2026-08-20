/// Konfigurasi per-lembaga (flavor) — satu codebase, di-build ulang per
/// tenant dengan applicationId, nama app, ikon, splash, dan warna berbeda.
///
/// Beda dari pola flavor umum (mis. HRM): tiap lembaga SiMasjid pada
/// dasarnya backend/subdomain SENDIRI (bukan 1 API multi-tenant dibedakan
/// lewat id), jadi FlavorConfig ini juga bawa [apiBaseUrl]/[webBaseUrl]
/// milik tenant-nya masing-masing.
class FlavorConfig {
  /// Slug unik lembaga (dipakai di applicationId & sebagai identitas flavor).
  final String flavorId;

  /// Nama yang tampil di title bar / layar login / nama app di HP.
  final String appName;

  /// Path logo asset khusus flavor ini.
  final String logoAssetPath;

  /// Base URL API mobile lembaga ini, mis. https://{slug}.tpq.smartedugame.com/api/mobile/v1
  final String apiBaseUrl;

  /// Base URL web lembaga ini (dipakai webview_flutter untuk fitur berbasis web).
  final String webBaseUrl;

  const FlavorConfig({
    required this.flavorId,
    required this.appName,
    required this.logoAssetPath,
    required this.apiBaseUrl,
    required this.webBaseUrl,
  });

  /// Instance aktif, di-set sekali di `main_{flavor}.dart` saat app start.
  static late FlavorConfig instance;

  static void setInstance(FlavorConfig config) {
    instance = config;
  }
}
