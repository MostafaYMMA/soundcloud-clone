import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/models/playlist.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/providers/playlist_provider.dart';
import 'package:my_project/providers/music_providers.dart';
import 'package:my_project/screens/library/collections_screen.dart';
import 'package:my_project/screens/library/context_menu_sheet.dart';
import 'package:my_project/screens/search/search_bar.dart';
import 'package:my_project/screens/search/vibes_section.dart';
import 'package:my_project/models/album.dart';
import 'package:my_project/providers/album_provider.dart';
import 'package:my_project/screens/library/collections_details_mapper.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final void Function(Track)? onTrackTap;
  final void Function(Widget screen)? onNavigate;
  final void Function(List<Track> tracks, int startIndex)? onQueuePlay;

  const SearchScreen({
    super.key,
    this.onTrackTap,
    this.onNavigate,
    this.onQueuePlay,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _updatingPlaylistId;

  String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'https://streamline-swp.duckdns.org$url';
    return url;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).fetchLikedPlaylists();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();

      setState(() => _query = query);

      ref.read(playlistProvider.notifier).searchPlaylists(query);
      ref.invalidate(searchTracksProvider(query));
      ref.invalidate(searchAlbumsProvider(query));
    });
  }

  bool _isPlaylistLiked(Playlist playlist, PlaylistState state) {
    return state.likedPlaylists.any((p) => p.id == playlist.id);
  }

  Future<void> _togglePlaylistLike(Playlist playlist) async {
    if (_updatingPlaylistId != null) return;

    final playlistState = ref.read(playlistProvider);
    final isLiked = _isPlaylistLiked(playlist, playlistState);

    setState(() {
      _updatingPlaylistId = playlist.id;
    });

    if (isLiked) {
      await ref.read(playlistProvider.notifier).unlikePlaylist(playlist.id);
    } else {
      await ref.read(playlistProvider.notifier).likePlaylist(playlist.id);
    }

    if (!mounted) return;

    final updatedState = ref.read(playlistProvider);

    setState(() {
      _updatingPlaylistId = null;
    });

    if (updatedState.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(updatedState.error!)));
      ref.read(playlistProvider.notifier).clearMessages();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLiked
              ? 'You removed this playlist from likes.'
              : '${playlist.name} added to your playlists.',
        ),
      ),
    );

    ref.read(playlistProvider.notifier).clearMessages();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    final trackState = ref.watch(searchTracksProvider(_query));
    final albumAsync = ref.watch(searchAlbumsProvider(_query));
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBar1(controller: _controller, onChanged: _onSearchChanged),
            const SizedBox(height: 10),
            Expanded(
              child: isSearching
                  ? _buildResults(playlistState, trackState, albumAsync)
                  : const SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: VibesSection(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    PlaylistState playlistState,
    AsyncValue<List<Track>> trackState,
    AsyncValue<List<Album>> albumAsync,
  ) {
    if (playlistState.isSearching ||
        trackState.isLoading ||
        albumAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final playlists = playlistState.searchResults;
    final tracks = trackState.value ?? [];
    final albums = albumAsync.value ?? [];
    if (playlistState.error != null &&
        playlists.isEmpty &&
        tracks.isEmpty &&
        albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            playlistState.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (playlists.isEmpty && tracks.isEmpty && albums.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView(
      children: [
        // ───── TRACKS ─────
        if (tracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Tracks',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          ...tracks.map((track) {
            final artistName = track.artist?.displayName ?? 'Unknown Artist';
            final image = fixImageUrl(track.coverImageUrl);

            return ListTile(
              onTap: () {
                widget.onTrackTap?.call(track);
              },

              leading: _SquareImage(
                imageUrl: image,
                fallbackIcon: Icons.music_note,
              ),

              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),

              subtitle: Text(
                artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),

              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  showTrackContextMenu(context, track);
                },
              ),
            );
          }),
        ],
        // ───── ALBUMS ─────
        if (albums.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Albums',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ...albums.map((album) {
            final image = fixImageUrl(album.artworkUrl);
            final isLiked = ref
                .watch(albumProvider)
                .likedAlbums
                .any((a) => a.id == album.id);

            return ListTile(
              onTap: () => _openAlbum(album),
              leading: _SquareImage(imageUrl: image, fallbackIcon: Icons.album),
              title: Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                tooltip: isLiked ? 'Remove from likes' : 'Add to likes',
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () async {
                  if (isLiked) {
                    await ref
                        .read(albumProvider.notifier)
                        .unlikeAlbum(album.id);
                  } else {
                    await ref.read(albumProvider.notifier).likeAlbum(album.id);
                  }
                },
              ),
            );
          }),
        ],

        // ───── PLAYLISTS ─────
        if (playlists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Playlists',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),

          ...playlists.map((playlist) {
            final image = fixImageUrl(playlist.coverUrl);
            final isLiked = _isPlaylistLiked(playlist, playlistState);
            final isUpdating = _updatingPlaylistId == playlist.id;

            return ListTile(
              onTap: () => openPlaylist(playlist),

              leading: _SquareImage(
                imageUrl: image,
                fallbackIcon: Icons.queue_music,
              ),

              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),

              subtitle: Text(
                playlist.description.isEmpty
                    ? 'Playlist'
                    : playlist.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),

              trailing: IconButton(
                tooltip: isLiked ? 'Remove from likes' : 'Add to likes',
                icon: isUpdating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                onPressed: isUpdating
                    ? null
                    : () => _togglePlaylistLike(playlist),
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> openPlaylist(Playlist playlist) async {
    final detailed = await ref
        .read(playlistProvider.notifier)
        .getPlaylistDetails(playlist.id);

    if (!mounted) return;

    if (detailed == null) {
      final error =
          ref.read(playlistProvider).error ?? 'Could not open playlist.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    widget.onNavigate?.call(
      CollectionDetailsScreen(
        playlistId: detailed.id,
        data: CollectionDetailsData(
          type: CollectionType.playlist,
          title: detailed.name,
          artworkPath: detailed.coverUrl,
          ownerName: detailed.owner,
          ownerAvatarPath: '',
          yearText: '${detailed.trackCount} tracks',
          likesText: detailed.owner,
          tracks: detailed.tracks
              .map(
                (track) => CollectionTrack(
                  id: track.id,
                  title: track.title,
                  artist: track.artist,
                  artworkPath: track.artworkUrl,
                  durationSeconds: track.durationSeconds,
                  isAvailable: true,
                ),
              )
              .toList(),
        ),
        onTrackTap: (collectionTrack) async {
          // ← add
          final playableTrack = Track(
            trackId: collectionTrack.id,
            title: collectionTrack.title,
            coverImageUrl: collectionTrack.artworkPath,
            streamUrl:
                'https://streamline-swp.duckdns.org/api/tracks/${collectionTrack.id}/audio',
            artist: TrackArtist(
              userId: '',
              username: '',
              displayName: collectionTrack.artist,
              followerCount: 0,
            ),
            visibility: 'public',
            processingStatus: '',
            playCount: 0,
            durationSeconds: collectionTrack.durationSeconds,
          );
          widget.onTrackTap?.call(playableTrack);
        },
        onQueuePlay: widget.onQueuePlay,

        onBack: () => widget.onNavigate?.call(
          SearchScreen(
            onTrackTap: widget.onTrackTap,
            onNavigate: widget.onNavigate,
          ),
        ),
      ),
    );
  }

  Future<void> _openAlbum(Album album) async {
    final detailed = await ref
        .read(albumProvider.notifier)
        .getAlbumDetails(album.id);

    if (!mounted) return;

    if (detailed == null) {
      final error = ref.read(albumProvider).error ?? 'Could not open album.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    widget.onNavigate?.call(
      CollectionDetailsScreen(
        data: CollectionDetailsMapper.fromAlbum(detailed),
        onTrackTap: (collectionTrack) async {
          // ← add
          final playableTrack = Track(
            trackId: collectionTrack.id,
            title: collectionTrack.title,
            coverImageUrl: collectionTrack.artworkPath,
            streamUrl:
                'https://streamline-swp.duckdns.org/api/tracks/${collectionTrack.id}/audio',
            artist: TrackArtist(
              userId: '',
              username: '',
              displayName: collectionTrack.artist,
              followerCount: 0,
            ),
            visibility: 'public',
            processingStatus: '',
            playCount: 0,
            durationSeconds: collectionTrack.durationSeconds,
          );
          widget.onTrackTap?.call(playableTrack);
        },

        onQueuePlay: widget.onQueuePlay,

        onBack: () => widget.onNavigate?.call(
          SearchScreen(
            onTrackTap: widget.onTrackTap,
            onNavigate: widget.onNavigate,
          ),
        ),
      ),
    );
  }
}

class _SquareImage extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const _SquareImage({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackIcon(icon: fallbackIcon),
              )
            : _FallbackIcon(icon: fallbackIcon),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final IconData icon;

  const _FallbackIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Icon(icon, color: Colors.white),
    );
  }
}
