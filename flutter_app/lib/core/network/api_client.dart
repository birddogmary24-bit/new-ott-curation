import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Dio 인스턴스 프로바이더 (앱 전역)
final apiClientProvider = Provider<Dio>((ref) => createApiClient());

/// Cloud Run API 클라이언트
/// Firebase Auth 토큰을 자동으로 Authorization 헤더에 추가
Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl:        AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ),
  );

  // Firebase Auth 토큰 자동 주입
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          } catch (_) {
            // 토큰 갱신 실패 시 그냥 진행 (공개 API)
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 401: 토큰 만료 → Firebase Auth가 자동 갱신 처리
        return handler.next(error);
      },
    ),
  );

  // 개발 환경에서 요청/응답 로깅
  assert(() {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false,  // 응답 바디는 너무 길어서 비활성화
      logPrint: (obj) => print('[API] $obj'),
    ));
    return true;
  }());

  return dio;
}
