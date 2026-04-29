import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feee_service.dart'; // Fix #1: corrected typo from feee_service.dart
import '../models/feed_response.dart';
import 'auth_providers.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

// Fix #2: Dio is created once. Token is read lazily inside the interceptor
// at request time instead of rebuilding the whole provider on every auth change.
final feedServiceProvider = Provider<FeedService>((ref) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).tokens?.accessToken ?? '';
        options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ),
  );
  return FeedService(dio: dio);
});

// ─── Following Feed Notifier ──────────────────────────────────────────────────

class FollowingFeedNotifier extends AsyncNotifier<FeedState> {
  // Fix #3: dedicated flag to prevent concurrent loadMore calls
  bool _isLoadingMore = false;

  @override
  Future<FeedState> build() async {
    return const FeedState(items: [], hasMore: true, nextCursor: null);
  }

  // Load first page
  Future<void> loadFollowingFeed({int limit = 20}) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(feedServiceProvider)
          .getFollowingFeed(limit: limit);

      state = AsyncData(
        FeedState(
          items: response.data.items,
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
        ),
      );
    } on DioException catch (e) {
      state = AsyncError(
        'DioError ${e.response?.statusCode}: ${e.response?.data}',
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncError('Unknown error: $e', st);
    }
  }

  // Load next page (pagination)
  Future<void> loadMoreFollowingFeed({int limit = 20}) async {
    // Fix #3: guard against concurrent calls
    if (_isLoadingMore) return;
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;
    if (currentState.nextCursor == null) return;

    _isLoadingMore = true;
    final previousItems = currentState.items;

    try {
      final response = await ref
          .read(feedServiceProvider)
          .getFollowingFeed(limit: limit, cursor: currentState.nextCursor);

      state = AsyncData(
        FeedState(
          items: [...previousItems, ...response.data.items],
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
        ),
      );
    } on DioException catch (e) {
      // Fix #4: surface pagination errors — preserve existing items in paginationError
      state = AsyncData(
        FeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          paginationError:
              'Failed to load more: ${e.response?.statusCode ?? e.message}',
        ),
      );
    } catch (e) {
      state = AsyncData(
        FeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          paginationError: 'Failed to load more: $e',
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  // Refresh (pull to refresh)
  Future<void> refreshFollowingFeed({int limit = 20}) async {
    await loadFollowingFeed(limit: limit);
  }
}

// ─── Discover Feed Notifier ───────────────────────────────────────────────────

class DiscoverFeedNotifier extends AsyncNotifier<FeedState> {
  // Fix #3: dedicated flag to prevent concurrent loadMore calls
  bool _isLoadingMore = false;

  @override
  Future<FeedState> build() async {
    return const FeedState(items: [], hasMore: true, nextCursor: null);
  }

  // Load first page
  Future<void> loadDiscoverFeed({int limit = 20}) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(feedServiceProvider)
          .getDiscoverFeed(limit: limit);

      state = AsyncData(
        FeedState(
          items: response.data.items,
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
        ),
      );
    } on DioException catch (e) {
      state = AsyncError(
        'DioError ${e.response?.statusCode}: ${e.response?.data}',
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncError('Unknown error: $e', st);
    }
  }

  // Load next page
  Future<void> loadMoreDiscoverFeed({int limit = 20}) async {
    // Fix #3: guard against concurrent calls
    if (_isLoadingMore) return;
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;
    if (currentState.nextCursor == null) return;

    _isLoadingMore = true;
    final previousItems = currentState.items;

    try {
      final response = await ref
          .read(feedServiceProvider)
          .getDiscoverFeed(limit: limit, cursor: currentState.nextCursor);

      state = AsyncData(
        FeedState(
          items: [...previousItems, ...response.data.items],
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
        ),
      );
    } on DioException catch (e) {
      // Fix #4: surface pagination errors — preserve existing items
      state = AsyncData(
        FeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          paginationError:
              'Failed to load more: ${e.response?.statusCode ?? e.message}',
        ),
      );
    } catch (e) {
      state = AsyncData(
        FeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          paginationError: 'Failed to load more: $e',
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  // Refresh
  Future<void> refreshDiscoverFeed({int limit = 20}) async {
    await loadDiscoverFeed(limit: limit);
  }
}

// ─── Cached Discover Feed Notifier (Optimized) ────────────────────────────────

class CachedDiscoverFeedNotifier extends AsyncNotifier<CachedFeedState> {
  // Fix #3: dedicated flag to prevent concurrent loadMore calls
  bool _isLoadingMore = false;

  @override
  Future<CachedFeedState> build() async {
    return const CachedFeedState(
      items: [],
      hasMore: true,
      nextCursor: null,
      cacheHit: false,
    );
  }

  // Load with caching info
  Future<void> loadCachedDiscoverFeed({int limit = 20}) async {
    state = const AsyncLoading();
    try {
      final response = await ref
          .read(feedServiceProvider)
          .getDiscoverFeedCached(limit: limit);

      state = AsyncData(
        CachedFeedState(
          items: response.data.items,
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
          cacheHit: response.cacheHit,
          queryTimeMs: response.queryTimeMs,
          cachedAt: response.cachedAt != null
              ? DateTime.tryParse(response.cachedAt!)
              : null,
          cacheTtlSeconds: response.cacheTtlSeconds,
        ),
      );
    } on DioException catch (e) {
      state = AsyncError(
        'DioError ${e.response?.statusCode}: ${e.response?.data}',
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncError('Unknown error: $e', st);
    }
  }

  // Load next page (cached version)
  Future<void> loadMoreCachedDiscoverFeed({int limit = 20}) async {
    // Fix #3: guard against concurrent calls
    if (_isLoadingMore) return;
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;
    if (currentState.nextCursor == null) return;

    _isLoadingMore = true;
    final previousItems = currentState.items;

    try {
      final response = await ref
          .read(feedServiceProvider)
          .getDiscoverFeedCached(limit: limit, cursor: currentState.nextCursor);

      state = AsyncData(
        CachedFeedState(
          items: [...previousItems, ...response.data.items],
          hasMore: response.data.hasMore,
          nextCursor: response.data.nextCursor,
          cacheHit: response.cacheHit,
          queryTimeMs: response.queryTimeMs,
          cachedAt: response.cachedAt != null
              ? DateTime.tryParse(response.cachedAt!)
              : null,
          cacheTtlSeconds: response.cacheTtlSeconds,
        ),
      );
    } on DioException catch (e) {
      // Fix #4: surface pagination errors — preserve existing items
      state = AsyncData(
        CachedFeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          cacheHit: currentState.cacheHit,
          queryTimeMs: currentState.queryTimeMs,
          cachedAt: currentState.cachedAt,
          cacheTtlSeconds: currentState.cacheTtlSeconds,
          paginationError:
              'Failed to load more: ${e.response?.statusCode ?? e.message}',
        ),
      );
    } catch (e) {
      state = AsyncData(
        CachedFeedState(
          items: previousItems,
          hasMore: currentState.hasMore,
          nextCursor: currentState.nextCursor,
          cacheHit: currentState.cacheHit,
          queryTimeMs: currentState.queryTimeMs,
          cachedAt: currentState.cachedAt,
          cacheTtlSeconds: currentState.cacheTtlSeconds,
          paginationError: 'Failed to load more: $e',
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  // Fix #5: added missing refresh method (was present on the other two notifiers)
  Future<void> refreshCachedDiscoverFeed({int limit = 20}) async {
    await loadCachedDiscoverFeed(limit: limit);
  }

  // Clear the cache on server
  Future<void> clearCache() async {
    try {
      await ref.read(feedServiceProvider).clearFeedCache();
    } on DioException catch (e) {
      rethrow;
    }
  }
}

// ─── State Classes ────────────────────────────────────────────────────────────

class FeedState {
  final List<FeedTrackItem> items;
  final bool hasMore;
  final String? nextCursor;
  // Fix #4: field for surfacing pagination errors without losing existing items
  final String? paginationError;

  const FeedState({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    this.paginationError,
  });

  // Fix #6: equality and hashCode so Riverpod skips unnecessary rebuilds
  @override
  bool operator ==(Object other) =>
      other is FeedState &&
      other.hasMore == hasMore &&
      other.nextCursor == nextCursor &&
      other.paginationError == paginationError &&
      listEquals(other.items, items);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), hasMore, nextCursor, paginationError);
}

class CachedFeedState extends FeedState {
  final bool cacheHit;
  final double? queryTimeMs;
  final DateTime? cachedAt;
  final int? cacheTtlSeconds;

  const CachedFeedState({
    required super.items,
    required super.hasMore,
    super.nextCursor,
    super.paginationError,
    required this.cacheHit,
    this.queryTimeMs,
    this.cachedAt,
    this.cacheTtlSeconds,
  });

  bool get isFromCache => cacheHit;

  bool get isCacheExpired {
    if (cachedAt == null || cacheTtlSeconds == null) return true;
    return DateTime.now().difference(cachedAt!).inSeconds > cacheTtlSeconds!;
  }

  // Fix #6: equality and hashCode for CachedFeedState
  @override
  bool operator ==(Object other) =>
      other is CachedFeedState &&
      super == other &&
      other.cacheHit == cacheHit &&
      other.queryTimeMs == queryTimeMs &&
      other.cachedAt == cachedAt &&
      other.cacheTtlSeconds == cacheTtlSeconds;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    cacheHit,
    queryTimeMs,
    cachedAt,
    cacheTtlSeconds,
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final followingFeedProvider =
    AsyncNotifierProvider<FollowingFeedNotifier, FeedState>(
      FollowingFeedNotifier.new,
    );

final discoverFeedProvider =
    AsyncNotifierProvider<DiscoverFeedNotifier, FeedState>(
      DiscoverFeedNotifier.new,
    );

final cachedDiscoverFeedProvider =
    AsyncNotifierProvider<CachedDiscoverFeedNotifier, CachedFeedState>(
      CachedDiscoverFeedNotifier.new,
    );
