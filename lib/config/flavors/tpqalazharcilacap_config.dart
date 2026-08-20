import '../flavor_config.dart';

/// Config untuk TPQ Al-Azhar Cilacap (lembaga pertama yang pakai app ini).
/// Duplikasi file ini untuk lembaga baru — lihat README bagian
/// "Multi-Tenant (Flavor)", atau pakai `dart run tool/add_tenant.dart`.
final FlavorConfig tpqalazharcilacapConfig = const FlavorConfig(
  flavorId: 'tpqalazharcilacap',
  appName: 'TPQ Al-Azhar Cilacap',
  logoAssetPath: 'assets/images/logo.png',
  apiBaseUrl: 'https://tpqalazharcilacap.tpq.smartedugame.com/api/mobile/v1',
  webBaseUrl: 'https://tpqalazharcilacap.tpq.smartedugame.com',
);
