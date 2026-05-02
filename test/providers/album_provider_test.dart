import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/album.dart';
import 'package:my_project/providers/album_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('AlbumState', () {
    test('initial state is empty', () {
      const state = AlbumState();

      expect(state.likedAlbums, []);
      expect(state.isLoadingLiked, false);
      expect(state.isWorking, false);
      expect(state.error, isNull);
    });

    test('copyWith preserves fields when nothing updated', () {
      final state = const AlbumState(
        likedAlbums: [],
        isLoadingLiked: false,
      );

      final updated = state.copyWith();

      expect(updated.likedAlbums, state.likedAlbums);
      expect(updated.isLoadingLiked, state.isLoadingLiked);
    });

    test('copyWith updates individual fields', () {
      final album = Album(
        id: 'album-1',
        title: 'Test Album',
        artist: 'Test Artist',
        artworkUrl: 'https://example.com/art.jpg',
        trackCount: 10,
        releaseYear: 2024,
        likeCount: 5,
      );

      final state = const AlbumState(likedAlbums: []);
      final updated = state.copyWith(likedAlbums: [album]);

      expect(updated.likedAlbums, [album]);
      expect(updated.isLoadingLiked, false);
    });

    test('copyWith clearError removes error when flag is true', () {
      const state = AlbumState(error: 'Some error');

      final updated = state.copyWith(clearError: true);

      expect(updated.error, isNull);
    });

    test('copyWith preserves error when clearError is false', () {
      const state = AlbumState(error: 'Some error');

      final updated = state.copyWith(clearError: false);

      expect(updated.error, 'Some error');
    });

    test('copyWith updates isLoading flag', () {
      const state = AlbumState(isLoadingLiked: false);

      final updated = state.copyWith(isLoadingLiked: true);

      expect(updated.isLoadingLiked, true);
    });

    test('copyWith updates isWorking flag', () {
      const state = AlbumState(isWorking: false);

      final updated = state.copyWith(isWorking: true);

      expect(updated.isWorking, true);
    });

    test('copyWith updates multiple fields at once', () {
      final album = Album(
        id: 'album-1',
        title: 'Test Album',
        artist: 'Test Artist',
        artworkUrl: 'https://example.com/art.jpg',
        trackCount: 10,
        releaseYear: 2024,
        likeCount: 5,
      );

      const state = AlbumState();

      final updated = state.copyWith(
        likedAlbums: [album],
        isLoadingLiked: true,
        isWorking: true,
        error: 'Test error',
      );

      expect(updated.likedAlbums, [album]);
      expect(updated.isLoadingLiked, true);
      expect(updated.isWorking, true);
      expect(updated.error, 'Test error');
    });
  });
}
