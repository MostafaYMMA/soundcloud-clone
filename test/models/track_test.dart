import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/track.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  // ── Fixtures ──────────────────────────────────────────────────────────────

  final fullTrackJson = {
    'track_id': 'track-1',
    'title': 'Test Song',
    'description': 'A test description',
    'genre': 'Rock',
    'tags': ['rock', 'test'],
    'release_date': '2024-01-01',
    'cover_image_url': 'https://example.com/cover.jpg',
    'stream_url': 'https://example.com/stream',
    'user_id': 'user-1',
    'artist': {
      'user_id': 'artist-1',
      'username': 'rockstar',
      'display_name': 'Rock Star',
      'profile_picture': 'https://example.com/pic.jpg',
      'follower_count': 1000,
    },
    'visibility': 'public',
    'processing_status': 'done',
    'play_count': 500,
    'duration_seconds': 240,
    'like_count': 50,
    'repost_count': 10,
    'comment_count': 5,
    'is_liked': true,
    'is_reposted': false,
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  // ── TrackArtist ───────────────────────────────────────────────────────────

  group('TrackArtist.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'user_id': 'a1',
        'username': 'testuser',
        'display_name': 'Test User',
        'profile_picture': 'https://example.com/pic.jpg',
        'follower_count': 500,
      };
      final artist = TrackArtist.fromJson(json);
      expect(artist.userId, 'a1');
      expect(artist.username, 'testuser');
      expect(artist.displayName, 'Test User');
      expect(artist.profilePicture, 'https://example.com/pic.jpg');
      expect(artist.followerCount, 500);
    });

    test('defaults missing fields to empty string or zero', () {
      final artist = TrackArtist.fromJson({});
      expect(artist.userId, '');
      expect(artist.username, '');
      expect(artist.displayName, '');
      expect(artist.profilePicture, isNull);
      expect(artist.followerCount, 0);
    });

    test('profilePicture is null when missing', () {
      final artist = TrackArtist.fromJson({'user_id': 'u1', 'username': 'u', 'display_name': 'd', 'follower_count': 0});
      expect(artist.profilePicture, isNull);
    });
  });

  // ── Track.fromJson ────────────────────────────────────────────────────────

  group('Track.fromJson', () {
    test('parses full track with artist', () {
      final track = Track.fromJson(fullTrackJson);

      expect(track.trackId, 'track-1');
      expect(track.title, 'Test Song');
      expect(track.description, 'A test description');
      expect(track.genre, 'Rock');
      expect(track.tags, ['rock', 'test']);
      expect(track.releaseDate, '2024-01-01');
      expect(track.coverImageUrl, 'https://example.com/cover.jpg');
      expect(track.streamUrl, 'https://example.com/stream');
      expect(track.userId, 'user-1');
      expect(track.visibility, 'public');
      expect(track.processingStatus, 'done');
      expect(track.playCount, 500);
      expect(track.durationSeconds, 240);
      expect(track.likeCount, 50);
      expect(track.repostCount, 10);
      expect(track.commentCount, 5);
      expect(track.isLiked, isTrue);
      expect(track.isReposted, isFalse);
      expect(track.createdAt, isNotNull);
    });

    test('parses artist sub-object', () {
      final track = Track.fromJson(fullTrackJson);
      expect(track.artist, isNotNull);
      expect(track.artist!.username, 'rockstar');
      expect(track.artist!.displayName, 'Rock Star');
      expect(track.artist!.followerCount, 1000);
    });

    test('artist is null when missing from json', () {
      final json = Map<String, dynamic>.from(fullTrackJson)..remove('artist');
      final track = Track.fromJson(json);
      expect(track.artist, isNull);
    });

    test('defaults missing required fields', () {
      final track = Track.fromJson({});
      expect(track.trackId, '');
      expect(track.title, '');
      expect(track.streamUrl, '');
      expect(track.visibility, 'public');
      expect(track.processingStatus, '');
      expect(track.playCount, 0);
    });

    test('nullable fields are null when missing', () {
      final track = Track.fromJson({});
      expect(track.description, isNull);
      expect(track.genre, isNull);
      expect(track.tags, isNull);
      expect(track.coverImageUrl, isNull);
      expect(track.userId, isNull);
      expect(track.artist, isNull);
      expect(track.durationSeconds, isNull);
      expect(track.likeCount, isNull);
      expect(track.repostCount, isNull);
      expect(track.commentCount, isNull);
      expect(track.isLiked, isNull);
      expect(track.isReposted, isNull);
      expect(track.createdAt, isNull);
    });

    test('parses createdAt as DateTime', () {
      final track = Track.fromJson({'created_at': '2024-06-15T12:00:00.000Z'});
      expect(track.createdAt, isA<DateTime>());
      expect(track.createdAt!.year, 2024);
      expect(track.createdAt!.month, 6);
    });

    test('createdAt is null for invalid date string', () {
      final track = Track.fromJson({'created_at': 'not-a-date'});
      expect(track.createdAt, isNull);
    });
  });

  // ── Track computed properties ─────────────────────────────────────────────

  group('Track computed properties', () {
    test('artworkUrl is alias for coverImageUrl', () {
      final track = Track.fromJson(fullTrackJson);
      expect(track.artworkUrl, track.coverImageUrl);
    });

    test('artistName returns artist displayName', () {
      final track = Track.fromJson(fullTrackJson);
      expect(track.artistName, 'Rock Star');
    });

    test('artistName returns empty string when artist is null', () {
      final json = Map<String, dynamic>.from(fullTrackJson)..remove('artist');
      final track = Track.fromJson(json);
      expect(track.artistName, '');
    });

    test('formattedArtist returns artist displayName', () {
      final track = Track.fromJson(fullTrackJson);
      expect(track.formattedArtist, 'Rock Star');
    });

    test('formattedArtist returns Unknown Artist when artist is null', () {
      final json = Map<String, dynamic>.from(fullTrackJson)..remove('artist');
      final track = Track.fromJson(json);
      expect(track.formattedArtist, 'Unknown Artist');
    });
  });

  // ── Track.copyWith ────────────────────────────────────────────────────────

  group('Track.copyWith', () {
    late Track original;

    setUp(() => original = Track.fromJson(fullTrackJson));

    test('updates likeCount', () {
      final updated = original.copyWith(likeCount: 99);
      expect(updated.likeCount, 99);
      expect(updated.trackId, original.trackId);
    });

    test('toggles isLiked', () {
      final unliked = original.copyWith(isLiked: false);
      expect(unliked.isLiked, isFalse);
      expect(unliked.title, original.title);
    });

    test('updates repostCount and isReposted', () {
      final updated = original.copyWith(repostCount: 20, isReposted: true);
      expect(updated.repostCount, 20);
      expect(updated.isReposted, isTrue);
    });

    test('updates coverImageUrl', () {
      final updated = original.copyWith(coverImageUrl: 'https://new.com/img.jpg');
      expect(updated.coverImageUrl, 'https://new.com/img.jpg');
      expect(updated.artworkUrl, 'https://new.com/img.jpg');
    });

    test('preserves all other fields when only one is updated', () {
      final updated = original.copyWith(likeCount: 1);
      expect(updated.trackId, original.trackId);
      expect(updated.title, original.title);
      expect(updated.streamUrl, original.streamUrl);
      expect(updated.playCount, original.playCount);
      expect(updated.visibility, original.visibility);
    });

    test('null copyWith argument preserves original value', () {
      final updated = original.copyWith();
      expect(updated.likeCount, original.likeCount);
      expect(updated.isLiked, original.isLiked);
    });
  });
}
