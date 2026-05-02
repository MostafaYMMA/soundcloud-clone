import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/providers/liked_tracks_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('LikedTracksNotifier', () {
    test('initial state is empty set', () {
      final notifier = LikedTracksNotifier();

      expect(notifier.state, <String>{});
    });

    test('isLiked returns false for non-existent track', () {
      final notifier = LikedTracksNotifier();

      expect(notifier.isLiked('track-1'), false);
    });

    test('toggleLocal adds track to liked set', () {
      final notifier = LikedTracksNotifier();

      notifier.toggleLocal('track-1');

      expect(notifier.state.contains('track-1'), true);
      expect(notifier.isLiked('track-1'), true);
    });

    test('toggleLocal removes track from liked set', () {
      final notifier = LikedTracksNotifier();

      notifier.toggleLocal('track-1');
      notifier.toggleLocal('track-1');

      expect(notifier.state.contains('track-1'), false);
      expect(notifier.isLiked('track-1'), false);
    });

    test('toggleLocal toggles multiple tracks', () {
      final notifier = LikedTracksNotifier();

      notifier.toggleLocal('track-1');
      notifier.toggleLocal('track-2');
      notifier.toggleLocal('track-3');

      expect(notifier.state.length, 3);
      expect(notifier.isLiked('track-1'), true);
      expect(notifier.isLiked('track-2'), true);
      expect(notifier.isLiked('track-3'), true);
    });

    test('setAll replaces entire set', () {
      final notifier = LikedTracksNotifier();

      notifier.toggleLocal('track-1');
      notifier.toggleLocal('track-2');

      final newSet = {'track-5', 'track-6'};
      notifier.setAll(newSet);

      expect(notifier.state, newSet);
      expect(notifier.isLiked('track-1'), false);
      expect(notifier.isLiked('track-5'), true);
    });

    test('setAll with empty set clears all likes', () {
      final notifier = LikedTracksNotifier();

      notifier.toggleLocal('track-1');
      notifier.toggleLocal('track-2');

      notifier.setAll({});

      expect(notifier.state, <String>{});
    });
  });
}
