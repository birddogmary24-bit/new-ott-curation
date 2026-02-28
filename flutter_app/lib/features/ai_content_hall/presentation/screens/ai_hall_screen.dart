import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../routing/app_router.dart';
import '../providers/ai_hall_provider.dart';
import '../widgets/ai_content_card.dart';

class AiHallScreen extends ConsumerStatefulWidget {
  const AiHallScreen({super.key});

  @override
  ConsumerState<AiHallScreen> createState() => _AiHallScreenState();
}

class _AiHallScreenState extends ConsumerState<AiHallScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(aiHallFeedProvider);
    final currentIndex = ref.watch(currentPlayingIndexProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI 콘텐츠 관',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            onPressed: () => context.push(Routes.aiHallUpload),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(feedState, currentIndex),
    );
  }

  Widget _buildBody(AiHallFeedState feedState, int currentIndex) {
    if (feedState.isLoading && feedState.items.isEmpty) {
      return const _LoadingFeed();
    }

    if (feedState.error != null && feedState.items.isEmpty) {
      return _ErrorFeed(onRetry: () => ref.read(aiHallFeedProvider.notifier).loadInitial());
    }

    if (feedState.items.isEmpty) {
      return const _EmptyFeed();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 끝에 가까워지면 더 로드
        if (notification is ScrollEndNotification) {
          if (_pageController.position.pixels >=
              _pageController.position.maxScrollExtent * 0.8) {
            ref.read(aiHallFeedProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: feedState.items.length + (feedState.hasMore ? 1 : 0),
        onPageChanged: (index) {
          ref.read(currentPlayingIndexProvider.notifier).state = index;
        },
        itemBuilder: (context, index) {
          // 로딩 인디케이터
          if (index >= feedState.items.length) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final content = feedState.items[index];
          return AiContentCard(
            content: content,
            isActive: index == currentIndex,
            onLike: () => ref.read(aiHallFeedProvider.notifier).toggleLike(content.id),
            onComment: () => _showComments(context, content.id),
          );
        },
      ),
    );
  }

  void _showComments(BuildContext context, String contentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _CommentsSheet(
          contentId: contentId,
          scrollController: controller,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 댓글 시트 (간이 구현)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _CommentsSheet extends StatelessWidget {
  final String contentId;
  final ScrollController scrollController;

  const _CommentsSheet({required this.contentId, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSecondaryDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Text(
          '댓글',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Divider(color: AppColors.dividerDark),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('아직 댓글이 없어요. 첫 번째 댓글을 남겨보세요!',
                    style: TextStyle(color: AppColors.textSecondaryDark)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 로딩 / 에러 / 빈 상태
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('AI 콘텐츠 불러오는 중...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorFeed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          const Text('콘텐츠를 불러오지 못했어요', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text('아직 AI 콘텐츠가 없어요', style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 8),
          Text('첫 번째 AI 콘텐츠를 올려보세요!', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
