import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/playlist.dart';
import 'package:my_project/providers/create_playlist_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CreatePlaylistState', () {
    test('initial state is empty', () {
      const state = CreatePlaylistState();

      expect(state.isLoading, false);
      expect(state.createdPlaylist, isNull);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('can create state with playlist', () {
      final playlist = Playlist(
        id: 'pl-1',
        userId: 'user-1',
        name: 'Test Playlist',
        description: 'A test playlist',
        coverUrl: 'https://example.com/cover.jpg',
        isPublic: true,
        trackCount: 0,
        tracks: const [],
      );

      final state = CreatePlaylistState(createdPlaylist: playlist);

      expect(state.createdPlaylist, playlist);
      expect(state.isLoading, false);
    });

    test('can create state with error', () {
      const state = CreatePlaylistState(error: 'Some error');

      expect(state.error, 'Some error');
      expect(state.createdPlaylist, isNull);
    });

    test('can create state with success message', () {
      const state = CreatePlaylistState(successMessage: 'Created!');

      expect(state.successMessage, 'Created!');
    });
  });
}
