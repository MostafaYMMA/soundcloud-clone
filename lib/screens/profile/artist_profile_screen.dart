import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/track.dart';
import '../../providers/track_provider.dart';
import '../../providers/followers_provider.dart';
import '../../providers/auth_providers.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../library/context_menu_sheet.dart';

const Color kBackgroundColor = Color(0xFF0F0F0F);

class ArtistProfileScreen extends ConsumerWidget {
  const ArtistProfileScreen({
    super.key,
    required this.username,
    required this.displayName,
    required this.onTrackTap,
  });

  final String username;
  final String displayName;
  final Future<void> Function(Track) onTrackTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTracksAsync = ref.watch(userTracksProvider(username));
    final userRepostsAsync = ref.watch(userRepostsProvider(username));
    final authState = ref.watch(authProvider);
    final isCurrentUser = authState.user?.userName == username;
    final size = MediaQuery.of(context).size;
    final double sectionGap = (size.height * 0.018).clamp(18.0, 26.0);

    final followKey = (userId: '', username: username);
    final followState = ref.watch(followProvider(followKey));
    final isFollowing = followState.isFollowing;
    final isFollowLoading = followState.isLoading;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner & Avatar Header
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey[600],
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: -30,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),

              // Artist Info Section
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (!isCurrentUser)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isFollowLoading
                              ? null
                              : () {
                                  ref
                                      .read(followProvider(followKey).notifier)
                                      .toggle();
                                },
                          icon: isFollowLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isFollowing
                                      ? Icons.person_remove_outlined
                                      : Icons.person_add_alt_1_outlined,
                                ),
                          label: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: isFollowing
                                ? Colors.black
                                : AppColors.textSecondary,
                            side: BorderSide(
                              color: isFollowing
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Tracks Section
              SizedBox(height: sectionGap),
              _buildTracksSection(userTracksAsync),
              SizedBox(height: sectionGap),

              // Reposts Section
              if (userRepostsAsync.value?.isNotEmpty ?? false)
                _buildRepostsSection(userRepostsAsync),
              if (userRepostsAsync.value?.isNotEmpty ?? false)
                SizedBox(height: sectionGap),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksSection(AsyncValue<List<Track>> tracksAsync) {
    return tracksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load tracks',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tracks yet',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final displayTracks = tracks.take(5).toList();
        final showSeeAll = tracks.length > 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Tracks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (showSeeAll)
                    Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              itemCount: displayTracks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final track = displayTracks[index];
                return _TrackTile(
                  track: track,
                  onTap: () => onTrackTap(track),
                  onMoreTap: () => showTrackContextMenu(context, track),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRepostsSection(AsyncValue<List<Track>> repostsAsync) {
    return repostsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reposts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (reposts) {
        if (reposts.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayReposts = reposts.take(3).toList();
        final showSeeAll = reposts.length > 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Reposts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (showSeeAll)
                    Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              itemCount: displayReposts.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final track = displayReposts[index];
                return _TrackTile(
                  track: track,
                  onTap: () => onTrackTap(track),
                  onMoreTap: () => showTrackContextMenu(context, track),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.onTap,
    required this.onMoreTap,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  String _formatCount(int count) {
    if (count >= 1000000) {
      final v = count / 1000000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      final v = count / 1000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (track.coverImageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    track.coverImageUrl!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ThumbPlaceholder(),
                  )
                : const _ThumbPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (screenWidth * 0.046).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist?.displayName ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: (screenWidth * 0.04).clamp(13.0, 15.0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '▶ ${_formatCount(track.likeCount ?? 0)} · ${_formatDuration(track.durationSeconds ?? 0)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: (screenWidth * 0.037).clamp(12.0, 14.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onMoreTap,
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.more_horiz, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 28),
    );
  }
}
