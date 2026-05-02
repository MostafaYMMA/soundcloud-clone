import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/playlist_service.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioErr({int statusCode = 500, String? detail}) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        data: detail != null ? {'detail': detail} : {},
        statusCode: statusCode,
        requestOptions: RequestOptions(path: ''),
      ),
      type: DioExceptionType.badResponse,
    );

const _token = 'test-access-token';

final _playlistData = {
  'playlist_id': 'pl-1',
  'user_id': 'u-1',
  'name': 'My Playlist',
  'description': 'A playlist',
  'cover_photo_url': 'https://example.com/cover.jpg',
  'is_public': true,
  'track_count': 0,
  'tracks': [],
};

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  late MockDio mockDio;
  late PlaylistService sut;

  setUp(() {
    mockDio = MockDio();
    sut = PlaylistService(dio: mockDio);
  });

  // ── getLikedPlaylists ─────────────────────────────────────────────────────

  group('PlaylistService.getLikedPlaylists', () {
    test('returns list of Playlists on success', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': [_playlistData]}));

      final playlists = await sut.getLikedPlaylists(_token);
      expect(playlists, hasLength(1));
      expect(playlists.first.id, 'pl-1');
      expect(playlists.first.name, 'My Playlist');
    });

    test('returns empty list when data is empty array', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': []}));

      final playlists = await sut.getLikedPlaylists(_token);
      expect(playlists, isEmpty);
    });

    test('returns empty list when data is not a list', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': null}));

      final playlists = await sut.getLikedPlaylists(_token);
      expect(playlists, isEmpty);
    });

    test('throws readable error on 401', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.getLikedPlaylists(_token),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('Session expired')),
        ),
      );
    });

    test('throws detail message when server includes detail field', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 400, detail: 'Custom server error'));

      expect(
        () => sut.getLikedPlaylists(_token),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('Custom server error')),
        ),
      );
    });

    test('throws readable error on 404', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.getLikedPlaylists(_token),
        throwsA(
          predicate<Exception>((e) => e.toString().contains('not found')),
        ),
      );
    });
  });

  // ── getUserPlaylists ──────────────────────────────────────────────────────

  group('PlaylistService.getUserPlaylists', () {
    test('returns list of user Playlists', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => _res({'data': [_playlistData, _playlistData]}),
      );

      final playlists = await sut.getUserPlaylists(username: 'user1', accessToken: _token);
      expect(playlists, hasLength(2));
    });

    test('returns empty list when data is not a list', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': null}));

      final playlists = await sut.getUserPlaylists(username: 'user1', accessToken: _token);
      expect(playlists, isEmpty);
    });
  });

  // ── getPlaylistById ───────────────────────────────────────────────────────

  group('PlaylistService.getPlaylistById', () {
    test('returns Playlist on success', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': _playlistData}));

      final playlist = await sut.getPlaylistById(playlistId: 'pl-1', accessToken: _token);
      expect(playlist.id, 'pl-1');
      expect(playlist.name, 'My Playlist');
    });

    test('throws readable error on 404', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.getPlaylistById(playlistId: 'nonexistent', accessToken: _token),
        throwsA(predicate<Exception>((e) => e.toString().contains('not found'))),
      );
    });
  });

  // ── searchPlaylists ───────────────────────────────────────────────────────

  group('PlaylistService.searchPlaylists', () {
    test('returns matching Playlists', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'playlists': [_playlistData]},
        }),
      );

      final results = await sut.searchPlaylists(keyword: 'my', accessToken: _token);
      expect(results, hasLength(1));
      expect(results.first.name, 'My Playlist');
    });

    test('returns empty list when playlists key is not a list', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': {'playlists': null}}));

      final results = await sut.searchPlaylists(keyword: 'nothing', accessToken: _token);
      expect(results, isEmpty);
    });
  });

  // ── createPlaylist ────────────────────────────────────────────────────────

  group('PlaylistService.createPlaylist', () {
    test('returns newly created Playlist', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': _playlistData}));

      final playlist = await sut.createPlaylist(
        accessToken: _token,
        name: 'My Playlist',
        description: 'A playlist',
      );
      expect(playlist.name, 'My Playlist');
    });

    test('throws readable error on 422 validation failure', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 422));

      expect(
        () => sut.createPlaylist(accessToken: _token, name: ''),
        throwsA(predicate<Exception>((e) => e.toString().contains('Invalid data'))),
      );
    });
  });

  // ── updatePlaylist ────────────────────────────────────────────────────────

  group('PlaylistService.updatePlaylist', () {
    test('returns updated Playlist', () async {
      final updated = Map<String, dynamic>.from(_playlistData)..['name'] = 'Renamed';

      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': updated}));

      final playlist = await sut.updatePlaylist(
        playlistId: 'pl-1',
        accessToken: _token,
        name: 'Renamed',
      );
      expect(playlist.name, 'Renamed');
    });
  });

  // ── deletePlaylist ────────────────────────────────────────────────────────

  group('PlaylistService.deletePlaylist', () {
    test('completes on success', () async {
      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => _res({'message': 'deleted'}));

      await expectLater(
        sut.deletePlaylist(playlistId: 'pl-1', accessToken: _token),
        completes,
      );
    });

    test('throws readable error on 403', () async {
      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(_dioErr(statusCode: 403));

      expect(
        () => sut.deletePlaylist(playlistId: 'pl-1', accessToken: _token),
        throwsA(predicate<Exception>((e) => e.toString().contains('not allowed'))),
      );
    });
  });

  // ── likePlaylist ──────────────────────────────────────────────────────────

  group('PlaylistService.likePlaylist', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'liked'}));

      await expectLater(
        sut.likePlaylist(playlistId: 'pl-1', accessToken: _token),
        completes,
      );
    });

    test('throws on 429 rate limit', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 429));

      expect(
        () => sut.likePlaylist(playlistId: 'pl-1', accessToken: _token),
        throwsA(predicate<Exception>((e) => e.toString().contains('Too many requests'))),
      );
    });
  });

  // ── unlikePlaylist ────────────────────────────────────────────────────────

  group('PlaylistService.unlikePlaylist', () {
    test('completes on success', () async {
      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => _res({'message': 'unliked'}));

      await expectLater(
        sut.unlikePlaylist(playlistId: 'pl-1', accessToken: _token),
        completes,
      );
    });
  });

  // ── addTrackToPlaylist ────────────────────────────────────────────────────

  group('PlaylistService.addTrackToPlaylist', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'added'}));

      await expectLater(
        sut.addTrackToPlaylist(playlistId: 'pl-1', trackId: 'trk-1', accessToken: _token),
        completes,
      );
    });
  });

  // ── removeTrackFromPlaylist ───────────────────────────────────────────────

  group('PlaylistService.removeTrackFromPlaylist', () {
    test('completes on success', () async {
      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => _res({'message': 'removed'}));

      await expectLater(
        sut.removeTrackFromPlaylist(
          playlistId: 'pl-1',
          trackId: 'trk-1',
          accessToken: _token,
        ),
        completes,
      );
    });

    test('throws readable error on 500', () async {
      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(_dioErr(statusCode: 500));

      expect(
        () => sut.removeTrackFromPlaylist(
          playlistId: 'pl-1',
          trackId: 'trk-1',
          accessToken: _token,
        ),
        throwsA(predicate<Exception>((e) => e.toString().contains('Server error'))),
      );
    });
  });
}
