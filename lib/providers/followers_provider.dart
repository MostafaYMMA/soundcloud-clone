// providers/followers_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/follower.dart';
import '../services/followers_service.dart';
import 'auth_providers.dart';

// ─── Follow key ───────────────────────────────────────────────────────────────

typedef FollowKey = ({String userId, String username});

// ─── Service Provider ─────────────────────────────────────────────────────────

final followersServiceProvider = Provider<FollowersService>((ref) {
  final token = ref.watch(authProvider).tokens?.accessToken ?? '';
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return FollowersService(dio: dio);
});

// ─── GET /users/me/followers ──────────────────────────────────────────────────

final myFollowersProvider = FutureProvider<FollowerListResponse>((ref) async {
  return ref.read(followersServiceProvider).getMyFollowers();
});

// ─── GET /users/me/following ──────────────────────────────────────────────────

final myFollowingProvider = FutureProvider<FollowingListResponse>((ref) async {
  return ref.read(followersServiceProvider).getMyFollowing();
});

// ─── GET /users/{username}/followers ─────────────────────────────────────────

final userFollowersProvider =
    FutureProvider.family<FollowerListResponse, String>((ref, username) async {
      return ref
          .read(followersServiceProvider)
          .getUserFollowers(username: username);
    });

// ─── GET /users/{username}/following ─────────────────────────────────────────

final userFollowingProvider =
    FutureProvider.family<FollowingListResponse, String>((ref, username) async {
      return ref
          .read(followersServiceProvider)
          .getUserFollowing(username: username);
    });

// ─── POST/DELETE /users/{username}/follow ────────────────────────────────────

class FollowNotifier extends StateNotifier<_FollowState> {
  final FollowersService _service;
  final String _username;
  final Ref _ref;

  FollowNotifier({
    required FollowersService service,
    required String username,
    required bool initiallyFollowing,
    required Ref ref,
  }) : _service = service,
       _username = username,
       _ref = ref,
       super(_FollowState(isFollowing: initiallyFollowing));

  Future<void> toggle() async {
    if (state.isLoading) return;

    final prev = state.isFollowing;
    state = state.copyWith(isFollowing: !prev, isLoading: true);

    try {
      if (prev) {
        await _service.unfollowUser(username: _username);
      } else {
        await _service.followUser(username: _username);
      }
      state = state.copyWith(isLoading: false);
      // Invalidate so FollowingScreen re-fetches the updated list
      _ref.invalidate(myFollowingProvider);
    } catch (_) {
      state = state.copyWith(isFollowing: prev, isLoading: false);
    }
  }
}

class _FollowState {
  final bool isFollowing;
  final bool isLoading;

  const _FollowState({required this.isFollowing, this.isLoading = false});

  _FollowState copyWith({bool? isFollowing, bool? isLoading}) => _FollowState(
    isFollowing: isFollowing ?? this.isFollowing,
    isLoading: isLoading ?? this.isLoading,
  );
}

// Keyed by userId — one instance per artist shared across the whole app.
// Username is carried along for the API call.
// ref.watch (not read) ensures the notifier rebuilds when myFollowingProvider
// loads or refreshes, so the correct isFollowing state is reflected on every
// track by the same artist across the whole app.
final followProvider =
    StateNotifierProvider.family<FollowNotifier, _FollowState, FollowKey>((
      ref,
      key,
    ) {
      final followingAsync = ref.watch(myFollowingProvider);
      final initiallyFollowing = followingAsync.maybeWhen(
        data: (res) => res.following.any((f) => f.userId == key.userId),
        orElse: () => false,
      );

      return FollowNotifier(
        service: ref.read(followersServiceProvider),
        username: key.username,
        initiallyFollowing: initiallyFollowing,
        ref: ref,
      );
    });

// ─── POST/DELETE /users/{username}/block ──────────────────────────────────────

class BlockNotifier extends StateNotifier<_FollowState> {
  final FollowersService _service;
  final String _username;

  BlockNotifier({required FollowersService service, required String username})
    : _service = service,
      _username = username,
      super(const _FollowState(isFollowing: false));

  Future<void> toggle() async {
    if (state.isLoading) return;

    final prev = state.isFollowing;
    state = state.copyWith(isFollowing: !prev, isLoading: true);

    try {
      if (prev) {
        await _service.unblockUser(username: _username);
      } else {
        await _service.blockUser(username: _username);
      }
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isFollowing: prev, isLoading: false);
    }
  }
}

final blockProvider =
    StateNotifierProvider.family<BlockNotifier, _FollowState, String>(
      (ref, username) => BlockNotifier(
        service: ref.read(followersServiceProvider),
        username: username,
      ),
    );

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dioError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 401) return 'You are not logged in.';
  if (status == 403) return 'You do not have permission to do this.';
  if (status == 404) return 'User not found.';
  if (status == 422) return 'Invalid request. Please try again.';
  return 'Something went wrong. Please try again.';
}
