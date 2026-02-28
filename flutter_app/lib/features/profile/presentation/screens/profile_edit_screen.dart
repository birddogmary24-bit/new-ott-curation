import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/constants/ott_platforms.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/domain/constants/genre_constants.dart';
import '../providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  Set<String> _selectedGenres = {};
  Set<String> _selectedPlatforms = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _bioController.text = user.bio ?? '';
      _selectedGenres = Set.from(user.preferredGenres);
      _selectedPlatforms = Set.from(user.preferredPlatforms);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 20) return;

    setState(() => _isSaving = true);
    try {
      final ds = ref.read(profileDataSourceProvider);
      await ds.updateProfile(
        nickname: nickname,
        bio: _bioController.text.trim(),
        preferredGenres: _selectedGenres.toList(),
        preferredPlatforms: _selectedPlatforms.toList(),
      );
      // authNotifier 갱신을 위해 재로드
      ref.invalidate(authNotifierProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했어요'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('프로필 편집',
            style: TextStyle(color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700)),
        leading: const BackButton(color: AppColors.textPrimaryDark),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('저장', style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임
            const _Label('닉네임'),
            TextField(
              controller: _nicknameController,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              maxLength: 20,
              decoration: _inputDecoration('2~20자'),
            ),
            const SizedBox(height: 16),

            // 바이오
            const _Label('소개'),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              maxLength: 200,
              maxLines: 3,
              decoration: _inputDecoration('자기소개를 입력해주세요'),
            ),
            const SizedBox(height: 20),

            // 선호 장르
            const _Label('선호 장르'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: GenreConstants.all.map((g) {
                final selected = _selectedGenres.contains(g.id);
                return ChoiceChip(
                  label: Text('${g.emoji} ${g.nameKo}'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedGenres.remove(g.id);
                    } else {
                      _selectedGenres.add(g.id);
                    }
                  }),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 구독 OTT
            const _Label('구독 OTT'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: OttPlatform.all.map((p) {
                final selected = _selectedPlatforms.contains(p.id);
                return ChoiceChip(
                  label: Text(p.nameKo),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedPlatforms.remove(p.id);
                    } else {
                      _selectedPlatforms.add(p.id);
                    }
                  }),
                  selectedColor: p.color,
                  backgroundColor: AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
