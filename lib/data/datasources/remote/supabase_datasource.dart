import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/prayer_data.dart';
import '../../models/user_session.dart';

class SupabaseDatasource {
  SupabaseDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch the latest prayer from the prayers table (10s timeout)
  Future<PrayerRecord?> fetchLatestPrayer() async {
    final response = await _client
        .from('prayers')
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .single()
        .timeout(const Duration(seconds: 10));

    return PrayerRecord.fromJson(response);
  }

  /// Upload a new prayer to the prayers table
  Future<void> uploadPrayer(PrayerData data) async {
    await _client.from('prayers').insert({
      'title': data.title,
      'content': {
        'sections': data.sections.map((s) => s.toJson()).toList(),
        'verse': data.verse?.toJson(),
      },
    });
  }

  /// Check if a user is in the allowed_users table
  Future<({bool isAllowed, bool isAuthor})> checkUserPermission(
      String kakaoId) async {
    try {
      final data = await _client
          .from('allowed_users')
          .select('is_author')
          .eq('kakao_id', kakaoId)
          .single();

      return (
        isAllowed: true,
        isAuthor: data['is_author'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('checkUserPermission error: $e');
      return (isAllowed: false, isAuthor: false);
    }
  }

  /// Record a denied user (only if not already recorded)
  Future<void> recordDeniedUser(KakaoUser user) async {
    try {
      final existing = await _client
          .from('denied_users')
          .select('kakao_id')
          .eq('kakao_id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _client.from('denied_users').insert({
          'kakao_id': user.id,
          'nickname': user.nickname,
          'email': user.email,
        });
      }
    } catch (e) {
      // Silently ignore errors (already exists or network error)
    }
  }

  /// Fetch app config for the given platform
  Future<({String minVersion, int minVersionCode})?> fetchAppConfig(
      String platform) async {
    try {
      final data = await _client
          .from('app_config')
          .select('min_version, min_version_code')
          .eq('platform', platform)
          .single();

      return (
        minVersion: data['min_version'] as String? ?? '1.0.0',
        minVersionCode: data['min_version_code'] as int? ?? 1,
      );
    } catch (e) {
      debugPrint('Error fetching app config: $e');
      return null;
    }
  }
}
