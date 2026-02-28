import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../domain/entities/taste_profile.dart';

final profileDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ProfileRemoteDataSource(dio);
});

/// 취향 프로필
final tasteProfileProvider = FutureProvider<TasteProfile>((ref) async {
  final ds = ref.read(profileDataSourceProvider);
  return ds.getTasteProfile();
});

/// 내 평점 목록
class MyRatingsState {
  final List<UserRatingItem> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;

  const MyRatingsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  MyRatingsState copyWith({
    List<UserRatingItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
  }) {
    return MyRatingsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class UserRatingItem {
  final String contentId;
  final String titleKo;
  final String? posterUrl;
  final String contentType;
  final double rating;
  final double? ourAvgRating;
  final DateTime createdAt;

  const UserRatingItem({
    required this.contentId,
    required this.titleKo,
    this.posterUrl,
    required this.contentType,
    required this.rating,
    this.ourAvgRating,
    required this.createdAt,
  });

  factory UserRatingItem.fromJson(Map<String, dynamic> json) {
    return UserRatingItem(
      contentId:   json['content_id'] as String,
      titleKo:     json['title_ko'] as String? ?? '',
      posterUrl:   json['poster_url'] as String?,
      contentType: json['content_type'] as String? ?? 'movie',
      rating:      (json['rating'] as num).toDouble(),
      ourAvgRating: (json['our_avg_rating'] as num?)?.toDouble(),
      createdAt:   DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

final myRatingsProvider =
    StateNotifierProvider<MyRatingsNotifier, MyRatingsState>(
  (ref) => MyRatingsNotifier(ref),
);

class MyRatingsNotifier extends StateNotifier<MyRatingsState> {
  final Ref _ref;

  MyRatingsNotifier(this._ref) : super(const MyRatingsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, items: [], currentPage: 1, hasMore: true);
    try {
      final ds = _ref.read(profileDataSourceProvider);
      final result = await ds.getMyRatings(page: 1);
      final items = result.items.map(UserRatingItem.fromJson).toList();
      state = state.copyWith(
        items: items,
        hasMore: result.hasMore,
        currentPage: 1,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final ds = _ref.read(profileDataSourceProvider);
      final result = await ds.getMyRatings(page: nextPage);
      final items = result.items.map(UserRatingItem.fromJson).toList();
      state = state.copyWith(
        items: [...state.items, ...items],
        hasMore: result.hasMore,
        currentPage: nextPage,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
