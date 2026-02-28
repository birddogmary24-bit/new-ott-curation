import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/constants/ott_platforms.dart';
import '../../../home/domain/entities/content.dart';

class OttAvailabilitySection extends StatelessWidget {
  final List<OttAvailability> availability;

  const OttAvailabilitySection({super.key, required this.availability});

  @override
  Widget build(BuildContext context) {
    if (availability.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '현재 이용 가능한 OTT가 없어요',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
      );
    }

    // flatrate, rent, buy 순으로 그룹핑
    final flatrate = availability.where((a) => a.isFlatrate).toList();
    final rent = availability.where((a) => a.type == 'rent').toList();
    final buy = availability.where((a) => a.type == 'buy').toList();
    final free = availability.where((a) => a.isFree).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('어디서 볼 수 있나요?',
            style: TextStyle(color: AppColors.textPrimaryDark,
                fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (flatrate.isNotEmpty) ...[
          _GroupLabel('구독'),
          _AvailabilityList(items: flatrate),
        ],
        if (free.isNotEmpty) ...[
          _GroupLabel('무료'),
          _AvailabilityList(items: free),
        ],
        if (rent.isNotEmpty) ...[
          _GroupLabel('대여'),
          _AvailabilityList(items: rent),
        ],
        if (buy.isNotEmpty) ...[
          _GroupLabel('구매'),
          _AvailabilityList(items: buy),
        ],
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(text, style: const TextStyle(
          color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  final List<OttAvailability> items;
  const _AvailabilityList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _AvailabilityChip(item: item)).toList(),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  final OttAvailability item;
  const _AvailabilityChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final platform = item.platform;
    final color = platform?.color ?? AppColors.primary;

    return GestureDetector(
      onTap: () async {
        if (item.deepLinkUrl != null) {
          final uri = Uri.parse(item.deepLinkUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  platform?.nameKo.substring(0, 1) ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              platform?.nameKo ?? item.platformId,
              style: const TextStyle(color: AppColors.textPrimaryDark,
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (item.price != null) ...[
              const SizedBox(width: 6),
              Text(
                '₩${item.price!.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
              ),
            ],
            if (item.deepLinkUrl != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 12, color: AppColors.textSecondaryDark),
            ],
          ],
        ),
      ),
    );
  }
}
