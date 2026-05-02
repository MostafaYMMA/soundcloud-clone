import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/engagement_service.dart';

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
  late EngagementService sut;

  setUp(() {
    mockDio = MockDio();
    sut = EngagementService(dio: mockDio);
  });

  // ── Like Track ─────────────────────────────────────────────────────────────

  group('EngagementService.likeTrack', () {
    test('completes on success', () async {
      when(() => mockDio.post(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.likeTrack(trackId: 'track-1'), completes);
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.post(any())).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.likeTrack(trackId: 'track-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Unlike Track ───────────────────────────────────────────────────────────

  group('EngagementService.unlikeTrack', () {
    test('completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.unlikeTrack(trackId: 'track-1'), completes);
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.delete(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.unlikeTrack(trackId: 'track-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Like Playlist ─────────────────────────────────────────────────────────

  group('EngagementService.likePlaylist', () {
    test('completes on success', () async {
      when(() => mockDio.post(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.likePlaylist(playlistId: 'playlist-1'), completes);
    });
  });

  // ── Unlike Playlist ────────────────────────────────────────────────────────

  group('EngagementService.unlikePlaylist', () {
    test('completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.unlikePlaylist(playlistId: 'playlist-1'),
        completes,
      );
    });
  });

  // ── Get Liked Playlists ────────────────────────────────────────────────────

  group('EngagementService.getLikedPlaylists', () {
    test('returns list of liked playlists', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({'data': [{'id': 'playlist-1', 'name': 'Liked'}]}),
      );

      final playlists = await sut.getLikedPlaylists();

      expect(playlists.length, 1);
    });

    test('returns empty list when no liked playlists', () async {
      when(() => mockDio.get(any())).thenAnswer((_) async => _res({}));

      final playlists = await sut.getLikedPlaylists();

      expect(playlists, []);
    });
  });

  // ── Get Comments ───────────────────────────────────────────────────────────

  group('EngagementService.getComments', () {
    test('placeholder', () async {
      expect(true, true);
    });
  });

  // ── Add Comment ────────────────────────────────────────────────────────────

  group('EngagementService.addComment', () {
    test('adds comment to track', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.addComment(trackId: 'track-1', content: 'Nice!'),
        completes,
      );
    });

    test('adds comment with timestamp', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.addComment(
          trackId: 'track-1',
          content: 'Nice!',
          timestampInTrack: 30,
        ),
        completes,
      );
    });

    test('adds reply comment', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.addComment(
          trackId: 'track-1',
          content: 'Reply!',
          parentCommentId: 'comment-1',
        ),
        completes,
      );
    });
  });

  // ── Playlist Management ────────────────────────────────────────────────────

  group('EngagementService playlist methods', () {
    test('createPlaylist returns playlist data', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            _res({'data': {'id': 'playlist-1', 'name': 'New Playlist'}}),
      );

      final result =
          await sut.createPlaylist(name: 'New Playlist');

      expect(result['id'], 'playlist-1');
    });

    test('getPlaylist returns playlist data', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({'data': {'id': 'playlist-1', 'name': 'My Playlist'}}),
      );

      final result = await sut.getPlaylist(playlistId: 'playlist-1');

      expect(result['id'], 'playlist-1');
    });

    test('updatePlaylist completes on success', () async {
      when(() => mockDio.patch(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _res({}));

      await expectLater(
        sut.updatePlaylist(
          playlistId: 'playlist-1',
          name: 'Updated',
        ),
        completes,
      );
    });

    test('deletePlaylist completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.deletePlaylist(playlistId: 'playlist-1'),
        completes,
      );
    });

    test('addTrackToPlaylist completes on success', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _res({}));

      await expectLater(
        sut.addTrackToPlaylist(
          playlistId: 'playlist-1',
          trackId: 'track-1',
        ),
        completes,
      );
    });

    test('removeTrackFromPlaylist completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.removeTrackFromPlaylist(
          playlistId: 'playlist-1',
          trackId: 'track-1',
        ),
        completes,
      );
    });
  });
}
