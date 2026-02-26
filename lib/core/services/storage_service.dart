import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage Methods (for sensitive data like tokens)
  static Future<void> storeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }

  // Regular Storage Methods (for non-sensitive data)
  static Future<void> storeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> storeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> storeInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> storeDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<void> storeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, json.encode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  // Chat-related storage methods
  static Future<void> saveChatMessage(Map<String, dynamic> message) async {
    final rideId = message['rideId'] as String;
    final key = 'chat_$rideId';

    final existingMessages = _prefs.getStringList(key) ?? [];
    existingMessages.add(json.encode(message));

    await _prefs.setStringList(key, existingMessages);
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(
    String rideId,
  ) async {
    final key = 'chat_$rideId';
    final messagesStrings = _prefs.getStringList(key) ?? [];

    return messagesStrings.map((messageString) {
      return json.decode(messageString) as Map<String, dynamic>;
    }).toList();
  }

  static Future<void> clearChatHistory(String rideId) async {
    final key = 'chat_$rideId';
    await _prefs.remove(key);
  }
}
