import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/playlist.dart';

void main() {
  // ── PlaylistTrack ─────────────────────────────────────────────────────────

  group('PlaylistTrack.fromJson', () {
    test('parses all fields with track_id key', () {
      final track = PlaylistTrack.fromJson({
        'track_id': 'tid-1',
        'title': 'Song One',
        'artist_name': 'The Artist',
        'cover_image_url': 'https://example.com/cover.jpg',
        'duration_seconds': 180,
      });
      expect(track.id, 'tid-1');
      expect(track.title, 'Song One');
      expect(track.artist, 'The Artist');
      expect(track.artworkUrl, 'https://example.com/cover.jpg');
      expect(track.durationSeconds, 180);
    });

    test('falls back to id key when track_id is absent', () {
      final track = PlaylistTrack.fromJson({
        'id': 'alt-id',
        'title': 'Alt Song',
        'artist': 'Artist Two',
        'artwork_url': 'https://example.com/art.jpg',
        'duration_seconds': 200,
      });
      expect(track.id, 'alt-id');
      expect(track.artist, 'Artist Two');
      expect(track.artworkUrl, 'https://example.com/art.jpg');
    });

    test('prepends base URL for relative cover_image_url', () {
      final track = PlaylistTrack.fromJson({
        'track_id': 't1',
        'title': 'T',
        'artist_name': 'A',
        'cover_image_url': '/media/cover.jpg',
        'duration_seconds': 0,
      });
      expect(track.artworkUrl, 'https://streamline-swp.duckdns.org/media/cover.jpg');
    });

    test('returns empty string for null artwork url', () {
      final track = PlaylistTrack.fromJson({
        'track_id': 't1',
        'title': 'T',
        'artist_name': 'A',
        'duration_seconds': 0,
      });
      expect(track.artworkUrl, '');
    });

    test('defaults title to Untitled Track when missing', () {
      final track = PlaylistTrack.fromJson({'track_id': 't1', 'duration_seconds': 0});
      expect(track.title, 'Untitled Track');
    });

    test('defaults artist to Unknown Artist when missing', () {
      final track = PlaylistTrack.fromJson({'track_id': 't1', 'duration_seconds': 0});
      expect(track.artist, 'Unknown Artist');
    });

    test('parses duration_seconds as string', () {
      final track = PlaylistTrack.fromJson({
        'track_id': 't1',
        'title': 'T',
        'artist_name': 'A',
        'duration_seconds': '210',
      });
      expect(track.durationSeconds, 210);
    });

    test('defaults duration to 0 for invalid string', () {
      final track = PlaylistTrack.fromJson({
        'track_id': 't1',
        'title': 'T',
        'artist_name': 'A',
        'duration_seconds': 'invalid',
      });
      expect(track.durationSeconds, 0);
    });
  });

  // ── Playlist ──────────────────────────────────────────────────────────────

  group('Playlist.fromJson', () {
    final playlistJson = {
      'playlist_id': 'pl-1',
      'user_id': 'u-1',
      'name': 'My Playlist',
      'description': 'A great playlist',
      'cover_photo_url': 'https://example.com/pl.jpg',
      'is_public': true,
      'track_count': 2,
      'tracks': [
        {
          'track_id': 't1',
          'title': 'Song A',
          'artist_name': 'Artist A',
          'cover_image_url': '',
          'duration_seconds': 120,
        },
        {
          'track_id': 't2',
          'title': 'Song B',
          'artist_name': 'Artist B',
          'cover_image_url': '',
          'duration_seconds': 200,
        },
      ],
    };

    test('parses all fields correctly', () {
      final playlist = Playlist.fromJson(playlistJson);
      expect(playlist.id, 'pl-1');
      expect(playlist.userId, 'u-1');
      expect(playlist.name, 'My Playlist');
      expect(playlist.description, 'A great playlist');
      expect(playlist.isPublic, isTrue);
      expect(playlist.trackCount, 2);
    });

    test('parses tracks list', () {
      final playlist = Playlist.fromJson(playlistJson);
      expect(playlist.tracks, hasLength(2));
      expect(playlist.tracks.first.id, 't1');
      expect(playlist.tracks.last.id, 't2');
    });

    test('handles null tracks by returning empty list', () {
      final json = Map<String, dynamic>.from(playlistJson)..remove('tracks');
      final playlist = Playlist.fromJson(json);
      expect(playlist.tracks, isEmpty);
    });

    test('falls back to id key when playlist_id is absent', () {
      final json = Map<String, dynamic>.from(playlistJson)
        ..remove('playlist_id')
        ..['id'] = 'alt-pl';
      final playlist = Playlist.fromJson(json);
      expect(playlist.id, 'alt-pl');
    });

    test('falls back to cover_url key when cover_photo_url is absent', () {
      final json = Map<String, dynamic>.from(playlistJson)
        ..remove('cover_photo_url')
        ..['cover_url'] = 'https://example.com/alt.jpg';
      final playlist = Playlist.fromJson(json);
      expect(playlist.coverUrl, 'https://example.com/alt.jpg');
    });

    test('prepends base URL for relative cover_photo_url', () {
      final json = Map<String, dynamic>.from(playlistJson)
        ..['cover_photo_url'] = '/media/playlist_cover.jpg';
      final playlist = Playlist.fromJson(json);
      expect(playlist.coverUrl, 'https://streamline-swp.duckdns.org/media/playlist_cover.jpg');
    });

    test('is_public defaults to false when absent', () {
      final json = Map<String, dynamic>.from(playlistJson)..remove('is_public');
      final playlist = Playlist.fromJson(json);
      expect(playlist.isPublic, isFalse);
    });

    test('defaults name to Untitled playlist when missing', () {
      final playlist = Playlist.fromJson({});
      expect(playlist.name, 'Untitled playlist');
    });

    test('trackCount falls back to tracks.length when track_count is absent', () {
      final json = Map<String, dynamic>.from(playlistJson)..remove('track_count');
      final playlist = Playlist.fromJson(json);
      expect(playlist.trackCount, 2);
    });

    test('owner getter returns constant string', () {
      final playlist = Playlist.fromJson(playlistJson);
      expect(playlist.owner, 'Playlist owner');
    });

    test('skips non-map entries in tracks list gracefully', () {
      final json = Map<String, dynamic>.from(playlistJson)
        ..['tracks'] = ['invalid_entry', null, {'track_id': 't3', 'title': 'C', 'artist_name': 'A', 'duration_seconds': 0}];
      // whereType<Map<String, dynamic>> filters out non-maps
      final playlist = Playlist.fromJson(json);
      expect(playlist.tracks, hasLength(1));
    });
  });
}
