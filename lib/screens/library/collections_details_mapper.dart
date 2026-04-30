import '../../models/album.dart';
import '../../models/playlist.dart';
import 'collections_screen.dart';

class CollectionDetailsMapper {
  CollectionDetailsMapper._();

  static CollectionDetailsData fromAlbum(Album album) {
    return CollectionDetailsData(
      type: CollectionType.album,
      title: album.title,
      artworkPath: album.artworkUrl,
      ownerName: album.artist,
      ownerAvatarPath: album.artworkUrl,
      yearText: album.releaseYear > 0 ? album.releaseYear.toString() : '',
      likesText: '${album.likeCount} likes',
      tracks: album.tracks
          .map(
            (t) => CollectionTrack(
              id: t.id,
              title: t.title,
              artist: t.artist,
              artworkPath: t.artworkUrl,
              durationSeconds: t.durationSeconds,
            ),
          )
          .toList(),
    );
  }

  static CollectionDetailsData fromPlaylist(Playlist playlist) {
    return CollectionDetailsData(
      type: CollectionType.playlist,
      title: playlist.name,
      artworkPath: playlist.coverUrl,
      ownerName: playlist.owner,
      ownerAvatarPath: playlist.coverUrl,
      yearText: '${playlist.trackCount} tracks',
      likesText: playlist.owner,
      tracks: playlist.tracks
          .map(
            (t) => CollectionTrack(
              id: t.id,
              title: t.title,
              artist: t.artist,
              artworkPath: t.artworkUrl,
              durationSeconds: t.durationSeconds,
            ),
          )
          .toList(),
    );
  }
}
