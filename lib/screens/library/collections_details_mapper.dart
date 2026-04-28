import '../../models/album.dart';
import '../../models/playlist.dart';
import '../../models/station.dart';
import 'collections_screen.dart';

/// Maps domain models → [CollectionDetailsData] for [CollectionDetailsScreen].
class CollectionDetailsMapper {
  CollectionDetailsMapper._();

  static CollectionDetailsData fromAlbum(Album album) {
    return CollectionDetailsData(
      type: CollectionType.album,
      title: album.title,
      artworkPath: album.artworkUrl,
      ownerName: album.artist,
      ownerAvatarPath: album.artworkUrl, // use artwork as fallback avatar
      yearText: album.releaseYear.toString(),
      likesText: album.likeCount.toString(),
      tracks: [], // populate when track data is available
    );
  }

  static CollectionDetailsData fromPlaylist(Playlist playlist) {
    return CollectionDetailsData(
      type: CollectionType.playlist,
      title: playlist.name,
      artworkPath: playlist.coverUrl ?? '',
      ownerName: playlist.owner,
      ownerAvatarPath: playlist.coverUrl ?? '',
      yearText: playlist.duration ?? '',
      likesText: '${playlist.trackCount} tracks',
      tracks: [], // populate when track data is available
    );
  }

  static CollectionDetailsData fromStation(Station station) {
    return CollectionDetailsData(
      type: CollectionType.station,
      title: station.title,
      artworkPath: station.artworkUrl,
      ownerName: station.basedOn,
      ownerAvatarPath: station.artworkUrl,
      yearText: station.mood,
      likesText: station.likeCount.toString(),
      tracks: [], // populate when track data is available
    );
  }
}