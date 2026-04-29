import 'package:flutter/material.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/constants/app_dimensions.dart';
import 'package:my_project/constants/app_text_styles.dart';
import 'package:my_project/mock_data/mock_tracks.dart';
import 'package:my_project/screens/library/widgets/track_tile.dart';

class VibeScreen extends StatelessWidget {
  final String vibe;

  const VibeScreen({super.key, required this.vibe});

  @override
  Widget build(BuildContext context) {
    final trendingTracks = [
      ...MockTracks.likedTracks,
      MockTracks.hotTrack,
      ...MockTracks.recommendedTracks,
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vibe),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spaceExtraLarge),
                  Text(
                    vibe,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceExtraLarge),
            const TabBar(
              labelColor: AppColors.textPrimary,
              labelStyle: AppTextStyles.button,
              dividerColor: AppColors.background,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              overlayColor: WidgetStatePropertyAll(AppColors.background),
              tabs: [
                Tab(text: "Trending"),
                Tab(text: "Playlists"),
                Tab(text: "Albums"),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMedium),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceLarge,
                        ),
                        child: Text(
                          'Trending',
                          style: AppTextStyles.heading1,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceSmall,
                          ),
                          itemCount: trendingTracks.length,
                          itemBuilder: (context, index) {
                            final track = trendingTracks[index];
                            return TrackTile(
                              track: track,
                              onTap: () {},
                              onMoreTap: () {},
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  /// PLAYLISTS TAB (FIXED NULL SAFETY)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceLarge,
                        ),
                        child: Text(
                          'Playlists',
                          style: AppTextStyles.heading1,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceLarge,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: trendingTracks.length,
                          itemBuilder: (context, index) {
                            final track = trendingTracks[index];
                            return _GridTile(track: track);
                          },
                        ),
                      ),
                    ],
                  ),

                  /// ALBUMS TAB (FIXED NULL SAFETY)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceLarge,
                        ),
                        child: Text(
                          'Albums',
                          style: AppTextStyles.heading1,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSmall),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceLarge,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: trendingTracks.length,
                          itemBuilder: (context, index) {
                            final track = trendingTracks[index];
                            return _GridTile(track: track);
                          },
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
    );
  }
}

/// FIXED GRID TILE (prevents null crash)
class _GridTile extends StatelessWidget {
  final dynamic track;

  const _GridTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final String artworkUrl = track.artworkUrl ?? '';
    final String title = track.title ?? 'Unknown';
    final String artist = track.artist ?? 'Unknown';

    return GestureDetector(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSharp),
            child: artworkUrl.isNotEmpty
                ? Image.network(
                    artworkUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: AppColors.waveformInactive,
                      child: const Icon(Icons.queue_music),
                    ),
                  )
                : Container(
                    height: 140,
                    color: AppColors.waveformInactive,
                    child: const Icon(Icons.queue_music),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            artist,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}