// providers/followers_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/follower.dart';
import '../services/followers_service.dart';
import 'auth_providers.dart';

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

// ─── POST/DELETE /users/{username}/follow ─────────────────────────────────────
//
// Handles follow + unfollow with optimistic UI updates.
// The notifier tracks whether the current user is following `username`.
// Call [toggle] to flip the state; the provider will call the correct endpoint.

class FollowNotifier extends FamilyAsyncNotifier<bool, String> {
  /// [arg] is the target username.
  @override
  Future<bool> build(String arg) async {
    // Derive initial state from the "my following" list so the button renders
    // correctly without an extra network call.
    // Falls back to false if the list isn't loaded yet.
    final followingAsync = ref.watch(myFollowingProvider);
    return followingAsync.maybeWhen(
      data: (res) => res.following.any((f) => f.username == arg),
      orElse: () => false,
    );
  }

  Future<void> toggle() async {
    final currentlyFollowing = state.valueOrNull ?? false;

    // Optimistic update
    state = AsyncData(!currentlyFollowing);

    try {
      if (currentlyFollowing) {
        await ref.read(followersServiceProvider).unfollowUser(username: arg);
      } else {
        await ref.read(followersServiceProvider).followUser(username: arg);
      }
      // Refresh social graph caches
      ref.invalidate(myFollowingProvider);
      ref.invalidate(userFollowersProvider(arg));
      ref.invalidate(userFollowingProvider(arg));
    } on DioException catch (e) {
      // Rollback on failure
      state = AsyncData(currentlyFollowing);
      state = AsyncError(Exception(_dioError(e)), StackTrace.current);
    } catch (e) {
      state = AsyncData(currentlyFollowing);
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final followProvider =
    AsyncNotifierProviderFamily<FollowNotifier, bool, String>(
      FollowNotifier.new,
    );

// ─── POST/DELETE /users/{username}/block ──────────────────────────────────────
//
// Tracks block state for a given username.
// Call [toggle] to block or unblock.
// After blocking, the target user is also unfollowed on the server side
// (standard platform behaviour), so related caches are invalidated.

class BlockNotifier extends FamilyAsyncNotifier<bool, String> {
  /// [arg] is the target username.
  @override
  Future<bool> build(String arg) async => false; // no "blocked list" endpoint in spec

  Future<void> toggle() async {
    final currentlyBlocked = state.valueOrNull ?? false;

    // Optimistic update
    state = AsyncData(!currentlyBlocked);

    try {
      if (currentlyBlocked) {
        await ref.read(followersServiceProvider).unblockUser(username: arg);
      } else {
        await ref.read(followersServiceProvider).blockUser(username: arg);
        // Blocking typically removes the follow relationship on both sides.
        ref.invalidate(followProvider(arg));
        ref.invalidate(myFollowingProvider);
        ref.invalidate(myFollowersProvider);
        ref.invalidate(userFollowersProvider(arg));
        ref.invalidate(userFollowingProvider(arg));
      }
    } on DioException catch (e) {
      // Rollback on failure
      state = AsyncData(currentlyBlocked);
      state = AsyncError(Exception(_dioError(e)), StackTrace.current);
    } catch (e) {
      state = AsyncData(currentlyBlocked);
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final blockProvider = AsyncNotifierProviderFamily<BlockNotifier, bool, String>(
  BlockNotifier.new,
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
