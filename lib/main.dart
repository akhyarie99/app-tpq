import 'config/flavor_config.dart';
import 'config/flavors/tpqalazharcilacap_config.dart';
import 'main_common.dart';

/// Entry point default/dev (tanpa --flavor) — fallback ke config TPQ
/// Al-Azhar Cilacap supaya `flutter run` biasa tetap jalan untuk
/// pengembangan cepat. Build rilis per-lembaga pakai main_{flavor}.dart
/// masing-masing, lihat README bagian "Multi-Tenant (Flavor)".
void main() {
  FlavorConfig.setInstance(tpqalazharcilacapConfig);
  runSiMasjidApp();
}
