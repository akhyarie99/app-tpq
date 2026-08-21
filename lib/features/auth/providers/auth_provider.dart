import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';

/// [locked] — sesi (token) sudah ada, tapi login biometrik diaktifkan dan
/// belum diverifikasi di pembukaan app kali ini. Beda dari [unauthenticated]:
/// user TIDAK perlu ketik ulang nomor HP/password, cukup verifikasi
/// biometrik lewat [AuthNotifier.unlockWithBiometric] untuk lanjut ke
/// [authenticated] (form login tetap tersedia sebagai fallback).
enum AuthStatus { bootstrapping, unauthenticated, authenticating, authenticated, locked }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage, this.biometricAvailable = false});

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool biometricAvailable;

  static const initial = AuthState(status: AuthStatus.bootstrapping);

  AuthState copyWith({AuthStatus? status, UserModel? user, String? errorMessage, bool? biometricAvailable}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref.read(biometricServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._biometricService) : super(AuthState.initial) {
    DioClient.instance.onUnauthorized = _forceLogout;
    bootstrap();
  }

  final AuthRepository _repository;
  final BiometricService _biometricService;

  // True tepat setelah login pakai password berhasil (bukan restore sesi
  // atau unlock biometrik) — dipakai HomeShell untuk menawarkan aktivasi
  // biometrik sekali saja, lalu di-reset lewat consumeJustLoggedIn().
  bool _justLoggedInWithPassword = false;

  bool consumeJustLoggedIn() {
    final value = _justLoggedInWithPassword;
    _justLoggedInWithPassword = false;
    return value;
  }

  Future<void> bootstrap() async {
    final biometricAvailable = await _biometricService.isAvailable();

    String? token;
    try {
      token = await SecureStorage.instance.readToken();
    } catch (_) {
      // Secure storage tidak tersedia (mis. platform channel belum siap saat test) — anggap belum login.
      state = state.copyWith(status: AuthStatus.unauthenticated, biometricAvailable: biometricAvailable);
      return;
    }

    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated, biometricAvailable: biometricAvailable);
      return;
    }

    final biometricEnabled = await SecureStorage.instance.isBiometricEnabled();
    if (biometricEnabled && biometricAvailable) {
      state = state.copyWith(status: AuthStatus.locked, biometricAvailable: biometricAvailable);
      return;
    }

    await _finishRestoring(biometricAvailable);
  }

  Future<void> _finishRestoring(bool biometricAvailable) async {
    try {
      final user = await _repository.fetchProfile();
      state = state.copyWith(status: AuthStatus.authenticated, user: user, biometricAvailable: biometricAvailable);
    } on ApiException {
      await SecureStorage.instance.clear();
      state = state.copyWith(status: AuthStatus.unauthenticated, biometricAvailable: biometricAvailable);
    }
  }

  /// Dipanggil dari layar kunci — sukses membuka sesi yang sudah tersimpan
  /// TANPA password, gagal/dibatalkan tetap di status [AuthStatus.locked].
  Future<bool> unlockWithBiometric() async {
    try {
      final confirmed = await _biometricService.authenticate(
        reason: 'Verifikasi identitas Anda untuk membuka aplikasi',
      );
      if (!confirmed) return false;

      await _finishRestoring(state.biometricAvailable);
      return state.status == AuthStatus.authenticated;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> login({required String phone, required String password, String? fcmToken}) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final user = await _repository.login(phone: phone, password: password, fcmToken: fcmToken);
      _justLoggedInWithPassword = true;
      final biometricAvailable = await _biometricService.isAvailable();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
        biometricAvailable: biometricAvailable,
      );
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.message);
    }
  }

  Future<bool> isBiometricEnabled() => SecureStorage.instance.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) => SecureStorage.instance.setBiometricEnabled(enabled);

  /// Dipanggil dari tombol "Keluar" — kalau login biometrik aktif, ini cuma
  /// mengunci app ([lockApp], token TETAP tersimpan supaya sidik jari/wajah
  /// masih bisa membuka sesi yang sama lagi nanti) alih-alih membakar sesi
  /// sepenuhnya. Device yang sudah dikunci lewat sidik jari/wajah pemiliknya
  /// dianggap seaman lock screen HP itu sendiri — kalau mau benar-benar
  /// keluar dari akun (device dipakai orang lain), matikan dulu toggle
  /// "Login Biometrik" di Profil, baru tekan Keluar.
  Future<void> logout() async {
    if (await isBiometricEnabled()) {
      lockApp();
    } else {
      await signOut();
    }
  }

  /// Mengunci app tanpa memutus sesi — token & preferensi biometrik tetap
  /// tersimpan, cuma state di memori yang dibersihkan.
  void lockApp() {
    state = AuthState(status: AuthStatus.locked, biometricAvailable: state.biometricAvailable);
  }

  /// Logout penuh — revoke token di server, hapus token & preferensi
  /// biometrik dari secure storage.
  Future<void> signOut() async {
    await _repository.logout();
    state = AuthState(status: AuthStatus.unauthenticated, biometricAvailable: state.biometricAvailable);
  }

  void _forceLogout() {
    SecureStorage.instance.clear();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Sesi Anda berakhir, silakan login kembali.',
      biometricAvailable: state.biometricAvailable,
    );
  }
}
