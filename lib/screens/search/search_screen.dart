import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/models/playlist.dart';
import 'package:my_project/models/track.dart';
import 'package:my_project/providers/playlist_provider.dart';
import 'package:my_project/providers/music_providers.dart';
import 'package:my_project/screens/library/collections_screen.dart';
import 'package:my_project/screens/search/search_bar.dart';
import 'package:my_project/screens/search/vibes_section.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final Set<String> _locallyLikedPlaylistIds = {};

  String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return 'https://streamline-swp.duckdns.org$url';
    return url;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();

      setState(() => _query = query);

      ref.read(playlistProvider.notifier).searchPlaylists(query);
      ref.invalidate(searchTracksProvider(query));
    });
  }

  Future<void> _likePlaylist(Playlist playlist) async {
    if (_locallyLikedPlaylistIds.contains(playlist.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist is already in your library.')),
      );
      return;
    }

    await ref.read(playlistProvider.notifier).likePlaylist(playlist.id);

    if (!mounted) return;

    final state = ref.read(playlistProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
      return;
    }

    setState(() {
      _locallyLikedPlaylistIds.add(playlist.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${playlist.name} added to your playlists.')),
    );

    ref.read(playlistProvider.notifier).clearMessages();
  }

  bool _isPlaylistLiked(Playlist playlist, PlaylistState state) {
    return _locallyLikedPlaylistIds.contains(playlist.id) ||
        state.likedPlaylists.any((p) => p.id == playlist.id);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).fetchLikedPlaylists();
    });
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
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            SearchBar1(controller: _controller, onChanged: _onSearchChanged),
            const SizedBox(height: 10),
            Expanded(
              child: isSearching
                  ? _buildResults(playlistState, trackState)
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
  ) {
    if (playlistState.isSearching || trackState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final playlists = playlistState.searchResults;
    final tracks = trackState.value ?? [];

    if (playlistState.error != null && playlists.isEmpty && tracks.isEmpty) {
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

    if (playlists.isEmpty && tracks.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView(
      children: [
        if (tracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Tracks',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ...tracks.map((t) {
            final artistName = t.artist?.displayName ?? 'Unknown Artist';
            final image = fixImageUrl(t.coverImageUrl);

            return ListTile(
              leading: _SquareImage(
                imageUrl: image,
                fallbackIcon: Icons.music_note,
              ),
              title: Text(
                t.title,
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
            );
          }),
        ],
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

            return ListTile(
              onTap: () => _openPlaylist(playlist),
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
                tooltip: isLiked ? 'Already in library' : 'Add to library',
                icon: playlistState.isLiking
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
                onPressed: playlistState.isLiking || isLiked
                    ? null
                    : () => _likePlaylist(playlist),
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _openPlaylist(Playlist playlist) async {
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
