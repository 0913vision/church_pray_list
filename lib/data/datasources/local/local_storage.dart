import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/prayer_data.dart';
import '../../models/user_session.dart';

class LocalStorage {
  LocalStorage({
    SharedPreferences? prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefsFuture = prefs != null
            ? Future.value(prefs)
            : SharedPreferences.getInstance(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _cacheKey = 'cached_prayer_data';
  static const String _sessionKey = 'kakao_user_session';

  final Future<SharedPreferences> _prefsFuture;
  final FlutterSecureStorage _secureStorage;

  // --- Prayer Data Cache ---

  Future<PrayerData?> loadCachedPrayer() async {
    try {
      final prefs = await _prefsFuture;
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return null;
      return PrayerData.fromJsonString(cached);
    } catch (e) {
      debugPrint('Error loading cached data: $e');
      return null;
    }
  }

  Future<void> saveCachedPrayer(PrayerData data) async {
    try {
      final prefs = await _prefsFuture;
      await prefs.setString(_cacheKey, data.toJsonString());
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
  }

  // --- User Session (Secure Storage) ---

  Future<UserSession?> loadSession() async {
    try {
      final sessionData = await _secureStorage.read(key: _sessionKey);
      if (sessionData == null) return null;
      return UserSession.fromJsonString(sessionData);
    } catch (e) {
      debugPrint('Error loading session: $e');
      return null;
    }
  }

  Future<void> saveSession(UserSession session) async {
    try {
      await _secureStorage.write(
        key: _sessionKey,
        value: session.toJsonString(),
      );
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
}
