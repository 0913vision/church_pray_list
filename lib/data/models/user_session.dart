import 'dart:convert';

class KakaoUser {
  final String id;
  final String? nickname;
  final String? email;

  const KakaoUser({required this.id, this.nickname, this.email});

  factory KakaoUser.fromJson(Map<String, dynamic> json) {
    return KakaoUser(
      id: json['id'].toString(),
      nickname: json['nickname'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (nickname != null) 'nickname': nickname,
        if (email != null) 'email': email,
      };
}

class UserSession {
  final KakaoUser kakaoUser;
  final bool isAuthor;
  final bool isAllowedUser;
  final int loginTimestamp;

  const UserSession({
    required this.kakaoUser,
    required this.isAuthor,
    required this.isAllowedUser,
    required this.loginTimestamp,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      kakaoUser:
          KakaoUser.fromJson(json['kakaoUser'] as Map<String, dynamic>),
      isAuthor: json['isAuthor'] as bool? ?? false,
      isAllowedUser: json['isAllowedUser'] as bool? ?? false,
      loginTimestamp: json['loginTimestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'kakaoUser': kakaoUser.toJson(),
        'isAuthor': isAuthor,
        'isAllowedUser': isAllowedUser,
        'loginTimestamp': loginTimestamp,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserSession.fromJsonString(String jsonString) {
    return UserSession.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
