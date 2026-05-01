import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../providers/playlist_provider.dart';
import '../../screens/library/context_menu_sheet.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.onTrackTap,
    this.onBack,
  });

  final Playlist playlist;
  final Future<void> Function(Track) onTrackTap;

  /// Use this instead of Navigator.pop() when screen was pushed via onNavigate
  final VoidCallback? onBack;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _detailedPlaylist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await ref
        .read(playlistProvider.notifier)
        .getPlaylistDetails(widget.playlist.id);

    if (!mounted) return;
    setState(() {
      _detailedPlaylist = details ?? widget.playlist;
      _isLoading = false;
      _error = details == null ? 'Failed to load playlist.' : null;
    });
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatTotalDuration(List<PlaylistTrack> tracks) {
    final total = tracks.fold(0, (sum, t) => sum + t.durationSeconds);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatTrackDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playlist = _detailedPlaylist ?? widget.playlist;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // ── Header ────────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: playlist.coverUrl.isNotEmpty
                                      ? Image.network(
                                          playlist.coverUrl,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const _CoverPlaceholder(
                                                size: 110,
                                              ),
                                        )
                                      : const _CoverPlaceholder(size: 110),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlist.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Playlist · ${playlist.tracks.length} tracks'
                                        '${playlist.tracks.isNotEmpty ? ' · ${_formatTotalDuration(playlist.tracks)}' : ''}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2A2A2A),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white54,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'By ${playlist.owner}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // ── Action row ────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white70,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Icon(
                                    Icons.more_horiz,
                                    color: Colors.white70,
                                    size: 26,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {},
                                  child: Icon(
                                    Icons.shuffle,
                                    color: Colors.grey[500],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    if (playlist.tracks.isNotEmpty) {
                                      widget.onTrackTap(
                                        _playlistTrackToTrack(
                                          playlist.tracks.first,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // ── Track list ────────────────────────────────────
                        if (playlist.tracks.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 32,
                              ),
                              child: Text(
                                'No tracks in this playlist yet.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final t = playlist.tracks[index];
                              final asTrack = _playlistTrackToTrack(t);
                              return _TrackRow(
                                track: t,
                                formatDuration: _formatTrackDuration,
                                onTap: () => widget.onTrackTap(asTrack),
                                onMoreTap: () =>
                                    showTrackContextMenu(context, asTrack),
                              );
                            }, childCount: playlist.tracks.length),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Track _playlistTrackToTrack(PlaylistTrack t) {
    return Track(
      trackId: t.id,
      title: t.title,
      coverImageUrl: t.artworkUrl.isNotEmpty ? t.artworkUrl : null,
      streamUrl: '',
      visibility: 'public',
      processingStatus: '',
      playCount: 0,
      durationSeconds: t.durationSeconds,
      artist: TrackArtist(
        userId: '',
        username: t.artist,
        displayName: t.artist,
        followerCount: 0,
      ),
    );
  }
}

// ── Track row widget ───────────────────────────────────────────────────────────

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.formatDuration,
    required this.onTap,
    required this.onMoreTap,
  });

  final PlaylistTrack track;
  final String Function(int) formatDuration;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.artworkUrl.isNotEmpty
                  ? Image.network(
                      track.artworkUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _TrackArtPlaceholder(),
                    )
                  : const _TrackArtPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatDuration(track.durationSeconds),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onMoreTap,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.more_horiz, color: Colors.white54, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder widgets ────────────────────────────────────────────────────────

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.queue_music, color: Colors.white38, size: 36),
    );
  }
}

class _TrackArtPlaceholder extends StatelessWidget {
  const _TrackArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
    );
  }
}
