import 'package:local_auth/local_auth.dart';

/// Tipis di atas `local_auth` — dipakai untuk mengunci/membuka sesi yang
/// sudah tersimpan lewat [SecureStorage] tanpa perlu ketik ulang password.
/// Ini BUKAN pengganti login: biometrik cuma memverifikasi identitas
/// pemilik device sebelum sesi (token API) yang sudah ada dipakai lagi.
class BiometricService {
  LocalAuthentication? _auth;

  // Dikonstruksi lazy DI DALAM try/catch pemanggilnya (bukan field
  // initializer) — plugin ini menyentuh platform channel saat dikonstruksi,
  // yang bisa melempar error di luar device nyata (mis. widget test tanpa
  // binding plugin). Kalau dikonstruksi sebagai field biasa, error itu lolos
  // dari try/catch method-method di bawah ini.
  LocalAuthentication get _instance => _auth ??= LocalAuthentication();

  /// True kalau hardware biometrik tersedia DAN sudah didaftarkan (ada
  /// sidik jari/wajah yang terenroll di pengaturan OS).
  Future<bool> isAvailable() async {
    try {
      final auth = _instance;
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;

      final enrolled = await auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Throws kalau gagal/dibatalkan — pemanggil cukup try/catch dan
  /// menampilkan pesannya, mirip ApiException di layar lain.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _instance.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      throw Exception('Autentikasi biometrik gagal: $e');
    }
  }
}
