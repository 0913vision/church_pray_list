import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/user_session.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
  final KakaoUser? user;
  final bool loading;
  final bool isAuthor;
  final bool? isAllowedUser; // null = not checked yet
  final String? error;

  const AuthState({
    this.user,
    this.loading = true,
    this.isAuthor = false,
    this.isAllowedUser,
    this.error,
  });

  AuthState copyWith({
    KakaoUser? user,
    bool? loading,
    bool? isAuthor,
    bool? isAllowedUser,
    String? error,
    bool clearUser = false,
    bool clearError = false,
    bool clearAllowedUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      isAuthor: isAuthor ?? this.isAuthor,
      isAllowedUser:
          clearAllowedUser ? null : (isAllowedUser ?? this.isAllowedUser),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const AuthState()) {
    _initializeAuth();
  }

  final AuthRepository _repository;

  Future<void> _initializeAuth() async {
    try {
      state = state.copyWith(loading: true);

      final session = await _repository.restoreSession();

      if (session != null) {
        state = AuthState(
          user: session.kakaoUser,
          loading: false,
          isAuthor: session.isAuthor,
          isAllowedUser: session.isAllowedUser,
        );
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> signInWithKakao() async {
    try {
      state = state.copyWith(loading: true, clearError: true);

      final session = await _repository.signInWithKakao();

      state = AuthState(
        user: session.kakaoUser,
        loading: false,
        isAuthor: session.isAuthor,
        isAllowedUser: session.isAllowedUser,
      );

      return null; // no error
    } catch (e) {
      state = state.copyWith(loading: false);

      final errorMessage = e.toString();
      if (errorMessage.contains('user cancelled') ||
          errorMessage.contains('CANCELED')) {
        return null; // user cancelled, not a real error
      }
      return errorMessage;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(
      loading: false,
    );
  }
}
