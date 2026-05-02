import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/album_service.dart';

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
  late AlbumService sut;

  setUp(() {
    mockDio = MockDio();
    sut = AlbumService(dio: mockDio);
  });

  // ── Get Liked Albums ──────────────────────────────────────────────────────

  group('AlbumService.getLikedAlbums', () {
    test('returns list of liked albums', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => _res({
          'data': [
            {'album_id': 'album-1', 'title': 'Album 1', 'artist': 'Artist 1'},
          ],
        }),
      );

      final albums = await sut.getLikedAlbums('token-123');

      expect(albums.length, 1);
    });

    test('returns empty list when no liked albums', () async {
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({'data': []}));

      final albums = await sut.getLikedAlbums('token-123');

      expect(albums, []);
    });

    test('throws exception on API error', () async {
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.getLikedAlbums('invalid-token'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── Get Album by ID ───────────────────────────────────────────────────────

  // ── Create Album ─────────────────────────────────────────────────────────

  group('AlbumService.createAlbum', () {
    test('creates album and returns details', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'album_id': 'album-1', 'title': 'New Album'},
        }),
      );

      final album = await sut.createAlbum(
        title: 'New Album',
        description: 'Description',
        accessToken: 'token',
      );

      expect(album.id, 'album-1');
    });
  });

  // ── Update Album ──────────────────────────────────────────────────────────

  group('AlbumService.updateAlbum', () {
    test('updates album', () async {
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'album_id': 'album-1', 'title': 'Updated Album'},
        }),
      );

      final album = await sut.updateAlbum(
        albumId: 'album-1',
        title: 'Updated Album',
        accessToken: 'token',
      );

      expect(album.id, 'album-1');
    });
  });

  // ── Delete Album ──────────────────────────────────────────────────────────

  group('AlbumService.deleteAlbum', () {
    test('deletes album', () async {
      when(
        () => mockDio.delete(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.deleteAlbum(albumId: 'album-1', accessToken: 'token'),
        completes,
      );
    });
  });

  // ── Like Album ────────────────────────────────────────────────────────────

  group('AlbumService.likeAlbum', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.likeAlbum(albumId: 'album-1', accessToken: 'token'),
        completes,
      );
    });

    test('throws exception on failure', () async {
      when(
        () => mockDio.post(any(), options: any(named: 'options')),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.likeAlbum(albumId: 'album-1', accessToken: 'invalid'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── Unlike Album ──────────────────────────────────────────────────────────

  group('AlbumService.unlikeAlbum', () {
    test('completes on success', () async {
      when(
        () => mockDio.delete(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.unlikeAlbum(albumId: 'album-1', accessToken: 'token'),
        completes,
      );
    });
  });
}
