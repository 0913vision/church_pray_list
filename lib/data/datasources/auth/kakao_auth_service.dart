import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import '../../models/user_session.dart';

class KakaoAuthService {
  /// Sign in with Kakao and return the user profile
  Future<KakaoUser> signIn() async {
    // Try KakaoTalk first, fall back to web login
    final bool isTalkInstalled = await kakao.isKakaoTalkInstalled();

    if (isTalkInstalled) {
      await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    final profile = await kakao.UserApi.instance.me();

    return KakaoUser(
      id: profile.id.toString(),
      nickname: profile.kakaoAccount?.profile?.nickname,
      email: profile.kakaoAccount?.email,
    );
  }

  /// Sign out from Kakao
  Future<void> signOut() async {
    try {
      await kakao.UserApi.instance.logout();
    } catch (e) {
      debugPrint('Kakao logout error: $e');
    }
  }
}
