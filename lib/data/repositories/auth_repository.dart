import 'package:flutter/foundation.dart';
import '../datasources/auth/kakao_auth_service.dart';
import '../datasources/local/local_storage.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/user_session.dart';

class AuthRepository {
  AuthRepository({
    KakaoAuthService? kakaoAuthService,
    SupabaseDatasource? remoteDatasource,
    LocalStorage? localStorage,
  })  : _kakao = kakaoAuthService ?? KakaoAuthService(),
        _remote = remoteDatasource ?? SupabaseDatasource(),
        _local = localStorage ?? LocalStorage();

  final KakaoAuthService _kakao;
  final SupabaseDatasource _remote;
  final LocalStorage _local;

  /// Sign in with Kakao, check permission, save session
  Future<UserSession> signInWithKakao() async {
    final kakaoUser = await _kakao.signIn();
    return _processLogin(kakaoUser);
  }

  /// Restore session from secure storage, re-check permission
  Future<UserSession?> restoreSession() async {
    final session = await _local.loadSession();
    if (session == null) return null;

    debugPrint('=== Auto login ===');
    return _processLogin(session.kakaoUser);
  }

  /// Sign out: Kakao logout + clear session
  Future<void> signOut() async {
    try {
      await _kakao.signOut();
    } catch (e) {
      debugPrint('Kakao signout error: $e');
    }
    await _local.clearSession();
  }

  /// Common login processing: check permission + save session
  Future<UserSession> _processLogin(KakaoUser kakaoUser) async {
    debugPrint('Kakao ID: ${kakaoUser.id}');
    debugPrint('Nickname: ${kakaoUser.nickname}');
    debugPrint('Email: ${kakaoUser.email}');

    final permission = await _remote.checkUserPermission(kakaoUser.id);

    if (!permission.isAllowed) {
      await _remote.recordDeniedUser(kakaoUser);
    }

    debugPrint('Permission: ${permission.isAllowed}, Author: ${permission.isAuthor}');

    final session = UserSession(
      kakaoUser: kakaoUser,
      isAuthor: permission.isAuthor,
      isAllowedUser: permission.isAllowed,
      loginTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _local.saveSession(session);
    return session;
  }
}
