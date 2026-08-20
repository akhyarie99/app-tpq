# SiMasjid App (Flutter — Android)

Aplikasi native untuk Ustadz/Ustadzah TPQ, pendamping web SiMasjid (`../masjid`).
Arsitektur hybrid: layar native untuk fitur yang butuh hardware (GPS untuk presensi),
WebView untuk modul admin lain yang sudah ada di web (token auto-login).

## Menjalankan (development)

Pastikan backend Laravel (`../masjid`) sudah jalan di `php artisan serve` (default port 8000).

```bash
flutter pub get

# Emulator Android: 10.0.2.2 adalah alias localhost bawaan emulator, jadi default
# di lib/core/constants/app_config.dart sudah benar tanpa perlu --dart-define.
flutter run

# Device fisik: ganti ke IP LAN mesin dev.
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/mobile/v1 \
            --dart-define=WEB_BASE_URL=http://192.168.1.x:8000
```

Login pakai akun yang sudah punya role `ustadz`, `admin`, atau `super_admin` di backend
(role lain ditolak oleh `/api/mobile/v1/login`, lihat `MobileAuthController::login`).

## Multi-Tenant (Flavor)

Backend web SiMasjid sudah multi-tenant SaaS — tiap lembaga dapat subdomain/domain
sendiri. App ini mengikutinya: satu codebase, di-build ulang per lembaga jadi APK
terpisah dengan nama app, ikon, dan splash screen sendiri-sendiri, tiap flavor arah
ke subdomain lembaganya masing-masing. Pola ini diadaptasi dari `E:\project\hrm\hrm_mobile`
— bedanya, tiap flavor di sini bawa `apiBaseUrl`/`webBaseUrl` sendiri (lihat
`lib/config/flavor_config.dart`) karena tiap lembaga memang backend/subdomain terpisah,
bukan satu API multi-tenant dibedakan id seperti di HRM.

### Menjalankan flavor yang sudah ada

```bash
flutter run --flavor tpqalazharcilacap -t lib/main_tpqalazharcilacap.dart
flutter build apk --flavor tpqalazharcilacap -t lib/main_tpqalazharcilacap.dart --release
```

`flutter run`/`flutter build` tanpa `--flavor` (lewat `lib/main.dart`) tetap jalan untuk
dev cepat — fallback ke config `tpqalazharcilacap`.

### Menambah lembaga baru

Pakai script otomatis (generate config Dart, entry point, ikon, splash, dan daftarkan
flavor di Gradle sekaligus):

```bash
dart run tool/add_tenant.dart <flavor_id> <path/logo.png> "<Nama App>" <api_base_url> <web_base_url>

# Contoh:
dart run tool/add_tenant.dart tpqnurulhuda assets/tmp/logo.png "TPQ Nurul Huda" \
  https://tpqnurulhuda.tpq.smartedugame.com/api/mobile/v1 \
  https://tpqnurulhuda.tpq.smartedugame.com
```

Catatan:
- `flavor_id` harus huruf kecil + angka/underscore, diawali huruf, dan **tidak boleh
  diawali "test"** (direservasi Android Gradle Plugin untuk test variant — build akan
  gagal kalau dilanggar).
- Setelah script selesai, cek hasilnya: `flutter run --flavor <flavor_id> -t lib/main_<flavor_id>.dart`.
- Sisa langkah manual: siapkan signing config rilis sendiri sebelum publish ke Play Store
  (semua flavor saat ini masih pakai debug signing, lihat bagian "Yang sengaja belum
  dipasang" di bawah).

## Yang sudah dibangun

- Auth: login nomor HP, token Sanctum tersimpan di `flutter_secure_storage`, auto-logout saat 401.
- Dashboard: statistik kelas/santri/presensi hari ini + aksi cepat.
- Presensi: pilih kelas → input hadir/izin/sakit/alfa per santri → kirim dengan validasi GPS
  (radius 500m dari titik masjid, harus sama dengan validasi di backend) → rekap bulanan.
- Capaian santri: input nilai per mapel (semester aktif) + progres hafalan per surah.
- WebView: menu admin lengkap dibuka di WebView dengan auto-login lewat pertukaran
  token sekali-pakai (lihat `WebviewLoginController` di backend).

## Yang sengaja belum dipasang (butuh keputusan/kredensial dari Anda)

- **Firebase Cloud Messaging (push notif)**: `firebase_core`/`firebase_messaging` belum
  ditambahkan supaya build Android tidak butuh `google-services.json` yang belum ada.
  Backend (`FcmService`) sudah siap — riwayat notifikasi sudah tercatat di tab
  Notifikasi meski FCM belum aktif. Untuk mengaktifkan:
  1. Buat project di [Firebase Console](https://console.firebase.google.com), tambahkan app Android
     dengan package `com.simasjid.simasjid_app`.
  2. `dart pub global activate flutterfire_cli` lalu `flutterfire configure` di folder ini.
  3. Tambahkan `firebase_core`, `firebase_messaging`, `flutter_local_notifications` ke `pubspec.yaml`.
  4. Isi `FIREBASE_CREDENTIALS` di `.env` backend dengan path service account JSON, lalu
     `composer require kreait/laravel-firebase`.
- **Build release + signing**: `android/app/build.gradle.kts` masih pakai debug signing config.
  Sebelum rilis, generate keystore sendiri (`keytool -genkey ...`) dan buat
  `key.properties` + signing config release (jangan commit keystore/`key.properties` ke git).
- **Cleartext traffic** (`android:usesCleartextTraffic="true"` di AndroidManifest.xml) diaktifkan
  untuk dev server HTTP lokal. Sebelum rilis produksi (yang seharusnya sudah pakai HTTPS),
  ganti jadi network security config yang hanya mengizinkan cleartext untuk domain dev, atau
  hapus flag ini sepenuhnya jika backend produksi sudah full HTTPS.

## Struktur proyek

```
lib/
├── core/            # config, network (Dio + interceptor token), storage, lokasi
├── features/
│   ├── auth/        # login, token persistence
│   ├── dashboard/
│   ├── presensi/    # kelas -> input (GPS) -> rekap
│   ├── capaian/     # kelas -> santri -> nilai & hafalan
│   └── webview/     # wrapper WebView + auto-login
└── shared/          # theme (sinkron warna web), widget umum
```

State management: `flutter_riverpod` (tanpa code-gen). API layer: `dio` (tanpa retrofit
code-gen) — pilihan ini supaya build tetap ringan/stabil tanpa langkah `build_runner`.
