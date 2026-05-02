import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_text_styles.dart';
import '../../models/track.dart';
import '../../models/feed_response.dart';
import '../../providers/feed_provider.dart';

class QueueScreen extends ConsumerStatefulWidget {
  final ValueNotifier<({List<Track> queue, int currentIndex})> queueNotifier;
  final Track currentTrack;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final void Function(int index) onJumpTo;
  final void Function(Track track) onAddTrack;

  const QueueScreen({
    super.key,
    required this.queueNotifier,
    required this.currentTrack,
    required this.onReorder,
    required this.onRemove,
    required this.onJumpTo,
    required this.onAddTrack,
  });

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    final discoverFeed = ref.watch(discoverFeedProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            _buildDragHandle(),
            _buildHeader(),
            Expanded(
              child: ValueListenableBuilder<({List<Track> queue, int currentIndex})>(
                valueListenable: widget.queueNotifier,
                builder: (context, queueState, _) {
                  if (queueState.queue.isEmpty) {
                    return Center(
                      child: Text(
                        'Queue is empty',
                        style: AppTextStyles.artistName,
                      ),
                    );
                  }

                  return CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      if (queueState.queue.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceMedium,
                              vertical: AppDimensions.spaceSmall,
                            ),
                            child: Text(
                              'Now Playing',
                              style: AppTextStyles.heading2,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: _buildCurrentTrackTile(queueState),
                      ),
                      if (queueState.queue.length > 1)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceMedium,
                              vertical: AppDimensions.spaceSmall,
                            ),
                            child: Text(
                              'Up Next',
                              style: AppTextStyles.heading2,
                            ),
                          ),
                        ),
                      if (queueState.queue.length > 1)
                        SliverReorderableList(
                          onReorder: (oldIndex, newIndex) {
                            final actualOldIndex = oldIndex + queueState.currentIndex + 1;
                            final actualNewIndex = newIndex + queueState.currentIndex + 1;
                            widget.onReorder(actualOldIndex, actualNewIndex);
                          },
                          itemBuilder: (context, index) {
                            final trackIndex = queueState.currentIndex + 1 + index;
                            if (trackIndex >= queueState.queue.length) {
                              return const SizedBox();
                            }
                            final track = queueState.queue[trackIndex];
                            return ReorderableDragStartListener(
                              key: ValueKey(trackIndex),
                              index: index,
                              child: _buildQueueTrackTile(
                                track: track,
                                index: trackIndex,
                                currentIndex: queueState.currentIndex,
                              ),
                            );
                          },
                          itemCount: queueState.queue.length -
                              queueState.currentIndex -
                              1,
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMedium,
                            vertical: AppDimensions.spaceSmall,
                          ),
                          child: Text(
                            'Add to Queue',
                            style: AppTextStyles.heading2,
                          ),
                        ),
                      ),
                      discoverFeed.when(
                        loading: () => SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        error: (_, __) => SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100,
                            child: Center(
                              child: Text(
                                'Could not load discover feed',
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ),
                        ),
                        data: (feedState) {
                          final discoverTracks = feedState.items
                              .map((item) => item.toTrack())
                              .toList();

                          final queueTrackIds =
                              queueState.queue.map((t) => t.trackId).toSet();

                          final availableTracks = discoverTracks
                              .where(
                                (t) => !queueTrackIds.contains(t.trackId),
                              )
                              .take(20)
                              .toList();

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final track = availableTracks[index];
                                return _buildAddTrackTile(track);
                              },
                              childCount: availableTracks.length,
                            ),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: AppDimensions.spaceLarge,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSmall),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Queue',
            style: AppTextStyles.heading1,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTrackTile(({List<Track> queue, int currentIndex}) queueState) {
    final track = queueState.queue[queueState.currentIndex];
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceSmall),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up, color: AppColors.primary, size: 20),
          const SizedBox(width: AppDimensions.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTextStyles.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist?.displayName ?? 'Unknown Artist',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTrackTile({
    required Track track,
    required int index,
    required int currentIndex,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onJumpTo(index);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMedium,
          vertical: AppDimensions.spaceSmall,
        ),
        padding: const EdgeInsets.all(AppDimensions.spaceSmall),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: Row(
          children: [
            ReorderableDelayedDragStartListener(
              index: index - currentIndex - 1,
              child: const Icon(
                Icons.drag_handle,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: AppTextStyles.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist?.displayName ?? 'Unknown Artist',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
              onPressed: () => widget.onRemove(index),
              constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTrackTile(Track track) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
              child: (track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty)
                  ? Image.network(
                      track.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.waveformInactive,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.waveformInactive,
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTextStyles.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist?.displayName ?? 'Unknown Artist',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: () => widget.onAddTrack(track),
            constraints: const BoxConstraints(maxWidth: 48, maxHeight: 48),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// Extension to convert FeedTrackItem to Track
extension FeedTrackItemToTrack on FeedTrackItem {
  Track toTrack() => Track(
    trackId: trackId,
    title: title,
    description: description,
    genre: genre,
    tags: tags,
    releaseDate: releaseDate,
    coverImageUrl: coverImageUrl,
    streamUrl: streamUrl,
    userId: artist.userId,
    artist: TrackArtist(
      userId: artist.userId,
      username: artist.username,
      displayName: artist.displayName,
      profilePicture: artist.profilePicture,
      followerCount: artist.followerCount,
    ),
    visibility: 'public',
    processingStatus: 'ready',
    playCount: playCount,
    durationSeconds: durationSeconds,
    likeCount: likeCount,
    repostCount: repostCount,
    commentCount: commentCount,
    isLiked: isLiked,
    isReposted: isReposted,
    createdAt: createdAt,
  );
}
