import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/album.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  final albumJson = {
    'album_id': 'album-1',
    'title': 'Test Album',
    'artist': 'Test Artist',
    'cover_photo_url': 'https://example.com/cover.jpg',
    'track_count': 5,
    'release_date': '2024-01-15',
    'like_count': 42,
  };

  group('Album.fromJson', () {
    test('parses all fields correctly', () {
      final album = Album.fromJson(albumJson);

      expect(album.id, 'album-1');
      expect(album.title, 'Test Album');
      expect(album.artist, 'Test Artist');
      expect(album.trackCount, 5);
      expect(album.releaseYear, 2024);
      expect(album.likeCount, 42);
    });

    test('defaults missing fields', () {
      final album = Album.fromJson({});

      expect(album.id, '');
      expect(album.title, 'Untitled Album');
      expect(album.artist, 'Unknown Artist');
      expect(album.artworkUrl, '');
      expect(album.trackCount, 0);
      expect(album.releaseYear, 0);
      expect(album.likeCount, 0);
    });

    test('parses id from either album_id or id field', () {
      final json1 = {...albumJson, 'album_id': 'album-1'};
      final json2 = {'id': 'album-2', 'title': 'Album 2', 'artist': 'Artist'};

      final album1 = Album.fromJson(json1);
      final album2 = Album.fromJson(json2);

      expect(album1.id, 'album-1');
      expect(album2.id, 'album-2');
    });

    test('extracts release year from release_date', () {
      final json = {...albumJson, 'release_date': '2023-06-15'};

      final album = Album.fromJson(json);

      expect(album.releaseYear, 2023);
    });

    test('handles tracks list', () {
      final json = {
        ...albumJson,
        'tracks': [
          {'track_id': 'track-1', 'title': 'Song 1', 'artist': 'Artist', 'duration_seconds': 180},
          {'track_id': 'track-2', 'title': 'Song 2', 'artist': 'Artist', 'duration_seconds': 240},
        ],
      };

      final album = Album.fromJson(json);

      expect(album.tracks.length, 2);
      expect(album.tracks[0].title, 'Song 1');
    });

    test('parses artwork from multiple possible fields', () {
      final json1 = {...albumJson, 'cover_photo_url': 'https://example.com/photo.jpg'};
      final json2 = {
        ...albumJson,
        'cover_photo_url': null,
        'cover_image_url': 'https://example.com/image.jpg'
      };
      final json3 = {
        ...albumJson,
        'cover_photo_url': null,
        'cover_image_url': null,
        'artwork_url': 'https://example.com/artwork.jpg'
      };

      final album1 = Album.fromJson(json1);
      final album2 = Album.fromJson(json2);
      final album3 = Album.fromJson(json3);

      expect(album1.artworkUrl, 'https://example.com/photo.jpg');
      expect(album2.artworkUrl, 'https://example.com/image.jpg');
      expect(album3.artworkUrl, 'https://example.com/artwork.jpg');
    });
  });
}
