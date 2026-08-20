import 'config/flavor_config.dart';
import 'config/flavors/tpqalazharcilacap_config.dart';
import 'main_common.dart';

/// Jalankan dengan:
/// flutter run --flavor tpqalazharcilacap -t lib/main_tpqalazharcilacap.dart
/// flutter build apk --flavor tpqalazharcilacap -t lib/main_tpqalazharcilacap.dart
void main() {
  FlavorConfig.setInstance(tpqalazharcilacapConfig);
  runSiMasjidApp();
}
