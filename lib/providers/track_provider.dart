// providers/tracks_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../services/track_service.dart';
import '../services/user_profile_services.dart';
import 'auth_providers.dart';

// ─── Service Provider ─────────────────────────────────────────────────────────

final tracksServiceProvider = Provider<TracksService>((ref) {
  final token = ref.watch(authProvider).tokens?.accessToken;
  final dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('DIO ${response.statusCode}: ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (e, handler) {
        print('DIO ERROR ${e.response?.statusCode}: ${e.requestOptions.uri}');
        print('DIO DATA: ${e.response?.data}');
        handler.next(e);
      },
    ),
  );

  return TracksService(dio: dio);
});

// ─── GET /tracks/{track_id} ───────────────────────────────────────────────────

final trackProvider = FutureProvider.family<Track, String>((
  ref,
  String trackId,
) async {
  return ref.read(tracksServiceProvider).getTrack(trackId: trackId);
});

// ─── GET /tracks/{track_id}/waveform ──────────────────────────────────────────

final trackWaveformProvider = FutureProvider.family<List<double>, String>((
  ref,
  String trackId,
) async {
  try {
    print('Fetching waveform for: $trackId');

    if (trackId.trim().isEmpty) {
      print('EMPTY TRACK ID');
      return [];
    }

    List peaks = [];

    // ── 1. TRY WAVEFORM ENDPOINT ──
    try {
      final data = await ref
          .read(tracksServiceProvider)
          .getTrackWaveform(trackId: trackId);

      print('WAVEFORM RESPONSE: $data');

      if (data['peaks'] is List) {
        peaks = data['peaks'];
      }
    } catch (e) {
      print('waveform endpoint failed, trying playback...');
    }

    // ── 2. FALLBACK TO PLAYBACK ──
    if (peaks.isEmpty) {
      try {
        final playback = await ref
            .read(tracksServiceProvider)
            .getTrackPlayback(trackId: trackId);

        print('PLAYBACK RESPONSE: $playback');

        if (playback['waveform'] is List) {
          peaks = playback['waveform'];
        } else if (playback['peaks'] is List) {
          peaks = playback['peaks'];
        } else if (playback['data'] is Map &&
            playback['data']['peaks'] is List) {
          peaks = playback['data']['peaks'];
        }
      } catch (e) {
        print('playback fallback also failed');
      }
    }

    // ── 3. FINAL CHECK ──
    if (peaks.isEmpty) {
      print('NO WAVEFORM DATA FOUND');
      return [];
    }

    final values = peaks
        .whereType<num>()
        .map((e) => e.toDouble().abs())
        .toList();

    if (values.isEmpty) {
      print('INVALID PEAKS');
      return [];
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    if (maxValue <= 0) {
      return values.map((_) => 0.15).toList();
    }

    final normalized = values.map((v) {
      final value = v / maxValue;
      return value.clamp(0.08, 1.0);
    }).toList();

    print('FINAL WAVEFORM BARS: ${normalized.length}');

    return normalized;
  } catch (e) {
    print('WAVEFORM ERROR: $e');
    return [];
  }
});

// ─── GET /search/tracks?keyword= ─────────────────────────────────────────────

final searchTracksProvider = FutureProvider.family<List<Track>, String>((
  ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];
  return ref.read(tracksServiceProvider).searchTracks(keyword: query.trim());
});

// ─── GET /users/{username}/tracks ────────────────────────────────────────────

final userTracksProvider = FutureProvider.family<List<Track>, String>((
  ref,
  String username,
) async {
  return ref.read(tracksServiceProvider).getUserTracks(username: username);
});

// ─── GET /users/{username}/liked-tracks ──────────────────────────────────────

final userLikedTracksProvider = FutureProvider.family<List<Track>, String>((
  ref,
  String username,
) async {
  return ref.read(tracksServiceProvider).getUserLikedTracks(username: username);
});

// ─── GET /reposts/users/{username} ───────────────────────────────────────────

final userRepostsProvider = FutureProvider.family<List<Track>, String>((
  ref,
  String username,
) async {
  final userService = UserService(dio: Dio());
  return userService.getUserReposts(username: username);
});

// ─── Feed State ───────────────────────────────────────────────────────────────

class FeedState {
  final List<Track> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;

