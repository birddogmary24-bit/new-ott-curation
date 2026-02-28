import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit;

  const ProfileHeader({super.key, required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surface2Dark,
            backgroundImage: user.avatarUrl != null
                ? CachedNetworkImageProvider(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.nickname.isNotEmpty ? user.nickname[0] : '?',
                    style: const TextStyle(
                        color: AppColors.textSecondaryDark, fontSize: 28),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nickname, style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 20, fontWeight: FontWeight.w700)),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.bio!, style: const TextStyle(
                      color: AppColors.textSecondaryDark, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.textSecondaryDark, size: 20),
          ),
        ],
      ),
    );
  }
}
