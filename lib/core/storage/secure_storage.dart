import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper tipis di atas flutter_secure_storage — satu tempat untuk semua
/// key penyimpanan sensitif (token, data user ringan) agar tidak tersebar.
class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userRoleKey = 'user_role';
  static const _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserBasics({required String name, required String role}) async {
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async => (await _storage.read(key: _biometricEnabledKey)) == 'true';

  Future<void> clear() => _storage.deleteAll();
}