  const FeedState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
  });

  FeedState copyWith({
    List<Track>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool clearError = false,
  }) {
    return FeedState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── GET /feed/following ──────────────────────────────────────────────────────

class FollowingFeedNotifier extends StateNotifier<FeedState> {
  final TracksService _service;

  FollowingFeedNotifier(this._service) : super(const FeedState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading || state.isFetchingMore) return;

    if (refresh) {
      state = const FeedState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final data = await _service.getFollowingFeed(limit: 20);
      final rawItems = data['items'] as List? ?? [];

      state = FeedState(
        items: rawItems
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: data['next_cursor']?.toString(),
        hasMore: data['has_more'] as bool? ?? false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (!state.hasMore || state.isFetchingMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isFetchingMore: true);
    try {
      final data = await _service.getFollowingFeed(
        limit: 20,
        cursor: state.nextCursor,
      );

      final rawItems = data['items'] as List? ?? [];
      final newTracks = rawItems
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newTracks],
        nextCursor: data['next_cursor']?.toString(),
        hasMore: data['has_more'] as bool? ?? false,
        isFetchingMore: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isFetchingMore: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: e.toString());
    }
  }

  void toggleLike(String trackId) {
    state = state.copyWith(
      items: state.items.map((t) {
        if (t.trackId != trackId) return t;
        final liked = !(t.isLiked ?? false);
        return t.copyWith(
          isLiked: liked,
          likeCount: (t.likeCount ?? 0) + (liked ? 1 : -1),
        );
      }).toList(),
    );
  }

  Future<void> refresh() => fetch(refresh: true);
}

final followingFeedProvider =
    StateNotifierProvider<FollowingFeedNotifier, FeedState>((ref) {
  return FollowingFeedNotifier(ref.read(tracksServiceProvider));
});

// ─── GET /feed/discover ───────────────────────────────────────────────────────

class DiscoverFeedNotifier extends StateNotifier<FeedState> {
  final TracksService _service;

  DiscoverFeedNotifier(this._service) : super(const FeedState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading || state.isFetchingMore) return;

    if (refresh) {
      state = const FeedState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final data = await _service.getDiscoverFeed(limit: 20);
      final rawItems = data['items'] as List? ?? [];

      state = FeedState(
        items: rawItems
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: data['next_cursor']?.toString(),
        hasMore: data['has_more'] as bool? ?? false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (!state.hasMore || state.isFetchingMore || state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isFetchingMore: true);
    try {
      final data = await _service.getDiscoverFeed(
        limit: 20,
        cursor: state.nextCursor,
      );

      final rawItems = data['items'] as List? ?? [];
      final newTracks = rawItems
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newTracks],
        nextCursor: data['next_cursor']?.toString(),
        hasMore: data['has_more'] as bool? ?? false,
        isFetchingMore: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isFetchingMore: false, error: _dioError(e));
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: e.toString());
    }
  }

  void toggleLike(String trackId) {
    state = state.copyWith(
      items: state.items.map((t) {
        if (t.trackId != trackId) return t;
        final liked = !(t.isLiked ?? false);
        return t.copyWith(
          isLiked: liked,
          likeCount: (t.likeCount ?? 0) + (liked ? 1 : -1),
        );
      }).toList(),
    );
  }

  Future<void> refresh() => fetch(refresh: true);
}

final discoverFeedProvider =
    StateNotifierProvider<DiscoverFeedNotifier, FeedState>((ref) {
  return DiscoverFeedNotifier(ref.read(tracksServiceProvider));
});

// ─── POST /tracks/{track_id}/plays ───────────────────────────────────────────

class RecordPlayNotifier extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> record({int? durationListenedSeconds}) async {
    try {
      await ref
          .read(tracksServiceProvider)
          .recordPlay(
            trackId: arg,
            durationListenedSeconds: durationListenedSeconds,
          );
    } on DioException catch (e) {
      throw Exception(_dioError(e));
    }
  }
}

final recordPlayProvider =
    AsyncNotifierProviderFamily<RecordPlayNotifier, void, String>(
  RecordPlayNotifier.new,
);

// ─── POST /tracks/ ────────────────────────────────────────────────────────────

class CreateTrackNotifier extends AsyncNotifier<Track?> {
  @override
  Future<Track?> build() async => null;

  Future<Track> create({
    required String title,
    required String description,
    required String filePath,
    String? genre,
    String? tags,
    String? releaseDate,
    String visibility = 'public',
    String? coverImagePath,
  }) async {
    state = const AsyncLoading();

    final token = ref.read(authProvider).tokens?.accessToken;

    if (token == null || token.isEmpty) {
      final err = Exception('You are not logged in.');
      state = AsyncError(err, StackTrace.current);
      throw err;
    }

    try {
      final track = await ref
          .read(tracksServiceProvider)
          .createTrack(
            accessToken: token,
            title: title,
            description: description,
            filePath: filePath,
            genre: genre,
            tags: tags,
            releaseDate: releaseDate,
            visibility: visibility,
            coverImagePath: coverImagePath,
          );

      print('========== UPLOADED TRACK ==========');
      print('ID: ${track.trackId}');
      print('TITLE: ${track.title}');
      print('VISIBILITY: ${track.visibility}');
      print('PROCESSING STATUS: ${track.processingStatus}');
      print('===================================');

      state = AsyncData(track);

      ref.read(followingFeedProvider.notifier).refresh();
      ref.read(discoverFeedProvider.notifier).refresh();

      return track;
    } on DioException catch (e) {
      final err = Exception(_dioError(e));
      state = AsyncError(err, StackTrace.current);
      throw err;
    } catch (e) {
      final err = Exception(e.toString().replaceFirst('Exception: ', ''));
      state = AsyncError(err, StackTrace.current);
      throw err;
    }
  }
}

