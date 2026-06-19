import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> setString(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> getString(String key) => _storage.read(key: key);
  Future<void> deleteString(String key) => _storage.delete(key: key);

  Future<void> setBool(String key, bool value) => _storage.write(key: key, value: value.toString());
  Future<bool> getBool(String key) async {
    final v = await _storage.read(key: key);
    return v == 'true';
  }

  Future<void> clearAll() => _storage.deleteAll();
}
