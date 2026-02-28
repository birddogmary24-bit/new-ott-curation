import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/widgets/content_card.dart';
import '../../../../routing/app_router.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// 검색 디바운스 300ms
final _debouncedSearchProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(_debouncedSearchProvider.notifier).state = query.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_debouncedSearchProvider);
    final results = ref.watch(searchResultsProvider(query));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: _SearchBar(
          controller: _controller,
          onChanged: _onSearchChanged,
          onClear: () {
            _controller.clear();
            ref.read(_debouncedSearchProvider.notifier).state = '';
          },
        ),
      ),
      body: query.isEmpty
          ? _EmptySearch()
          : results.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Center(
                child: Text('검색 중 오류가 발생했어요',
                    style: TextStyle(color: Colors.white70)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.white38),
                        const SizedBox(height: 12),
                        Text('"$query" 검색 결과가 없어요',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.52,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ContentCard(
                      content: item,
                      width: double.infinity,
                      height: 160,
                      onTap: () => context.push(Routes.contentDetail(item.id)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: true,
      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: '영화, 드라마, 배우 검색...',
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondaryDark, size: 18),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('영화나 드라마를 검색해보세요',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
        ],
      ),
    );
  }
}
