import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/ai_hall_remote_datasource.dart';
import '../../domain/entities/ai_content.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Infrastructure
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final aiHallDataSourceProvider = Provider<AiHallRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AiHallRemoteDataSource(dio);
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AI Hall 피드 상태
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AiHallFeedState {
  final List<AiContent> items;
  final bool isLoading;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  const AiHallFeedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.nextCursor,
    this.error,
  });

  AiHallFeedState copyWith({
    List<AiContent>? items,
    bool? isLoading,
    bool? hasMore,
    String? nextCursor,
    String? error,
  }) {
    return AiHallFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      error: error,
    );
  }
}

final aiHallFeedProvider =
    StateNotifierProvider<AiHallFeedNotifier, AiHallFeedState>(
  (ref) => AiHallFeedNotifier(ref),
);

class AiHallFeedNotifier extends StateNotifier<AiHallFeedState> {
  final Ref _ref;

  AiHallFeedNotifier(this._ref) : super(const AiHallFeedState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, items: [], nextCursor: null, hasMore: true);
    try {
      final ds = _ref.read(aiHallDataSourceProvider);
      final result = await ds.getFeed();
      state = state.copyWith(
        items: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = _ref.read(aiHallDataSourceProvider);
      final result = await ds.getFeed(cursor: state.nextCursor);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleLike(String contentId) async {
    // 즉시 낙관적 업데이트
    final currentItems = state.items.map((item) {
      if (item.id != contentId) return item;
      final newLiked = !item.isLikedByMe;
      return item.copyWith(
        isLikedByMe: newLiked,
        likeCount: item.likeCount + (newLiked ? 1 : -1),
      );
    }).toList();
    state = state.copyWith(items: currentItems);

    // 서버 동기화
    try {
      final ds = _ref.read(aiHallDataSourceProvider);
      final result = await ds.toggleLike(contentId);
      final updatedItems = state.items.map((item) {
        if (item.id != contentId) return item;
        return item.copyWith(
          isLikedByMe: result.isLiked,
          likeCount: result.likeCount,
        );
      }).toList();
      state = state.copyWith(items: updatedItems);
    } catch (_) {
      // 실패 시 롤백
      state = state.copyWith(items: currentItems.map((item) {
        if (item.id != contentId) return item;
        final rollback = !item.isLikedByMe;
        return item.copyWith(
          isLikedByMe: rollback,
          likeCount: item.likeCount + (rollback ? 1 : -1),
        );
      }).toList());
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 현재 재생 중인 항목 인덱스
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final currentPlayingIndexProvider = StateProvider<int>((ref) => 0);
