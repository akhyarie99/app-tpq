// ignore_for_file: avoid_print
//
// Otomatisasi checklist "Menambah Lembaga Baru" di README.md — generate
// semua file branding per-flavor (config Dart, entry point, yaml icon/
// splash) dan menyisipkan blok productFlavors + entri assets yang
// dibutuhkan, lalu menjalankan flutter_launcher_icons & flutter_native_splash
// untuk flavor itu. Diadaptasi dari pola yang sama di E:\project\hrm
// (hrm_mobile/tool/add_tenant.dart) — beda utamanya: tiap lembaga di sini
// punya apiBaseUrl/webBaseUrl sendiri (backend/subdomain terpisah per
// tenant), bukan 1 backend dibedakan company_id, jadi tidak ada langkah
// google-services.json/Firebase (app ini juga belum pakai FCM sama sekali).
//
// Pemakaian:
//   dart run tool/add_tenant.dart <flavor_id> <path/logo.png> "<Nama App>" <api_base_url> <web_base_url> [application_id_suffix]
//
// Contoh:
//   dart run tool/add_tenant.dart tpqnurulhuda assets/tmp/logo.png "TPQ Nurul Huda" https://tpqnurulhuda.tpq.smartedugame.com/api/mobile/v1 https://tpqnurulhuda.tpq.smartedugame.com
//
// Jalankan dari root project (folder yang berisi pubspec.yaml).

import 'dart:io';

import 'generate_splash_safe.dart';

