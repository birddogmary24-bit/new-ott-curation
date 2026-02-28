import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/config/theme/app_theme.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정 (모바일 앱)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 상태바 스타일
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase 초기화
  // google-services.json (Android) / GoogleService-Info.plist (iOS) 필요
  await Firebase.initializeApp();

  // 카카오 SDK 초기화
  // 카카오 개발자 콘솔에서 발급한 Native App Key 입력
  // https://developers.kakao.com
  KakaoSdk.init(
    nativeAppKey: const String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: 'your_kakao_native_app_key',
    ),
  );

  runApp(
    const ProviderScope(
      child: OttCurationApp(),
    ),
  );
}

class OttCurationApp extends ConsumerWidget {
  const OttCurationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'OTT 큐레이션',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // 한국어 로컬라이제이션
      localizationsDelegates: const [
        // AppLocalizations.delegate,
        // GlobalMaterialLocalizations.delegate,
        // GlobalWidgetsLocalizations.delegate,
        // GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      routerConfig: appRouter,
    );
  }
}
