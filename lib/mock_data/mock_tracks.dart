import '../models/track.dart';
import '../models/recently_played_item.dart';
import '../models/playlist.dart';
import '../models/album.dart';

class MockTracks {
  static const List<Track> likedTracks = [
    Track(
      id: '1',
      title: 'God\'s Plan',
      artist: 'Drake',
      artworkUrl: 'https://picsum.photos/seed/track1/150/150',
      likeCount: 142000,
      duration: 198,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '2',
      title: 'HUMBLE.',
      artist: 'Kendrick Lamar',
      artworkUrl: 'https://picsum.photos/seed/track2/150/150',
      likeCount: 98700,
      duration: 177,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '3',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      artworkUrl: 'https://picsum.photos/seed/track3/150/150',
      likeCount: 210500,
      duration: 200,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '4',
      title: 'SICKO MODE',
      artist: 'Travis Scott',
      artworkUrl: 'https://picsum.photos/seed/track4/150/150',
      likeCount: 187300,
      duration: 312,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
  ];

  static const Track hotTrack = Track(
    id: '5',
    title: 'luther',
    artist: 'Kendrick Lamar ft. SZA',
    artworkUrl: 'https://picsum.photos/seed/track5/150/150',
    likeCount: 82000,
    duration: 228,
    audioPath:
        'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
  );

  static const List<Track> recommendedTracks = [
    Track(
      id: '6',
      title: 'fukumean',
      artist: 'Gunna',
      artworkUrl: 'https://picsum.photos/seed/track6/150/150',
      likeCount: 54000,
      duration: 149,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '7',
      title: 'Rich Flex',
      artist: 'Drake & 21 Savage',
      artworkUrl: 'https://picsum.photos/seed/track7/150/150',
      likeCount: 76800,
      duration: 231,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '8',
      title: 'Mask Off',
      artist: 'Future',
      artworkUrl: 'https://picsum.photos/seed/track8/150/150',
      likeCount: 43200,
      duration: 183,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '9',
      title: 'ROCKSTAR',
      artist: 'DaBaby ft. Roddy Ricch',
      artworkUrl: 'https://picsum.photos/seed/track9/150/150',
      likeCount: 91500,
      duration: 178,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
  ];

  static const List<Track> historyTracks = [
    Track(
      id: '4',
      title: 'SICKO MODE',
      artist: 'Travis Scott',
      artworkUrl: 'https://picsum.photos/seed/track4/150/150',
      likeCount: 187300,
      duration: 312,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '9',
      title: 'ROCKSTAR',
      artist: 'DaBaby ft. Roddy Ricch',
      artworkUrl: 'https://picsum.photos/seed/track9/150/150',
      likeCount: 91500,
      duration: 178,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '2',
      title: 'HUMBLE.',
      artist: 'Kendrick Lamar',
      artworkUrl: 'https://picsum.photos/seed/track2/150/150',
      likeCount: 98700,
      duration: 177,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '1',
      title: 'God\'s Plan',
      artist: 'Drake',
      artworkUrl: 'https://picsum.photos/seed/track1/150/150',
      likeCount: 142000,
      duration: 198,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
  ];

  static const List<Track> recentlyPlayedTracks = [
    Track(
      id: '8',
      title: 'Mask Off',
      artist: 'Future',
      artworkUrl: 'https://picsum.photos/seed/track8/150/150',
      likeCount: 43200,
      duration: 183,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '3',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      artworkUrl: 'https://picsum.photos/seed/track3/150/150',
      likeCount: 210500,
      duration: 200,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
    Track(
      id: '9',
      title: 'ROCKSTAR',
      artist: 'DaBaby ft. Roddy Ricch',
      artworkUrl: 'https://picsum.photos/seed/track9/150/150',
      likeCount: 91500,
      duration: 178,
      audioPath:
          'assets/audio/tadashikeiji-gods-got-my-love-life-handled-319926.mp3',
    ),
  ];

  static List<RecentlyPlayedItem> get recentlyPlayedItems => [
    RecentlyPlayedPlaylist(
      Playlist(
        id: 'p1',
        userId: 'THRILLHO',
        name: 'Somatic  -  Deep Bass  -  Brain Massage',
        description: '',
        coverUrl: '',
        isPublic: true,
        trackCount: 23,
        tracks: [],
      ),
    ),
    RecentlyPlayedAlbum(
      Album(
        id: 'a1',
        title: 'Lana Del Rey - ULTRAVIOLENCE',
        artist: 'Interscope Records',
        releaseYear: 2014,
        artworkUrl: '',
        trackCount: 0,
        likeCount: 0,
      ),
    ),
    RecentlyPlayedPlaylist(
      Playlist(
        id: 'p2',
        userId: 'Hana_Ahmed',
        name: 'kennedy walsh jams',
        description: '',
        coverUrl: '',
        isPublic: true,
        trackCount: 112,
        tracks: [],
      ),
    ),
    RecentlyPlayedPlaylist(
      Playlist(
        id: 'p3',
        userId: 'New!',
        name: 'Buzzing Indie',
        description: '',
        coverUrl: '',
        isPublic: true,
        trackCount: 25,
        tracks: [],
      ),
    ),
    RecentlyPlayedPlaylist(
      Playlist(
        id: 'p4',
        userId: 'SoundCloud',
        name: 'Your Mix 1',
        description: '',
        coverUrl: '',
        isPublic: false,
        trackCount: 0,
        tracks: [],
      ),
    ),
  ];
}
