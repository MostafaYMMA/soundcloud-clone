import 'package:dio/dio.dart';
import '../models/playlist.dart';

class PlaylistService {
  final Dio _dio;
  final String baseUrl = 'https://streamline-swp.duckdns.org/api';

  PlaylistService({required Dio dio}) : _dio = dio;

  Options _authOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  String _readableError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    switch (status) {
      case 400:
        return 'Bad request. Please check the entered data.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You are not allowed to perform this action.';
      case 404:
        return 'Playlist not found.';
      case 422:
        return 'Invalid data sent to server.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  // GET /playlists/liked
  Future<List<Playlist>> getLikedPlaylists(String accessToken) async {
    try {
      final res = await _dio.get(
        '$baseUrl/playlists/liked',
        options: _authOptions(accessToken),
      );
      final data = res.data['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Playlist.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // GET /users/{username}/playlists
  Future<List<Playlist>> getUserPlaylists({
    required String username,
    required String accessToken,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/users/$username/playlists',
        options: _authOptions(accessToken),
      );
      final data = res.data['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Playlist.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // GET /playlists/{playlist_id}
  Future<Playlist> getPlaylistById({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/playlists/$playlistId',
        options: _authOptions(accessToken),
      );
      return Playlist.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // GET /search/playlists?keyword=
  Future<List<Playlist>> searchPlaylists({
    required String keyword,
    required String accessToken,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/search/playlists',
        queryParameters: {'keyword': keyword},
        options: _authOptions(accessToken),
      );
      final playlists = res.data['data']?['playlists'];
      if (playlists is List) {
        return playlists
            .whereType<Map<String, dynamic>>()
            .map(Playlist.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // POST /playlists/{playlist_id}/like
  Future<void> likePlaylist({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/playlists/$playlistId/like',
        options: _authOptions(accessToken),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // DELETE /playlists/{playlist_id}/like
  Future<void> unlikePlaylist({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
      await _dio.delete(
        '$baseUrl/playlists/$playlistId/like',
        options: _authOptions(accessToken),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // POST /playlists/{playlist_id}/tracks
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    required String accessToken,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/playlists/$playlistId/tracks',
        data: {'track_id': trackId},
        options: _authOptions(accessToken),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // DELETE /playlists/{playlist_id}/tracks/{track_id}
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
    required String accessToken,
  }) async {
    try {
      await _dio.delete(
        '$baseUrl/playlists/$playlistId/tracks/$trackId',
        options: _authOptions(accessToken),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // POST /playlists/{playlist_id}/cover (multipart)
  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
    required String accessToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(
        '$baseUrl/playlists/$playlistId/cover',
        data: formData,
        options: _authOptions(accessToken),
      );
      return res.data['data']?['cover_photo_url'];
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // POST /playlists/
  Future<Playlist> createPlaylist({
    required String accessToken,
    required String name,
    String? description,
  }) async {
    try {
      final res = await _dio.post(
        '$baseUrl/playlists/',
        data: {'name': name, 'description': description ?? ''},
        options: _authOptions(accessToken),
      );
      return Playlist.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // PATCH /playlists/{playlist_id}
  Future<Playlist> updatePlaylist({
    required String playlistId,
    required String accessToken,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final res = await _dio.patch(
        '$baseUrl/playlists/$playlistId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (isPublic != null) 'is_public': isPublic,
        },
        options: _authOptions(accessToken),
      );
      return Playlist.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  // DELETE /playlists/{playlist_id}
  Future<void> deletePlaylist({
    required String playlistId,
    required String accessToken,
  }) async {
    try {
      await _dio.delete(
        '$baseUrl/playlists/$playlistId',
        options: _authOptions(accessToken),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }
}
