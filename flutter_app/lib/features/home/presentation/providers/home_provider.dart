import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/content_remote_datasource.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/entities/content.dart';
import '../../domain/entities/curation_section.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Infrastructure Providers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final contentDataSourceProvider = Provider<ContentRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ContentRemoteDataSource(dio);
});

final contentRepositoryProvider = Provider<ContentRepositoryImpl>((ref) {
  final dataSource = ref.watch(contentDataSourceProvider);
  return ContentRepositoryImpl(dataSource);
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Home Sections
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final homeSectionsProvider = AsyncNotifierProvider<HomeSectionsNotifier, List<CurationSection>>(
  HomeSectionsNotifier.new,
);

class HomeSectionsNotifier extends AsyncNotifier<List<CurationSection>> {
  @override
  Future<List<CurationSection>> build() async {
    return _fetchSections();
  }

  Future<List<CurationSection>> _fetchSections() {
    final repo = ref.read(contentRepositoryProvider);
    return repo.getHomeSections();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSections);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OTT Filter (홈 화면 플랫폼 필터)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final selectedPlatformProvider = StateProvider<String?>((ref) => null);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Content List (검색/탐색용)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ContentListState {
  final List<Content> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ContentListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ContentListState copyWith({
    List<Content>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ContentListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

final contentListProvider =
    StateNotifierProvider<ContentListNotifier, ContentListState>(
  (ref) => ContentListNotifier(ref),
);

class ContentListNotifier extends StateNotifier<ContentListState> {
  final Ref _ref;

  ContentListNotifier(this._ref) : super(const ContentListState()) {
    loadInitial();
  }

  Future<void> loadInitial({String? platformId, String? genre, String sort = 'rating'}) async {
    state = state.copyWith(isLoading: true, items: [], currentPage: 1, hasMore: true);
    try {
      final repo = _ref.read(contentRepositoryProvider);
      final result = await repo.getContents(
        platformId: platformId,
        genre: genre,
        sort: sort,
        page: 1,
      );
      state = state.copyWith(
        items: result.items,
        hasMore: result.hasMore,
        currentPage: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? platformId, String? genre, String sort = 'rating'}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final repo = _ref.read(contentRepositoryProvider);
      final result = await repo.getContents(
        platformId: platformId,
        genre: genre,
        sort: sort,
        page: nextPage,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        hasMore: result.hasMore,
        currentPage: nextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Search
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<List<Content>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final repo = ref.read(contentRepositoryProvider);
    return repo.searchContents(query: query);
  },
);
