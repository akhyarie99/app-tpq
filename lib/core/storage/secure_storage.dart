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

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserBasics({required String name, required String role}) async {
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<void> clear() => _storage.deleteAll();
}
