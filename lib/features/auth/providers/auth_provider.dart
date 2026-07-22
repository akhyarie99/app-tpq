import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';

enum AuthStatus { bootstrapping, unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  static const initial = AuthState(status: AuthStatus.bootstrapping);

  AuthState copyWith({AuthStatus? status, UserModel? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(AuthState.initial) {
    DioClient.instance.onUnauthorized = _forceLogout;
    bootstrap();
  }

  final AuthRepository _repository;

  Future<void> bootstrap() async {
    String? token;
    try {
      token = await SecureStorage.instance.readToken();
    } catch (_) {
      // Secure storage tidak tersedia (mis. platform channel belum siap saat test) — anggap belum login.
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _repository.fetchProfile();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on ApiException {
      await SecureStorage.instance.clear();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String phone, required String password, String? fcmToken}) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final user = await _repository.login(phone: phone, password: password, fcmToken: fcmToken);
      state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: null);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.message);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _forceLogout() {
    SecureStorage.instance.clear();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Sesi Anda berakhir, silakan login kembali.',
    );
  }
}
