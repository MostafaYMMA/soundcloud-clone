import 'package:dio/dio.dart';
import '../models/track.dart';

class MusicService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://streamline-swp.duckdns.org/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Track>> searchTracks(String query) async {
    final res = await _dio.get(
      'search/tracks',
      queryParameters: {"keyword": query},
    );

    final data = res.data;

    final List tracks = data['data']['tracks'];

    return tracks.map<Track>((json) => Track.fromJson(json)).toList();
  }

  Future<List<Track>> getTracks() async {
    return searchTracks('');
  }
}
