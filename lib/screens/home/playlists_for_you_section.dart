import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_dimensions.dart';
import '../../models/playlist.dart';

class PlaylistsForYouSection extends StatelessWidget {
  final String sectionTitle;
  final List<Playlist> playlists;
  final void Function(Playlist)? onPlaylistTap;

  const PlaylistsForYouSection({
    super.key,
    required this.sectionTitle,
    required this.playlists,
    this.onPlaylistTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMedium,
          ),
          child: Text(sectionTitle, style: AppTextStyles.heading1),
        ),
        const SizedBox(height: AppDimensions.spaceSmall),
        SizedBox(
          height: 210,
          child: playlists.isEmpty
              ? const Center(
                  child: Text('No items yet', style: AppTextStyles.caption),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceMedium,
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < playlists.length; i++) ...[
                        GestureDetector(
                          onTap: () => onPlaylistTap?.call(playlists[i]),
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.borderRadiusSmall,
                                  ),
                                  child: playlists[i].coverUrl.isNotEmpty
                                      ? Image.network(
                                          playlists[i].coverUrl,
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                          headers: const {
                                            'User-Agent': 'Mozilla/5.0',
                                          },
                                          errorBuilder: (_, _, _) =>
                                              const _PlaceholderCover(),
                                        )
                                      : const _PlaceholderCover(),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  playlists[i].name,
                                  style: AppTextStyles.artistName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${playlists[i].trackCount} tracks',
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i < playlists.length - 1)
                          const SizedBox(width: AppDimensions.spaceSmall),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      color: AppColors.waveformInactive,
      child: const Icon(
        Icons.playlist_play,
        color: AppColors.textMuted,
        size: 40,
      ),
    );
  }
}
