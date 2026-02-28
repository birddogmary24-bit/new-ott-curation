import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 실제 화면 imports
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/curation/presentation/screens/curation_chat_screen.dart';
import '../features/ai_content_hall/presentation/screens/ai_hall_screen.dart';
import '../features/ai_content_hall/presentation/screens/ai_hall_upload_screen.dart';

/// 라우트 경로 상수
class Routes {
  Routes._();
  static const String splash          = '/';
  static const String login           = '/login';
  static const String onboardingGenre = '/onboarding/genre';
  static const String onboardingOtt   = '/onboarding/ott';
  static const String onboardingRate  = '/onboarding/rate';
  static const String home            = '/home';
  static const String search          = '/search';
  static const String aiHall          = '/ai-hall';
  static const String aiHallUpload    = '/ai-hall/upload';
  static const String curationChat    = '/curation/chat';
  static const String community       = '/community';
  static const String profile         = '/profile';
  static const String editProfile     = '/profile/edit';
  static const String myRatings       = '/profile/ratings';
  static const String myCollections   = '/profile/collections';
  static const String settings        = '/settings';

  // 동적 경로 헬퍼
  static String contentDetail(String id)    => '/content/$id';
  static String aiHallDetail(String id)     => '/ai-hall/$id';
  static String collectionDetail(String id) => '/collection/$id';
}

/// GoRouter 설정
final appRouter = GoRouter(
  initialLocation: Routes.splash,
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == Routes.login || loc.startsWith('/onboarding') || loc == Routes.splash;

    if (user == null && !isAuthRoute) {
      return Routes.login;
    }
    return null;
  },
  refreshListenable: _FirebaseAuthNotifier(),
  routes: [
    // ── Splash ──
    GoRoute(
      path: Routes.splash,
      builder: (_, __) => const _SplashScreen(),
    ),

    // ── Auth ──
    GoRoute(
      path: Routes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.onboardingGenre,
      builder: (_, __) => const _PlaceholderScreen('온보딩: 장르 선택'),
    ),
    GoRoute(
      path: Routes.onboardingOtt,
      builder: (_, __) => const _PlaceholderScreen('온보딩: OTT 선택'),
    ),
    GoRoute(
      path: Routes.onboardingRate,
      builder: (_, __) => const _PlaceholderScreen('온보딩: 초기 평점'),
    ),

    // ── 메인 앱 (하단 탭 Shell) ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _MainShell(navigationShell: navigationShell);
      },
      branches: [
        // 탭 1: 홈
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, __) => const HomeScreen(),
          ),
        ]),
        // 탭 2: 검색
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.search,
            builder: (_, __) => const _PlaceholderScreen('검색'),
          ),
        ]),
        // 탭 3: AI 콘텐츠 관
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.aiHall,
            builder: (_, __) => const AiHallScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (_, __) => const AiHallUploadScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    _PlaceholderScreen('AI 콘텐츠: ${state.pathParameters['id']}'),
              ),
            ],
          ),
        ]),
        // 탭 4: 커뮤니티
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.community,
            builder: (_, __) => const _PlaceholderScreen('커뮤니티'),
          ),
        ]),
        // 탭 5: 프로필
        StatefulShellBranch(routes: [
          GoRoute(
            path: Routes.profile,
            builder: (_, __) => const _PlaceholderScreen('프로필'),
            routes: [
              GoRoute(path: 'edit',        builder: (_, __) => const _PlaceholderScreen('프로필 편집')),
              GoRoute(path: 'ratings',     builder: (_, __) => const _PlaceholderScreen('내 평점')),
              GoRoute(path: 'collections', builder: (_, __) => const _PlaceholderScreen('내 컬렉션')),
            ],
          ),
        ]),
      ],
    ),

    // ── Shell 밖 라우트 ──
    GoRoute(
      path: '/content/:id',
      builder: (_, state) =>
          _PlaceholderScreen('콘텐츠 상세: ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: '/collection/:id',
      builder: (_, state) =>
          _PlaceholderScreen('컬렉션: ${state.pathParameters['id']}'),
    ),
    GoRoute(
      path: Routes.curationChat,
      builder: (_, __) => const CurationChatScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (_, __) => const _PlaceholderScreen('설정'),
    ),
  ],
);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Firebase Auth 변경 감지
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _FirebaseAuthNotifier extends ChangeNotifier {
  _FirebaseAuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Splash 화면
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text(
              'OTT 큐레이션',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 플레이스홀더 (아직 미구현 화면)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined, size: 48, color: Color(0xFF6C63FF)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('구현 예정', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 메인 Shell (하단 네비게이션 바)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),     activeIcon: Icon(Icons.home),            label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined),   activeIcon: Icon(Icons.search),          label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'AI관'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline),    activeIcon: Icon(Icons.people),          label: '커뮤니티'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),    activeIcon: Icon(Icons.person),          label: '프로필'),
        ],
      ),
    );
  }
}
