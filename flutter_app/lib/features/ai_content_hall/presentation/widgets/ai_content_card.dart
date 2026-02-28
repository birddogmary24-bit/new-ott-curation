import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../domain/entities/ai_content.dart';

/// TikTok 스타일의 AI 콘텐츠 카드
/// PageView의 각 페이지로 사용됨
class AiContentCard extends StatefulWidget {
  final AiContent content;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const AiContentCard({
    super.key,
    required this.content,
    required this.isActive,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<AiContentCard> createState() => _AiContentCardState();
}

class _AiContentCardState extends State<AiContentCard> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initVideo();
  }

  @override
  void didUpdateWidget(AiContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      _videoController?.pause();
    }
  }

  Future<void> _initVideo() async {
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.content.videoUrl),
    );
    _videoController = controller;

    await controller.initialize();
    if (!mounted) return;

    setState(() {
      _isInitialized = true;
      _isPlaying = true;
    });

    controller.setLooping(true);
    controller.play();
  }

  void _togglePlay() {
    if (_videoController == null) return;
    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 비디오 또는 썸네일
          _buildVideoLayer(),

          // 그라데이션 오버레이
          _buildGradientOverlay(),

          // 일시정지 아이콘
          if (!_isPlaying && _isInitialized)
            const Center(
              child: Icon(Icons.play_arrow_rounded, size: 72, color: Colors.white54),
            ),

          // 우측 액션 버튼들
          Positioned(
            right: 12,
            bottom: 100,
            child: _ActionButtons(
              content: widget.content,
              onLike: widget.onLike,
              onComment: widget.onComment,
            ),
          ),

          // 하단 콘텐츠 정보
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: _ContentInfo(content: widget.content),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_isInitialized && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    // 썸네일 폴백
    if (widget.content.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.content.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceDark),
        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceDark),
      );
    }
    return Container(
      color: AppColors.surfaceDark,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 우측 액션 버튼 컬럼
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ActionButtons extends StatelessWidget {
  final AiContent content;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _ActionButtons({
    required this.content,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: content.isLikedByMe ? Icons.favorite : Icons.favorite_border,
          color: content.isLikedByMe ? AppColors.accent : Colors.white,
          count: content.likeCount,
          onTap: onLike,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          color: Colors.white,
          count: content.commentCount,
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.share_rounded,
          color: Colors.white,
          count: null,
          onTap: () => SharePlus.instance.share(
            ShareParams(text: '${content.title ?? 'AI 콘텐츠'} - OTT 큐레이션 앱에서 확인해보세요!'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (count != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatCount(count!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 하단 콘텐츠 정보
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ContentInfo extends StatelessWidget {
  final AiContent content;

  const _ContentInfo({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 작성자
        if (content.authorNickname != null)
          Text(
            '@${content.authorNickname}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),

        const SizedBox(height: 4),

        // 제목
        if (content.title != null)
          Text(
            content.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 6),

        // 태그
        if (content.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            children: content.tags.take(3).map((tag) {
              return Text(
                '#$tag',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 6),

        // AI 도구 + 콘텐츠 타입 + 재생 시간
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                content.contentType.displayName,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            if (content.aiToolUsed != null) ...[
              const SizedBox(width: 6),
              Text(
                content.aiToolUsed!,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
            const Spacer(),
            Text(
              content.formattedDuration,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
