// widgets/full_player.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/constants/app_dimensions.dart';
import 'package:my_project/constants/app_text_styles.dart';
import 'package:my_project/models/track.dart';
import '../../providers/auth_providers.dart';
import '../../providers/track_provider.dart';
import '../../providers/liked_tracks_provider.dart';
import '../../providers/followers_provider.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({
    super.key,
    required this.trackNotifier,
    required this.player,
    required this.onPlayPause,
    required this.onSeek,
    this.onSkipNext,
  });

  final ValueNotifier<Track> trackNotifier;
  final AudioPlayer player;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSkipNext;

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
  late Track _currentTrack;

  final List<double> waveform = List.generate(
    70,
    (index) => 0.2 + ((index % 7) * 0.08),
  );

  @override
  void initState() {
    super.initState();
    _currentTrack = widget.trackNotifier.value;
    widget.trackNotifier.addListener(_onTrackChanged);
    _seedLikedState(_currentTrack);
  }

  void _onTrackChanged() {
    if (!mounted) return;
    setState(() => _currentTrack = widget.trackNotifier.value);
    _seedLikedState(_currentTrack);
  }

  void _seedLikedState(Track track) {
    if (track.isLiked == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(likedTracksProvider.notifier);
        final current = ref.read(likedTracksProvider);
        if (!current.contains(track.trackId)) {
          notifier.setAll({...current, track.trackId});
        }
      });
    }
  }

  @override
  void dispose() {
    widget.trackNotifier.removeListener(_onTrackChanged);
    super.dispose();
  }

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _seekFromDx(double dx, double width, Duration totalDuration) {
    if (width <= 0 || totalDuration.inMilliseconds <= 0) return;
    final newProgress = (dx / width).clamp(0.0, 1.0);
    final targetMs = (newProgress * totalDuration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    // ── Follow state ─────────────────────────────────────────────────────────
    final artistUsername = _currentTrack.artist?.username;
    final artistUserId = _currentTrack.artist?.userId;

    final followKey = (artistUsername != null && artistUserId != null)
        ? (userId: artistUserId, username: artistUsername)
        : null;

    final followState = followKey != null
        ? ref.watch(followProvider(followKey))
        : null;

    final isFollowing = followState?.isFollowing ?? false;
    final isFollowLoading = followState?.isLoading ?? false;

    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, playerStateSnapshot) {
        final isPlaying = playerStateSnapshot.data?.playing ?? false;

        return StreamBuilder<Duration?>(
          stream: widget.player.durationStream,
          builder: (context, durationSnapshot) {
            final totalDuration =
                durationSnapshot.data ??
                Duration(seconds: _currentTrack.durationSeconds ?? 0);

            return StreamBuilder<Duration>(
              stream: widget.player.positionStream,
              initialData: widget.player.position,
              builder: (context, positionSnapshot) {
                final currentPosition = positionSnapshot.data ?? Duration.zero;
                final totalMs = totalDuration.inMilliseconds;
                final currentMs = currentPosition.inMilliseconds.clamp(
                  0,
                  totalMs > 0 ? totalMs : 1,
                );
                final progress = totalMs > 0 ? currentMs / totalMs : 0.0;
                final elapsed = currentPosition.inSeconds;
                final totalSeconds = totalDuration.inSeconds > 0
                    ? totalDuration.inSeconds
                    : _currentTrack.durationSeconds ?? 0;

                final coverUrl = _currentTrack.coverImageUrl;

                return Scaffold(
                  backgroundColor: Colors.black,
                  // Tap anywhere → pause (when playing).
                  // Buttons/waveform are descendants and win the gesture arena,
                  // so they are unaffected.
                  body: GestureDetector(
                    onTap: widget.onPlayPause,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Background: blurred cover art ─────────────────
                        _buildBackground(coverUrl),

                        // ── Dim overlay when paused ────────────────────────
                        if (!isPlaying)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: SizedBox.expand(),
                          ),

                        // ── All UI (always visible) ────────────────────────
                        SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopSection(
                                context,
                                isFollowing: isFollowing,
                                isFollowLoading: isFollowLoading,
                                followKey: followKey,
                              ),
                              const Spacer(),
                              _buildWaveform(
                                elapsed: elapsed,
                                totalSeconds: totalSeconds,
                                progress: progress,
                                totalDuration: totalDuration,
                              ),
                              _buildCommentBar(),
                              _buildBottomBar(),
                              const SizedBox(height: AppDimensions.spaceSmall),
                            ],
                          ),
                        ),

                        // ── Center controls ────────────────────────────────
                        // Play button only when paused; skip always visible.
                        // When playing, tap the background itself to pause.
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isPlaying) ...[
                                GestureDetector(
                                  onTap: widget.onPlayPause,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: AppColors.textPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppColors.background,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceLarge),
                              ],
                              GestureDetector(
                                onTap: widget.onSkipNext,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.85,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.skip_next_rounded,
                                    color: AppColors.textPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBackground(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      return Container(color: Colors.black);
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(coverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context, {
    required bool isFollowing,
    required bool isFollowLoading,
    required FollowKey? followKey,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentTrack.title, style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(
                  _currentTrack.artist?.displayName ?? 'Unknown Artist',
                  style: AppTextStyles.artistName,
                ),
                const SizedBox(height: AppDimensions.spaceSmall),
                const Row(
                  children: [
                    Icon(
                      Icons.graphic_eq,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text('Behind this track', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),

              // ── Follow / Unfollow button ──────────────────────────────────
              IconButton(
                icon: isFollowLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        isFollowing
                            ? Icons.person_remove_outlined
                            : Icons.person_add_alt_1_outlined,
                        color: isFollowing
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                tooltip: isFollowing ? 'Unfollow' : 'Follow',
                onPressed: (isFollowLoading || followKey == null)
                    ? null
                    : () =>
                          ref.read(followProvider(followKey).notifier).toggle(),
              ),

              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                color: AppColors.textSecondary,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform({
    required int elapsed,
    required int totalSeconds,
    required double progress,
    required Duration totalDuration,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) => _seekFromDx(
                details.localPosition.dx,
                constraints.maxWidth,
                totalDuration,
              ),
              onTapDown: (details) => _seekFromDx(
                details.localPosition.dx,
                constraints.maxWidth,
                totalDuration,
              ),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaveformPainter(
                    waveform: waveform,
                    progress: progress,
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMedium,
            vertical: AppDimensions.spaceExtraSmall,
          ),
          child: Row(
            children: [
              Text(
                formatTime(elapsed),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSmall),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final knobLeft = (progress * (constraints.maxWidth - 12))
                        .clamp(0.0, constraints.maxWidth - 12);
                    return GestureDetector(
                      onTapDown: (details) => _seekFromDx(
                        details.localPosition.dx,
                        constraints.maxWidth,
                        totalDuration,
                      ),
                      onHorizontalDragUpdate: (details) => _seekFromDx(
                        details.localPosition.dx,
                        constraints.maxWidth,
                        totalDuration,
                      ),
                      child: SizedBox(
                        height: 20,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.waveformInactive,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: knobLeft,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSmall),
              Text(formatTime(totalSeconds), style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spaceSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMedium,
          vertical: AppDimensions.spaceSmall,
        ),
        decoration: const ShapeDecoration(
          color: AppColors.surface,
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.textMuted, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Comment...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppDimensions.spaceSmall),
            const Text('👏', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppDimensions.spaceSmall),
            const Text('🥹', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final username = ref.watch(authProvider).user?.userName ?? '';

    // Single source of truth for liked state
    final likedIds = ref.watch(likedTracksProvider);
    final isLiked = likedIds.contains(_currentTrack.trackId);

    // Show the server like count, adjusted for optimistic toggle
    final serverCount = _currentTrack.likeCount ?? 0;
    final displayCount = isLiked
        ? (_currentTrack.isLiked == true ? serverCount : serverCount + 1)
        : (_currentTrack.isLiked == true ? serverCount - 1 : serverCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () async {
            final notifier = ref.read(likedTracksProvider.notifier);
            final wasLiked = isLiked;

            // Optimistic update
            notifier.toggleLocal(_currentTrack.trackId);

            try {
              await ref
                  .read(toggleTrackLikeProvider(_currentTrack.trackId).notifier)
                  .toggle(currentlyLiked: wasLiked, username: username);
            } catch (_) {
              // Rollback on failure
              notifier.toggleLocal(_currentTrack.trackId);
            }
          },
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                '$displayCount',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.textSecondary,
          size: 22,
        ),
        const Icon(Icons.ios_share, color: AppColors.textSecondary, size: 22),
        const Icon(Icons.queue_music, color: AppColors.textSecondary, size: 22),
        const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 22),
      ],
    );
  }

}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;

  WaveformPainter({required this.waveform, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final count = waveform.length;
    final barWidth = size.width / count;
    final gap = barWidth * 0.3;
    final midY = size.height * 0.6;
    final progressX = size.width * progress;

    for (int i = 0; i < count; i++) {
      final x = i * barWidth + gap / 2;
      final w = barWidth - gap;
      final h = waveform[i] * midY;
      final played = x < progressX;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, midY - h, w, h),
          const Radius.circular(2),
        ),
        Paint()
          ..color = played ? AppColors.textPrimary : AppColors.waveformInactive,
      );
    }

    canvas.drawLine(
      Offset(progressX, 0),
      Offset(progressX, size.height),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.waveform != waveform;
}
