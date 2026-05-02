class AlbumTrack {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int durationSeconds;

  const AlbumTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.durationSeconds,
  });

  static String _fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'https://streamline-swp.duckdns.org$url';
    return url;
  }

  factory AlbumTrack.fromJson(Map<String, dynamic> json) {
    return AlbumTrack(
      id: json['track_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Track',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      artworkUrl: _fixMediaUrl(json['cover_image_url']?.toString()),
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds']
          : int.tryParse(json['duration_seconds']?.toString() ?? '') ?? 0,
    );
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int trackCount;
  final int releaseYear;
  final int likeCount;
  final List<String> trackIds;
  final List<AlbumTrack> tracks; // ← added

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.trackCount,
    required this.releaseYear,
    required this.likeCount,
    this.trackIds = const [],
    this.tracks = const [], // ← added
  });

  static String _fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'https://streamline-swp.duckdns.org$url';
    return url;
  }

  factory Album.fromJson(Map<String, dynamic> json) {
  // Detail endpoint uses release_date, search endpoint uses year
  int releaseYear = 0;
  if (json['year'] != null) {
    releaseYear = json['year'] is int
        ? json['year']
        : int.tryParse(json['year'].toString()) ?? 0;
  } else {
    final rawDate = json['release_date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      releaseYear = int.tryParse(rawDate.split('-').first) ?? 0;
    }
  }

  final tracksRaw = json['tracks'];
  final tracks = tracksRaw is List
      ? tracksRaw
          .whereType<Map<String, dynamic>>()
          .map(AlbumTrack.fromJson)
          .toList()
      : <AlbumTrack>[];

  return Album(
    id: json['album_id']?.toString() ?? json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Untitled Album',
    // search uses artist_name, detail uses artist/display_name
    artist: json['artist_name']?.toString() ??
        json['artist']?.toString() ??
        json['display_name']?.toString() ??
        'Unknown Artist',
    artworkUrl: _fixMediaUrl(
      json['cover_photo_url']?.toString() ??
          json['cover_image_url']?.toString() ??
          json['artwork_url']?.toString(),
    ),
    trackCount: json['track_count'] is int
        ? json['track_count']
        : int.tryParse(json['track_count']?.toString() ?? '') ?? 0,
    releaseYear: releaseYear,
    likeCount: json['like_count'] is int
        ? json['like_count']
        : int.tryParse(json['like_count']?.toString() ?? '') ?? 0,
    trackIds:
        (json['track_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
    tracks: tracks,
  );
}
}