final createTrackProvider = AsyncNotifierProvider<CreateTrackNotifier, Track?>(
  CreateTrackNotifier.new,
);

// ─── PUT /tracks/{track_id} ───────────────────────────────────────────────────

class UpdateTrackNotifier extends FamilyAsyncNotifier<Track?, String> {
  @override
  Future<Track?> build(String arg) async => null;

  Future<Track> updateTrack({
    String? title,
    String? description,
    String? genre,
    List<String>? tags,
    String? releaseDate,
    String? fileUrl,
    String? visibility,
  }) async {
    state = const AsyncLoading();

    try {
      final track = await ref
          .read(tracksServiceProvider)
          .updateTrack(
            trackId: arg,
            title: title,
            description: description,
            genre: genre,
            tags: tags,
            releaseDate: releaseDate,
            fileUrl: fileUrl,
            visibility: visibility,
          );

      state = AsyncData(track);

      ref.invalidate(trackProvider(arg));
      ref.invalidate(trackWaveformProvider(arg));

      ref.invalidate(trackProvider(arg));
      return track;
    } on DioException catch (e) {
      final err = Exception(_dioError(e));
      state = AsyncError(err, StackTrace.current);
      throw err;
    }
  }
}

final updateTrackProvider =
    AsyncNotifierProviderFamily<UpdateTrackNotifier, Track?, String>(
  UpdateTrackNotifier.new,
);

// ─── DELETE /tracks/{track_id} ───────────────────────────────────────────────

class DeleteTrackNotifier extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> delete() async {
    try {
      await ref.read(tracksServiceProvider).deleteTrack(trackId: arg);

      ref.invalidate(trackProvider(arg));
      ref.invalidate(trackWaveformProvider(arg));

      ref.read(followingFeedProvider.notifier).refresh();
      ref.read(discoverFeedProvider.notifier).refresh();
    } on DioException catch (e) {
      throw Exception(_dioError(e));
    }
  }
}

final deleteTrackProvider =
    AsyncNotifierProviderFamily<DeleteTrackNotifier, void, String>(
  DeleteTrackNotifier.new,
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dioError(DioException e) {
  final status = e.response?.statusCode;

  if (status == 401) return 'You are not logged in.';
  if (status == 403) return 'You do not have permission to do this.';
  if (status == 404) return 'Track not found.';
  if (status == 413) return 'File is too large.';

  return 'Something went wrong. Please try again.';
}

// ─── POST+DELETE /likes/tracks/{track_id} ────────────────────────────────────

class ToggleTrackLikeNotifier extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> toggle({
    required bool currentlyLiked,
    required String username,
  }) async {
    final service = ref.read(tracksServiceProvider);

    try {
      if (currentlyLiked) {
        await service.unlikeTrack(trackId: arg);
      } else {
        await service.likeTrack(trackId: arg);
      }

      // Update feeds optimistically
      ref.read(followingFeedProvider.notifier).toggleLike(arg);
      ref.read(discoverFeedProvider.notifier).toggleLike(arg);

      // Refresh single track cache
      ref.invalidate(trackProvider(arg));

      // DO NOT invalidate userLikedTracksProvider here —
      // it would trigger setAll() in LikedTracksScreen with stale
      // server data, stomping the optimistic toggle in likedTracksProvider.
    } on DioException catch (e) {
      throw Exception(_dioError(e));
    }
  }
}

final toggleTrackLikeProvider =
    AsyncNotifierProviderFamily<ToggleTrackLikeNotifier, void, String>(
  ToggleTrackLikeNotifier.new,
);

// ─── POST+DELETE /tracks/{track_id}/repost ────────────────────────────────────

class ToggleRepostNotifier extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> toggle({required bool currentlyReposted}) async {
    final service = ref.read(tracksServiceProvider);
    try {
      if (currentlyReposted) {
        await service.unrepostTrack(trackId: arg);
      } else {
        await service.repostTrack(trackId: arg);
      }
    } on DioException catch (e) {
      throw Exception(_dioError(e));
    }
  }
}

final toggleRepostProvider =
    AsyncNotifierProviderFamily<ToggleRepostNotifier, void, String>(
  ToggleRepostNotifier.new,
);