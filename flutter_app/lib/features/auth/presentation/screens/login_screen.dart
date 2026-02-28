import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // 인증 완료 시 홈으로 이동
    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        final user = next.value!;
        if (user.onboardingCompleted) {
          context.go(Routes.home);
        } else {
          context.go(Routes.onboardingGenre);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 로고
              const Icon(Icons.play_circle_outline, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'OTT 큐레이션',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI가 당신의 취향에 맞는 콘텐츠를 골라드려요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),

              // 오류 메시지
              if (authState.hasError)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '로그인에 실패했습니다. 다시 시도해주세요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // 카카오 로그인 (메인)
              _LoginButton(
                onTap: authState.isLoading
                    ? null
                    : () => ref.read(authNotifierProvider.notifier).signInWithKakao(),
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF191919),
                icon: const Text('K', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF191919))),
                label: '카카오로 계속하기',
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 12),

              // Apple 로그인
              _LoginButton(
                onTap: authState.isLoading
                    ? null
                    : () => ref.read(authNotifierProvider.notifier).signInWithApple(),
                backgroundColor: Colors.black,
                textColor: Colors.white,
                icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                label: 'Apple로 계속하기',
                isLoading: false,
              ),
              const SizedBox(height: 12),

              // Google 로그인
              _LoginButton(
                onTap: authState.isLoading
                    ? null
                    : () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                icon: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                label: 'Google로 계속하기',
                isLoading: false,
              ),

              const Spacer(),
              Text(
                '로그인 시 이용약관 및 개인정보처리방침에 동의하는 것으로 간주됩니다.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final String label;
  final bool isLoading;

  const _LoginButton({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
