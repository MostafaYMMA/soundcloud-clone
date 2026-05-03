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
import '../../providers/followers_provider.dart';
import '../../providers/liked_tracks_provider.dart';
import '../../providers/track_provider.dart';
import '../../screens/home/queue_screen.dart';
import '../../screens/library/context_menu_sheet.dart';
import '../../screens/profile/artist_profile_screen.dart';
import '../../screens/profile/comments_screen.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({
    super.key,
    required this.trackNotifier,
    required this.player,
    required this.onPlayPause,
    required this.onSeek,
    this.onSkipNext,
    this.queueNotifier,
    this.onQueueReorder,
    this.onQueueRemove,
    this.onQueueJumpTo,
    this.onQueueAdd,
  });

  final ValueNotifier<Track> trackNotifier;
  final AudioPlayer player;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSkipNext;
  final ValueNotifier<({List<Track> queue, int currentIndex})>? queueNotifier;
  final void Function(int oldIndex, int newIndex)? onQueueReorder;
  final void Function(int index)? onQueueRemove;
  final void Function(int index)? onQueueJumpTo;
  final void Function(Track track)? onQueueAdd;

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
  late Track _currentTrack;

  @override
  void initState() {
    super.initState();
    _currentTrack = widget.trackNotifier.value;
    widget.trackNotifier.addListener(_onTrackChanged);
    _seedLikedState(_currentTrack);
  }

  void _onTrackChanged() {
    if (!mounted) return;
    setState(() {
      _currentTrack = widget.trackNotifier.value;
    });
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

  List<double> get _fallbackWaveform {
    return List.generate(90, (index) => 0.2 + ((index % 7) * 0.08));
  }

  @override
  Widget build(BuildContext context) {
    final waveformAsync = ref.watch(
      trackWaveformProvider(_currentTrack.trackId),
    );

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
                  body: GestureDetector(
                    onTap: widget.onPlayPause,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBackground(coverUrl),

                        if (!isPlaying)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: SizedBox.expand(),
                          ),

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
                              Expanded(child: _buildArtworkArea()),
                              waveformAsync.when(
                                data: (waveform) => _buildWaveform(
                                  waveform: waveform,
                                  elapsed: elapsed,
                                  totalSeconds: totalSeconds,
                                  progress: progress,
                                  totalDuration: totalDuration,
                                ),
                                loading: () => _buildWaveformLoading(
                                  elapsed: elapsed,
                                  totalSeconds: totalSeconds,
                                ),
                                error: (_, __) => _buildWaveform(
                                  waveform: _fallbackWaveform,
                                  elapsed: elapsed,
                                  totalSeconds: totalSeconds,
                                  progress: progress,
                                  totalDuration: totalDuration,
                                ),
                              ),
                              _buildCommentBar(),
                              _buildBottomBar(),
                              const SizedBox(height: AppDimensions.spaceSmall),
                            ],
                          ),
                        ),

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
                                    color: AppColors.surface.withOpacity(0.85),
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

    final fixedCoverUrl = coverUrl.startsWith('http')
        ? coverUrl
        : 'https://streamline-swp.duckdns.org$coverUrl';

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(fixedCoverUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildArtworkArea() {
    final imageUrl = _currentTrack.coverImageUrl;

    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          image: imageUrl != null && imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(
                    imageUrl.startsWith('http')
                        ? imageUrl
                        : 'https://streamline-swp.duckdns.org$imageUrl',
                  ),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(
                Icons.music_note_rounded,
                size: 70,
                color: Colors.white.withOpacity(0.15),
              )
            : null,
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
                GestureDetector(
                  onTap: _currentTrack.artist?.username != null
                      ? () => _openArtistProfile(
                            context,
                            _currentTrack.artist!.username,
                            _currentTrack.artist!.displayName,
                          )
                      : null,
                  child: Text(
                    _currentTrack.artist?.displayName ?? 'Unknown Artist',
                    style: AppTextStyles.artistName,
                  ),
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
                    : () {
                        ref.read(followProvider(followKey).notifier).toggle();
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformLoading({
    required int elapsed,
    required int totalSeconds,
  }) {
    return Column(
      children: [
        const SizedBox(
          height: 130,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        _buildTimeRow(
          elapsed: elapsed,
          totalSeconds: totalSeconds,
          progress: 0,
          totalDuration: Duration(seconds: totalSeconds),
        ),
      ],
    );
  }

  Widget _buildWaveform({
    required List<double> waveform,
    required int elapsed,
    required int totalSeconds,
    required double progress,
    required Duration totalDuration,
  }) {
    final displayWaveform = waveform.isEmpty ? _fallbackWaveform : waveform;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                _seekFromDx(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  totalDuration,
                );
              },
              onTapDown: (details) {
                _seekFromDx(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  totalDuration,
                );
              },
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaveformPainter(
                    waveform: displayWaveform,
                    progress: progress,
                  ),
                ),
              ),
            );
          },
        ),
        _buildTimeRow(
          elapsed: elapsed,
          totalSeconds: totalSeconds,
          progress: progress,
          totalDuration: totalDuration,
        ),
      ],
    );
  }

  Widget _buildTimeRow({
    required int elapsed,
    required int totalSeconds,
    required double progress,
    required Duration totalDuration,
  }) {
    return Padding(
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
                final knobLeft = (progress * (constraints.maxWidth - 12)).clamp(
                  0.0,
                  constraints.maxWidth - 12,
                );

                return GestureDetector(
                  onTapDown: (details) {
                    _seekFromDx(
                      details.localPosition.dx,
                      constraints.maxWidth,
                      totalDuration,
                    );
                  },
                  onHorizontalDragUpdate: (details) {
                    _seekFromDx(
                      details.localPosition.dx,
                      constraints.maxWidth,
                      totalDuration,
                    );
                  },
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
    );
  }

  Widget _buildCommentBar() {
    return GestureDetector(
      onTap: () => showCommentsScreen(context, _currentTrack),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMedium,
          vertical: AppDimensions.spaceSmall,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.textMuted, width: 0.5),
            bottom: BorderSide(color: AppColors.textMuted, width: 0.5),
          ),
        ),
        child: Text(
          'Comment...',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }

  void _openQueueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueScreen(
        queueNotifier: widget.queueNotifier!,
        currentTrack: _currentTrack,
        onReorder: widget.onQueueReorder!,
        onRemove: widget.onQueueRemove!,
        onJumpTo: widget.onQueueJumpTo!,
        onAddTrack: widget.onQueueAdd!,
      ),
    );
  }

  void _openArtistProfile(
    BuildContext context,
    String username,
    String displayName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistProfileScreen(
          username: username,
          displayName: displayName,
          onTrackTap: (track) async {},
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final username = ref.watch(authProvider).user?.userName ?? '';
    final likedIds = ref.watch(likedTracksProvider);
    final isLiked = likedIds.contains(_currentTrack.trackId);

    final serverCount = _currentTrack.likeCount ?? 0;
    final displayCount = isLiked
        ? (_currentTrack.isLiked == true ? serverCount : serverCount + 1)
        : (_currentTrack.isLiked == true ? serverCount - 1 : serverCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Like button
        GestureDetector(
          onTap: () async {
            final notifier = ref.read(likedTracksProvider.notifier);
            final wasLiked = isLiked;
            notifier.toggleLocal(_currentTrack.trackId);
            try {
              await ref
                  .read(
                    toggleTrackLikeProvider(_currentTrack.trackId).notifier,
                  )
                  .toggle(currentlyLiked: wasLiked, username: username);
            } catch (_) {
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
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Share
        const Icon(Icons.ios_share, color: AppColors.textSecondary, size: 22),

        // Queue
        GestureDetector(
          onTap: widget.queueNotifier != null ? _openQueueSheet : null,
          child: Icon(
            Icons.queue_music,
            color: widget.queueNotifier != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            size: 22,
          ),
        ),

        // More — opens context menu sheet
        GestureDetector(
          onTap: () => showTrackContextMenu(context, _currentTrack),
          child: const Icon(
            Icons.more_horiz,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
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
    final gap = barWidth * 0.35;
    final midY = size.height * 0.55;
    final progressX = size.width * progress;

    for (int i = 0; i < count; i++) {
      final x = i * barWidth + gap / 2;
      final w = barWidth - gap;
      final h = waveform[i].clamp(0.08, 1.0) * midY;
      final played = x < progressX;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, midY - h, w, h),
          const Radius.circular(2),
        ),
        Paint()
          ..color =
              played ? AppColors.waveformActive : AppColors.waveformInactive,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, midY + 2, w, h * 0.55),
          const Radius.circular(2),
        ),
        Paint()
          ..color = played
              ? AppColors.waveformActive.withOpacity(0.75)
              : AppColors.waveformInactive.withOpacity(0.75),
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
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveform != waveform;
  }
}