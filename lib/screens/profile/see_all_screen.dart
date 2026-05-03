import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_dimensions.dart';
import '../../models/track.dart';
import '../../models/playlist.dart';
import '../library/context_menu_sheet.dart';
import '../library/widgets/track_tile.dart';
import 'playlist_detail_screen.dart';

/// A generic "See All" screen that shows a vertical list of tracks
/// and/or playlists, matching the HistoryScreen style.
class SeeAllScreen extends StatelessWidget {
  const SeeAllScreen({
    super.key,
    required this.title,
    this.tracks = const [],
    this.playlists = const [],
    this.onBack,
    this.onTrackTap,
    this.onNavigate,
  });

  final String title;
  final List<Track> tracks;
  final List<Playlist> playlists;
  final VoidCallback? onBack;
  final Future<void> Function(Track)? onTrackTap;
  final void Function(Widget)? onNavigate;

  @override
  Widget build(BuildContext context) {
    // Combine into a unified list: tracks first then playlists
    final int totalCount = tracks.length + playlists.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(title, style: AppTextStyles.heading2),
      ),
      body: totalCount == 0
          ? const Center(
              child: Text('Nothing here yet.', style: AppTextStyles.artistName),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                if (index < tracks.length) {
                  final track = tracks[index];
                  return TrackTile(
                    track: track,
                    onTap: () => onTrackTap?.call(track),
                    onMoreTap: () => showTrackContextMenu(context, track),
                  );
                } else {
                  final playlist = playlists[index - tracks.length];
                  return _PlaylistTile(
                    playlist: playlist,
                    onTap: () {
                      final screen = PlaylistDetailScreen(
                        playlist: playlist,
                        onTrackTap: onTrackTap ?? (_) async {},
                        onBack: onBack,
                      );
                      if (onNavigate != null) {
                        onNavigate!(screen);
                      } else {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => screen));
                      }
                    },
                  );
                }
              },
            ),
    );
  }
}

// ── Playlist tile — matches TrackTile style ───────────────────────────────────

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceExtraSmall,
      ),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        child: playlist.coverUrl.isNotEmpty
            ? Image.network(
                playlist.coverUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
      title: Text(
        playlist.name,
        style: AppTextStyles.trackTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.trackCount} tracks · ${playlist.owner}',
        style: AppTextStyles.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.surfaceLight,
      child: const Icon(Icons.queue_music, color: AppColors.textMuted),
    );
  }
}
