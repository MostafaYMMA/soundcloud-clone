import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project/models/playlist.dart';
import 'package:my_project/providers/playlist_provider.dart';
import 'package:my_project/screens/library/collections_screen.dart';


Future<void> openPlaylist({
  required BuildContext context,
  required WidgetRef ref,
  required Playlist playlist,
}) async {
  final detailed = await ref
      .read(playlistProvider.notifier)
      .getPlaylistDetails(playlist.id);

  if (detailed == null) return;
  if (!context.mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CollectionDetailsScreen(
        playlistId: detailed.id,
        data: CollectionDetailsData(
          type: CollectionType.playlist,
          title: detailed.name,
          artworkPath: detailed.coverUrl,
          ownerName: detailed.owner,
          ownerAvatarPath: '',
          yearText: '2026',
          likesText: '0',
          tracks: detailed.tracks
              .map((t) => CollectionTrack(
                    id: t.id,
                    title: t.title,
                    artist: t.artist,
                    artworkPath: t.artworkUrl,
                    isAvailable: true,
                  ))
              .toList(),
        ),
      ),
    ),
  );
}