void main(List<String> args) async {
  if (args.length < 5) {
    stderr.writeln(
      'Pemakaian: dart run tool/add_tenant.dart <flavor_id> <path/logo.png> "<Nama App>" <api_base_url> <web_base_url> [application_id_suffix]',
    );
    exit(1);
  }

  final flavorId = args[0].trim();
  final logoPath = args[1].trim();
  final appName = args[2].trim();
  final apiBaseUrl = args[3].trim();
  final webBaseUrl = args[4].trim();
  final applicationIdSuffix = args.length > 5 ? args[5].trim() : flavorId;

  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(flavorId)) {
    stderr.writeln(
      'flavor_id harus huruf kecil, angka, underscore, dan diawali huruf. Contoh: tpqnurulhuda, masjid_agung',
    );
    exit(1);
  }

  // Android Gradle Plugin mereservasi nama varian berawalan "test" untuk
  // source set instrumentation test-nya sendiri (testDebug, androidTest,
  // dst) — flavor dengan nama itu bikin build gagal: "ProductFlavor names
  // cannot start with 'test'". Ketemu langsung waktu nge-test script ini.
  if (flavorId.startsWith('test')) {
    stderr.writeln(
      'flavor_id tidak boleh diawali "test" — itu nama yang direservasi Android Gradle Plugin untuk test variant, build akan gagal.',
    );
    exit(1);
  }

  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'Jalankan script ini dari root project Flutter (folder yang ada pubspec.yaml).',
    );
    exit(1);
  }

  final logoFile = File(logoPath);
  if (!logoFile.existsSync()) {
    stderr.writeln('Logo tidak ditemukan: $logoPath');
    exit(1);
  }

  final configFile = File('lib/config/flavors/${flavorId}_config.dart');
  final mainFile = File('lib/main_$flavorId.dart');
  if (configFile.existsSync() || mainFile.existsSync()) {
    stderr.writeln(
      'Flavor "$flavorId" sepertinya sudah ada (${configFile.path} / ${mainFile.path} sudah ada). Hapus dulu kalau mau bikin ulang.',
    );
    exit(1);
  }

  print('== Menambah flavor "$flavorId" ==');

  // 1. Logo asset
  final assetDir = Directory('assets/flavors/$flavorId');
  assetDir.createSync(recursive: true);
  final assetLogoPath = 'assets/flavors/$flavorId/logo.png';
  logoFile.copySync(assetLogoPath);
  print('[ok] Logo disalin ke $assetLogoPath');

  // 2. Flavor config
  configFile.createSync(recursive: true);
  configFile.writeAsStringSync('''
import '../flavor_config.dart';

final FlavorConfig ${flavorId}Config = const FlavorConfig(
  flavorId: '$flavorId',
  appName: '${_escapeDart(appName)}',
  logoAssetPath: '$assetLogoPath',
  apiBaseUrl: '${_escapeDart(apiBaseUrl)}',
  webBaseUrl: '${_escapeDart(webBaseUrl)}',
);
''');
  print('[ok] ${configFile.path} dibuat');

  // 3. main_<flavor>.dart entry point
  mainFile.writeAsStringSync('''
import 'config/flavor_config.dart';
import 'config/flavors/${flavorId}_config.dart';
import 'main_common.dart';

/// Jalankan dengan:
/// flutter run --flavor $flavorId -t lib/main_$flavorId.dart
/// flutter build apk --flavor $flavorId -t lib/main_$flavorId.dart
void main() {
  FlavorConfig.setInstance(${flavorId}Config);
  runSiMasjidApp();
}
''');
  print('[ok] ${mainFile.path} dibuat');

  // 4. flutter_launcher_icons-<flavor>.yaml
  File('flutter_launcher_icons-$flavorId.yaml').writeAsStringSync('''
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "$assetLogoPath"
  min_sdk_android: 23
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "$assetLogoPath"
''');
  print('[ok] flutter_launcher_icons-$flavorId.yaml dibuat');

  // 5. flutter_native_splash-<flavor>.yaml — Android 12+ (API 31+) pakai splash
  // API baru yang cuma menampilkan ikon di dalam "safe zone" lingkaran
  // terbatas; logo full-bleed apa adanya akan KEPOTONG di situ.
  // generateSplashSafe() otomatis bikin versi aman (logo diperkecil +
  // padding) supaya tidak perlu asset manual terpisah.
  final splashSafePath = 'assets/flavors/$flavorId/splash_safe.png';
  generateSplashSafe(flavorId, assetLogoPath);

  File('flutter_native_splash-$flavorId.yaml').writeAsStringSync('''
flutter_native_splash:
  color: "#FFFFFF"
  image: $assetLogoPath
  android: true
  ios: false
  android_12:
    color: "#FFFFFF"
    image: $splashSafePath
''');
  print('[ok] flutter_native_splash-$flavorId.yaml dibuat');

  // 6. pubspec.yaml -> flutter.assets
  _patchPubspecAssets(flavorId);

  // 7. android/app/build.gradle.kts -> productFlavors
  _patchGradleFlavors(flavorId, applicationIdSuffix, appName);

  // 8. Jalankan generator icon & splash untuk flavor ini.
  print('\n== Menjalankan flutter_launcher_icons & flutter_native_splash ==');
  await _run('dart', [
    'run',
    'flutter_launcher_icons',
    '-f',
    'flutter_launcher_icons-$flavorId.yaml',
  ]);
  await _run('dart', [
    'run',
    'flutter_native_splash:create',
    '--flavor',
    flavorId,
  ]);

  print('''

== Selesai ==
Sisa langkah manual (tidak bisa diotomatisasi):
  1. Siapkan signing config rilis sendiri sebelum publish ke Play Store
     (saat ini semua flavor masih pakai debug signing).
  2. Cek hasilnya:
     flutter run --flavor $flavorId -t lib/main_$flavorId.dart
''');
}

String _escapeDart(String s) => s.replaceAll("'", "\\'");

