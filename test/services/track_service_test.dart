import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/track_service.dart';

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

final _trackData = {
  'track_id': 'trk-1',
  'title': 'Track One',
  'description': 'desc',
  'genre': 'Pop',
  'tags': [],
  'release_date': null,
  'cover_image_url': null,
  'stream_url': 'https://example.com/stream',
  'user_id': 'u-1',
  'artist': null,
  'visibility': 'public',
  'processing_status': 'done',
  'play_count': 10,
  'duration_seconds': 180,
  'like_count': 5,
  'repost_count': 0,
  'comment_count': 1,
  'is_liked': false,
  'is_reposted': false,
  'created_at': '2024-01-01T00:00:00.000Z',
};

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  late MockDio mockDio;
  late TracksService sut;

  setUp(() {
    mockDio = MockDio();
    sut = TracksService(dio: mockDio);
  });

  // ── getTrack ──────────────────────────────────────────────────────────────

  group('TracksService.getTrack', () {
    test('returns Track on success', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': _trackData}));

      final track = await sut.getTrack(trackId: 'trk-1');
      expect(track.trackId, 'trk-1');
      expect(track.title, 'Track One');
    });

    test('propagates DioException on 404', () async {
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
        () => sut.getTrack(trackId: 'missing'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── updateTrack ───────────────────────────────────────────────────────────

  group('TracksService.updateTrack', () {
    test('returns updated Track on success', () async {
      final updatedData = Map<String, dynamic>.from(_trackData)
        ..['title'] = 'Updated';

      when(
        () => mockDio.put(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': updatedData}));

      final track = await sut.updateTrack(trackId: 'trk-1', title: 'Updated');
      expect(track.title, 'Updated');
    });

    test('propagates DioException on failure', () async {
      when(
        () => mockDio.put(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 403));

      expect(
        () => sut.updateTrack(trackId: 'trk-1', title: 'X'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── deleteTrack ───────────────────────────────────────────────────────────

  group('TracksService.deleteTrack', () {
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

      await expectLater(sut.deleteTrack(trackId: 'trk-1'), completes);
    });

    test('propagates DioException on 403', () async {
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
        () => sut.deleteTrack(trackId: 'trk-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── searchTracks ──────────────────────────────────────────────────────────

  group('TracksService.searchTracks', () {
    test('returns list of Tracks on success', () async {
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
          'data': {
            'tracks': [_trackData],
          },
        }),
      );

      final tracks = await sut.searchTracks(keyword: 'pop');
      expect(tracks, hasLength(1));
      expect(tracks.first.trackId, 'trk-1');
    });

    test('returns empty list when tracks key is absent', () async {
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
          'data': {'tracks': null},
        }),
      );

      final tracks = await sut.searchTracks(keyword: 'notfound');
      expect(tracks, isEmpty);
    });

    test('propagates DioException on server error', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 500));

      expect(
        () => sut.searchTracks(keyword: 'test'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── getUserTracks ─────────────────────────────────────────────────────────

  group('TracksService.getUserTracks', () {
    test('returns list of user Tracks', () async {
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
          'data': {
            'tracks': [_trackData, _trackData],
          },
        }),
      );

      final tracks = await sut.getUserTracks(username: 'rockstar');
      expect(tracks, hasLength(2));
    });

    test('returns empty list when tracks is null', () async {
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
          'data': {'tracks': null},
        }),
      );

      final tracks = await sut.getUserTracks(username: 'noone');
      expect(tracks, isEmpty);
    });
  });

  // ── getUserLikedTracks ────────────────────────────────────────────────────

  group('TracksService.getUserLikedTracks', () {
    test('returns liked tracks list', () async {
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
          'data': {
            'tracks': [_trackData],
          },
        }),
      );

      final tracks = await sut.getUserLikedTracks(username: 'user1');
      expect(tracks, hasLength(1));
    });
  });

  // ── getFollowingFeed ──────────────────────────────────────────────────────

  group('TracksService.getFollowingFeed', () {
    test('returns feed data map', () async {
      final feedData = {
        'items': [_trackData],
        'next_cursor': 'cursor123',
        'has_more': true,
      };

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'data': feedData}));

      final result = await sut.getFollowingFeed(limit: 20);
      expect(result['items'], hasLength(1));
      expect(result['has_more'], isTrue);
      expect(result['next_cursor'], 'cursor123');
    });

    test('returns empty feed data on no items', () async {
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
          'data': {'items': [], 'has_more': false},
        }),
      );

      final result = await sut.getFollowingFeed();
      expect(result['items'], isEmpty);
    });
  });

  // ── getDiscoverFeed ───────────────────────────────────────────────────────

  group('TracksService.getDiscoverFeed', () {
    test('returns discover feed data map', () async {
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
          'data': {
            'items': [_trackData],
            'has_more': false,
          },
        }),
      );

      final result = await sut.getDiscoverFeed(limit: 20);
      expect(result['items'], hasLength(1));
      expect(result['has_more'], isFalse);
    });
  });

  // ── recordPlay ────────────────────────────────────────────────────────────

  group('TracksService.recordPlay', () {
    test('completes without duration', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'ok'}));

      await expectLater(sut.recordPlay(trackId: 'trk-1'), completes);
    });

    test('completes with duration', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'ok'}));

      await expectLater(
        sut.recordPlay(trackId: 'trk-1', durationListenedSeconds: 120),
        completes,
      );
    });
  });

  // ── likeTrack / unlikeTrack ───────────────────────────────────────────────

  group('TracksService.likeTrack', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'liked'}));

      await expectLater(sut.likeTrack(trackId: 'trk-1'), completes);
    });

    test('propagates DioException on unauthorized', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.likeTrack(trackId: 'trk-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('TracksService.unlikeTrack', () {
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

      await expectLater(sut.unlikeTrack(trackId: 'trk-1'), completes);
    });
  });

  // ── getTrackAudioUrl ──────────────────────────────────────────────────────

  group('TracksService.getTrackAudioUrl', () {
    test('returns correct URL for given trackId', () {
      const id = 'trk-99';
      final url = sut.getTrackAudioUrl(trackId: id);
      expect(url, contains(id));
      expect(url, contains('audio'));
    });
  });

  // ── getTrackWaveform ──────────────────────────────────────────────────────

  group('TracksService.getTrackWaveform', () {
    test('returns waveform map on success', () async {
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
          'data': {
            'peaks': [0.5, 0.8, 0.3],
            'duration_seconds': 180,
          },
        }),
      );

      final result = await sut.getTrackWaveform(trackId: 'trk-1');
      expect(result['peaks'], isA<List>());
      expect((result['peaks'] as List).length, 3);
    });
  });
}
