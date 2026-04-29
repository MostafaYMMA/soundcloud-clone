import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../services/album_service.dart';
import 'auth_providers.dart';

class AlbumState {
  final List<Album> likedAlbums;
  final bool isLoadingLiked;
  final String? error;

  const AlbumState({
    this.likedAlbums = const [],
    this.isLoadingLiked = false,
    this.error,
  });

  AlbumState copyWith({
    List<Album>? likedAlbums,
    bool? isLoadingLiked,
    String? error,
    bool clearError = false,
  }) {
    return AlbumState(
      likedAlbums: likedAlbums ?? this.likedAlbums,
      isLoadingLiked: isLoadingLiked ?? this.isLoadingLiked,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AlbumNotifier extends StateNotifier<AlbumState> {
  final AlbumService _service;
  final Ref ref;

  AlbumNotifier(this._service, this.ref) : super(const AlbumState());

  String? get _token => ref.read(authProvider).tokens?.accessToken;

  Future<void> fetchLikedAlbums() async {
    final token = _token;

    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return;
    }

    state = state.copyWith(isLoadingLiked: true, clearError: true);

    try {
      final albums = await _service.getLikedAlbums(token);
      state = state.copyWith(likedAlbums: albums, isLoadingLiked: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingLiked: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Album?> getAlbumDetails(String albumId) async {
    final token = _token;

    if (token == null || token.isEmpty) {
      state = state.copyWith(
        error: 'No access token found. Please log in again.',
      );
      return null;
    }

    try {
      return await _service.getAlbumById(albumId: albumId, accessToken: token);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}

final albumProvider = StateNotifierProvider<AlbumNotifier, AlbumState>((ref) {
  final service = AlbumService(dio: Dio());
  return AlbumNotifier(service, ref);
});