// Escaping App Name untuk `resValue("string", "app_name", "...")` di
// build.gradle.kts — BEDA dari _escapeDart(). Kotlin mem-parse `\'` di
// source jadi karakter apostrof polos SEBELUM nilainya ditulis apa adanya
// oleh AGP ke XML resource string yang di-generate — jadi kalau appName
// punya apostrof, _escapeDart menghasilkan apostrof mentah di XML itu dan
// aapt2 gagal compile resource. Yang dibutuhkan XML resource Android adalah
// backslash literal + apostrof (\'), jadi source Kotlin-nya perlu DUA
// backslash (Kotlin escape utk satu backslash literal) + apostrof.
String _escapeGradleResValue(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll("'", "\\\\'");

void _patchPubspecAssets(String flavorId) {
  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();
  final entry = '    - assets/flavors/$flavorId/';

  if (lines.contains(entry)) {
    print('[skip] pubspec.yaml sudah punya entri assets untuk flavor ini');
    return;
  }

  final assetsIdx = lines.indexWhere((l) => l.trim() == 'assets:');
  if (assetsIdx == -1) {
    stderr.writeln(
      '[warn] Tidak ketemu "assets:" di pubspec.yaml — tambahkan manual: $entry',
    );
    return;
  }

  var insertAt = assetsIdx + 1;
  while (insertAt < lines.length &&
      lines[insertAt].trimLeft().startsWith('- ')) {
    insertAt++;
  }

  lines.insert(insertAt, entry);
  file.writeAsStringSync('${lines.join('\n')}\n');
  print('[ok] pubspec.yaml: ditambahkan "$entry"');
}

void _patchGradleFlavors(
  String flavorId,
  String applicationIdSuffix,
  String appName,
) {
  final file = File('android/app/build.gradle.kts');
  var content = file.readAsStringSync();

  if (content.contains('create("$flavorId")')) {
    print('[skip] build.gradle.kts sudah punya flavor "$flavorId"');
    return;
  }

  // File ini bisa saja di-checkout dengan CRLF di Windows — deteksi gaya
  // newline yang sebenarnya dipakai, supaya penyisipan tidak mengganti
  // seluruh file jadi LF (yang bikin diff git jadi berantakan padahal cuma
  // nambah satu blok).
  final eol = content.contains('\r\n') ? '\r\n' : '\n';

  // Anchor: baris penutup create(...) terakhir (indent 8) diikuti penutup
  // productFlavors (indent 4). PENTING: pola ini juga cocok dengan penutup
  // blok buildTypes { release { ... } } (indentasi sama persis) yang selalu
  // muncul LEBIH DULU di file ini — replaceFirst() naif pernah salah tempel
  // flavor baru ke dalam buildTypes. Cari dulu awal blok "productFlavors {"
  // dan baru cari anchor SETELAH titik itu supaya tidak ambigu.
  final productFlavorsIdx = content.indexOf('productFlavors {');
  if (productFlavorsIdx == -1) {
    stderr.writeln(
      '[warn] Tidak ketemu blok "productFlavors {" di build.gradle.kts — tambahkan manual:',
    );
    stderr.writeln('''
        create("$flavorId") {
            dimension = "tenant"
            applicationId = "com.simasjid.simasjid_app.$applicationIdSuffix"
            resValue("string", "app_name", "${_escapeGradleResValue(appName)}")
        }''');
    return;
  }

  final anchor = '        }$eol    }';
  final anchorIdx = content.indexOf(anchor, productFlavorsIdx);
  if (anchorIdx == -1) {
    stderr.writeln(
      '[warn] Tidak ketemu penutup blok productFlavors di build.gradle.kts — tambahkan manual:',
    );
    stderr.writeln('''
        create("$flavorId") {
            dimension = "tenant"
            applicationId = "com.simasjid.simasjid_app.$applicationIdSuffix"
            resValue("string", "app_name", "${_escapeGradleResValue(appName)}")
        }''');
    return;
  }

  final newBlock =
      '        }$eol'
      '        create("$flavorId") {$eol'
      '            dimension = "tenant"$eol'
      '            applicationId = "com.simasjid.simasjid_app.$applicationIdSuffix"$eol'
      '            resValue("string", "app_name", "${_escapeGradleResValue(appName)}")$eol'
      '        }$eol'
      '    }';

  content = content.replaceRange(anchorIdx, anchorIdx + anchor.length, newBlock);
  file.writeAsStringSync(content);
  print(
    '[ok] android/app/build.gradle.kts: flavor "$flavorId" ditambahkan (applicationId com.simasjid.simasjid_app.$applicationIdSuffix)',
  );
}

Future<void> _run(String executable, List<String> arguments) async {
  print('\$ $executable ${arguments.join(' ')}');
  final result = await Process.run(executable, arguments, runInShell: true);
  stdout.write(result.stdout);
  if (result.stderr.toString().trim().isNotEmpty) {
    stderr.write(result.stderr);
  }
  if (result.exitCode != 0) {
    stderr.writeln(
      '[warn] Perintah di atas gagal (exit code ${result.exitCode}) — jalankan manual setelah cek masalahnya.',
    );
  }
}
