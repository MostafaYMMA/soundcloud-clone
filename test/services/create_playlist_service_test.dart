import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/models/playlist.dart';
import 'package:my_project/services/create_playlist_service.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioErr({int statusCode = 500}) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        data: {},
        statusCode: statusCode,
        requestOptions: RequestOptions(path: ''),
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  late MockDio mockDio;
  late CreatePlaylistService sut;

  setUp(() {
    mockDio = MockDio();
    sut = CreatePlaylistService(dio: mockDio);
  });

  group('CreatePlaylistService.createPlaylist', () {
    test('creates playlist and returns Playlist object', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {
            'id': 'playlist-1',
            'name': 'New Playlist',
            'description': 'My playlist',
            'user_id': 'user-1',
            'is_public': true,
            'track_count': 0,
            'cover_url': '',
            'tracks': [],
          },
        }),
      );

      final playlist = await sut.createPlaylist(
        accessToken: 'token-123',
        name: 'New Playlist',
        description: 'My playlist',
      );

      expect(playlist, isA<Playlist>());
      expect(playlist.id, 'playlist-1');
      expect(playlist.name, 'New Playlist');
    });

    test('creates playlist without description', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => _res({
          'data': {
            'id': 'playlist-2',
            'name': 'Another Playlist',
            'description': '',
            'user_id': 'user-1',
            'is_public': true,
            'track_count': 0,
            'cover_url': '',
            'tracks': [],
          },
        }),
      );

      final playlist = await sut.createPlaylist(
        accessToken: 'token-123',
        name: 'Another Playlist',
      );

      expect(playlist.name, 'Another Playlist');
    });

    test('throws DioException on creation failure', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(
        () => sut.createPlaylist(
          accessToken: 'invalid-token',
          name: 'Playlist',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
