import '../../domain/entities/content.dart';
import '../../domain/entities/curation_section.dart';
import '../datasources/content_remote_datasource.dart';
import 'content_repository.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource _remoteDataSource;

  const ContentRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CurationSection>> getHomeSections() {
    return _remoteDataSource.getHomeSections();
  }

  @override
  Future<({List<Content> items, bool hasMore})> getContents({
    String? platformId,
    String? genre,
    String? contentType,
    String sort = 'rating',
    int page = 1,
  }) async {
    final result = await _remoteDataSource.getContents(
      platformId: platformId,
      genre: genre,
      contentType: contentType,
      sort: sort,
      page: page,
    );
    return (items: result.items, hasMore: result.hasMore);
  }

  @override
  Future<Content> getContentDetail(String contentId) {
    return _remoteDataSource.getContentDetail(contentId);
  }

  @override
  Future<List<Content>> searchContents({
    required String query,
    String? platformId,
    String? genre,
    String? contentType,
    int page = 1,
  }) {
    return _remoteDataSource.searchContents(
      query: query,
      platformId: platformId,
      genre: genre,
      contentType: contentType,
      page: page,
    );
  }
}
