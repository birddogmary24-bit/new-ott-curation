import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('설정',
            style: TextStyle(color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppColors.textPrimaryDark),
      ),
      body: ListView(
        children: [
          // 알림
          _SectionHeader('알림'),
          const _NotificationToggle(),
          const Divider(color: AppColors.dividerDark, height: 1),

          // 테마
          _SectionHeader('테마'),
          const ListTile(
            leading: Icon(Icons.dark_mode, color: AppColors.textSecondaryDark),
            title: Text('다크 모드', style: TextStyle(color: AppColors.textPrimaryDark)),
            trailing: Text('항상 사용', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          ),
          const Divider(color: AppColors.dividerDark, height: 1),

          // 정보
          _SectionHeader('정보'),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AppColors.textSecondaryDark),
            title: const Text('이용약관', style: TextStyle(color: AppColors.textPrimaryDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
            onTap: () => _openUrl('https://example.com/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondaryDark),
            title: const Text('개인정보처리방침', style: TextStyle(color: AppColors.textPrimaryDark)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
            onTap: () => _openUrl('https://example.com/privacy'),
          ),
          const _AppVersionTile(),
          const Divider(color: AppColors.dividerDark, height: 1),

          // 로그아웃
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    title: const Text('로그아웃', style: TextStyle(color: AppColors.textPrimaryDark)),
                    content: const Text('정말 로그아웃하시겠어요?',
                        style: TextStyle(color: AppColors.textSecondaryDark)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go(Routes.login);
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('로그아웃',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(text, style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  const _NotificationToggle();

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined, color: AppColors.textSecondaryDark),
      title: const Text('푸시 알림', style: TextStyle(color: AppColors.textPrimaryDark)),
      value: _enabled,
      activeColor: AppColors.primary,
      onChanged: (v) => setState(() => _enabled = v),
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snapshot) {
        final version = snapshot.data?.version ?? '-';
        final buildNumber = snapshot.data?.buildNumber ?? '';
        return ListTile(
          leading: const Icon(Icons.info_outline, color: AppColors.textSecondaryDark),
          title: const Text('앱 버전', style: TextStyle(color: AppColors.textPrimaryDark)),
          trailing: Text('v$version ($buildNumber)',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        );
      },
    );
  }
}
