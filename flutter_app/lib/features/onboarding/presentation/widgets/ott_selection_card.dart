import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/constants/ott_platforms.dart';

class OttSelectionCard extends StatelessWidget {
  final OttPlatform platform;
  final bool isSelected;
  final VoidCallback onTap;

  const OttSelectionCard({
    super.key,
    required this.platform,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? platform.color.withValues(alpha: 0.15)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? platform.color : AppColors.dividerDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 플랫폼 컬러 도트
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: platform.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _shortName(platform.id),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                platform.nameKo,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
          ],
        ),
      ),
    );
  }

  String _shortName(String id) => switch (id) {
    'netflix'      => 'N',
    'tving'        => 'T',
    'coupang_play' => 'C',
    'wavve'        => 'W',
    'watcha'       => 'WC',
    _              => id.substring(0, 1).toUpperCase(),
  };
}
