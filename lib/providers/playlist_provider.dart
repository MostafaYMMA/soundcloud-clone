import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import 'auth_providers.dart';

class PlaylistState {
  final List<Playlist> likedPlaylists;
  final List<Playlist> userPlaylists;
  final List<Playlist> searchResults;
  final bool isLoadingLiked;
  final bool isLoadingUserPlaylists;
  final bool isSearching;
  final bool isCreating;
  final bool isLiking;
  final bool isUpdating;
  final String? error;
  final String? successMessage;

  const PlaylistState({
    this.likedPlaylists = const [],
    this.userPlaylists = const [],
    this.searchResults = const [],
    this.isLoadingLiked = false,
    this.isLoadingUserPlaylists = false,
    this.isSearching = false,
    this.isCreating = false,
    this.isLiking = false,
    this.isUpdating = false,
    this.error,
    this.successMessage,
  });

  PlaylistState copyWith({
    List<Playlist>? likedPlaylists,
    List<Playlist>? userPlaylists,
    List<Playlist>? searchResults,
    bool? isLoadingLiked,
    bool? isLoadingUserPlaylists,
    bool? isSearching,
    bool? isCreating,
    bool? isLiking,
    bool? isUpdating,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PlaylistState(
      likedPlaylists: likedPlaylists ?? this.likedPlaylists,
      userPlaylists: userPlaylists ?? this.userPlaylists,
      searchResults: searchResults ?? this.searchResults,
      isLoadingLiked: isLoadingLiked ?? this.isLoadingLiked,
      isLoadingUserPlaylists:
          isLoadingUserPlaylists ?? this.isLoadingUserPlaylists,
      isSearching: isSearching ?? this.isSearching,
      isCreating: isCreating ?? this.isCreating,
      isLiking: isLiking ?? this.isLiking,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : error ?? this.error,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final PlaylistService _service;
  final Ref ref;

  PlaylistNotifier(this._service, this.ref) : super(const PlaylistState());

  String? get _token => ref.read(authProvider).tokens?.accessToken;

  // ── GET /playlists/liked ────────────────────────────────────────────────────

  Future<void> fetchLikedPlaylists() async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isLoadingLiked: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final playlists = await _service.getLikedPlaylists(token);
      state = state.copyWith(
        likedPlaylists: playlists,
        isLoadingLiked: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingLiked: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── GET /users/{username}/playlists ────────────────────────────────────────

  Future<void> fetchUserPlaylists(String username) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return;
    }

    state = state.copyWith(isLoadingUserPlaylists: true, clearError: true);

    try {
      final playlists = await _service.getUserPlaylists(
        username: username,
        accessToken: token,
      );
      state = state.copyWith(
        userPlaylists: playlists,
        isLoadingUserPlaylists: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingUserPlaylists: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── GET /playlists/{playlist_id} ───────────────────────────────────────────

  Future<Playlist?> getPlaylistDetails(String playlistId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return null;
    }

    try {
      return await _service.getPlaylistById(
        playlistId: playlistId,
        accessToken: token,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  // ── GET /search/playlists ──────────────────────────────────────────────────

  Future<void> searchPlaylists(String keyword) async {
    final token = _token;
    if (keyword.trim().isEmpty) {
      state = state.copyWith(searchResults: [], clearError: true);
      return;
    }
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final results = await _service.searchPlaylists(
        keyword: keyword.trim(),
        accessToken: token,
      );
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── POST /playlists/{playlist_id}/like ─────────────────────────────────────

  Future<void> likePlaylist(String playlistId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return;
    }

    state = state.copyWith(
      isLiking: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _service.likePlaylist(playlistId: playlistId, accessToken: token);
      await fetchLikedPlaylists();
      state = state.copyWith(
        isLiking: false,
        successMessage: 'Playlist added to your playlists.',
      );
    } catch (e) {
      state = state.copyWith(
        isLiking: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── DELETE /playlists/{playlist_id}/like ───────────────────────────────────

  Future<void> unlikePlaylist(String playlistId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(error: 'No access token.');
      return;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _service.unlikePlaylist(playlistId: playlistId, accessToken: token);
      await fetchLikedPlaylists();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Removed from your playlists.',
      );
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }

  // ── POST /playlists/{playlist_id}/tracks ───────────────────────────────────

  Future<void> addTrack({
    required String playlistId,
    required String trackId,
  }) async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      await _service.addTrackToPlaylist(
        playlistId: playlistId,
        trackId: trackId,
        accessToken: token,
      );
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Track added successfully.',
      );
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }

  // ── DELETE /playlists/{playlist_id}/tracks/{track_id} ──────────────────────

  Future<bool> removeTrack({
    required String playlistId,
    required String trackId,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(error: 'No access token.');
      return false;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _service.removeTrackFromPlaylist(
        playlistId: playlistId,
        trackId: trackId,
        accessToken: token,
      );
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Track removed.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── POST /playlists/{playlist_id}/cover ────────────────────────────────────

  Future<void> uploadCover({
    required String playlistId,
    required String filePath,
  }) async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      await _service.uploadPlaylistCover(
        playlistId: playlistId,
        filePath: filePath,
        accessToken: token,
      );
      await fetchLikedPlaylists();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Cover updated.',
      );
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }

  // ── POST /playlists/ ───────────────────────────────────────────────────────

  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return null;
    }

    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final playlist = await _service.createPlaylist(
        accessToken: token,
        name: name,
        description: description,
      );

      await _service.likePlaylist(
        playlistId: playlist.id,
        accessToken: token,
      );
      await fetchLikedPlaylists();
      state = state.copyWith(
        isCreating: false,
        successMessage: 'Playlist created successfully.',
      );
      return playlist;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  // ── PATCH /playlists/{playlist_id} ─────────────────────────────────────────

  Future<Playlist?> updatePlaylist({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return null;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _service.updatePlaylist(
        playlistId: playlistId,
        accessToken: token,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      await fetchLikedPlaylists();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Playlist updated.',
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  // ── DELETE /playlists/{playlist_id} ────────────────────────────────────────

  Future<bool> deletePlaylist(String playlistId) async {
    final token = _token;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _service.deletePlaylist(playlistId: playlistId, accessToken: token);
      state = state.copyWith(
        isUpdating: false,
        userPlaylists: state.userPlaylists
            .where((p) => p.id != playlistId)
            .toList(),
        likedPlaylists: state.likedPlaylists
            .where((p) => p.id != playlistId)
            .toList(),
        successMessage: 'Playlist deleted.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>(
  (ref) {
    final service = PlaylistService(dio: Dio());
    return PlaylistNotifier(service, ref);
  },
);

// ── FutureProvider for liked playlists — used by profile Likes section ────────

final userLikedPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final token = ref.watch(authProvider).tokens?.accessToken;
  if (token == null || token.isEmpty) return [];
  final service = PlaylistService(dio: Dio());
  return service.getLikedPlaylists(token);
});
