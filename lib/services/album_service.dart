import 'package:dio/dio.dart';
import '../models/album.dart';

class AlbumService {
  final Dio _dio;
  final String baseUrl = 'https://streamline-swp.duckdns.org/api';

  AlbumService({required Dio dio}) : _dio = dio;

  Options _authOptions(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  String _readableError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }

    switch (status) {
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You are not allowed to perform this action.';
      case 404:
        return 'Album not found.';
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

  /// GET /albums/liked
  Future<List<Album>> getLikedAlbums(String accessToken) async {
    try {
      final res = await _dio.get(
        '$baseUrl/albums/liked',
        options: _authOptions(accessToken),
      );

      print('GET LIKED ALBUMS STATUS: ${res.statusCode}');
      print('GET LIKED ALBUMS DATA: ${res.data}');

      final data = res.data['data'];

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Album.fromJson)
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  /// GET /albums/{album_id}
  Future<Album> getAlbumById({
    required String albumId,
    required String accessToken,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/albums/$albumId',
        options: _authOptions(accessToken),
      );

      print('GET ALBUM STATUS: ${res.statusCode}');
      print('GET ALBUM DATA: ${res.data}');

      return Album.fromJson(res.data['data']);
    } on DioException catch (e) {
      throw Exception(_readableError(e));
    }
  }
}