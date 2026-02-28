import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/app_user.dart';
import '../../../../core/config/providers.dart';

part 'auth_provider.g.dart';

/// Firebase Auth 상태 스트림 프로바이더
@riverpod
Stream<User?> firebaseAuthState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

/// 현재 앱 사용자 상태 노티파이어
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<AppUser?> build() {
    // Firebase 인증 상태 변화 감지
    ref.listen(firebaseAuthStateProvider, (_, next) async {
      if (next.hasValue) {
        if (next.value != null) {
          await _loadUserProfile();
        } else {
          state = const AsyncData(null);
        }
      }
    });
    return const AsyncData(null);
  }

  Dio get _dio => ref.read(apiClientProvider);

  /// 사용자 프로필 로드 (DB에서)
  Future<void> _loadUserProfile() async {
    state = const AsyncLoading();
    try {
      final response = await _dio.get('/api/users/profile');
      state = AsyncData(AppUser.fromJson(response.data['data'] as Map<String, dynamic>));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 카카오 로그인
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> signInWithKakao() async {
    state = const AsyncLoading();
    try {
      // 카카오 SDK 로그인
      if (await kakao.isKakaoTalkInstalled()) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 액세스 토큰 가져오기
      final token = await kakao.TokenManagerProvider.instance.manager.getToken();
      if (token?.accessToken == null) throw Exception('카카오 토큰 없음');

      // Cloud Run API에서 Firebase 커스텀 토큰 발급
      final response = await _dio.post('/api/users/auth/kakao', data: {
        'kakao_access_token': token!.accessToken,
      });

      final customToken = response.data['custom_token'] as String;

      // Firebase 로그인
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      await _loadUserProfile();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Apple 로그인
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken:     appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      await _loadUserProfile();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Google 로그인
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = const AsyncData(null);
        return;  // 사용자가 취소
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _loadUserProfile();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 로그아웃
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await kakao.UserApi.instance.logout().catchError((_) {});
    await FirebaseAuth.instance.signOut();
    state = const AsyncData(null);
  }

  /// 온보딩 완료 처리
  Future<void> completeOnboarding({
    required List<String> genres,
    required List<String> platforms,
    required List<Map<String, dynamic>> ratings,
  }) async {
    try {
      await _dio.post('/api/users/onboarding', data: {
        'preferred_genres':    genres,
        'preferred_platforms': platforms,
        'initial_ratings':     ratings,
      });
      await _loadUserProfile();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
