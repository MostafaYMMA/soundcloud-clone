import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/constants/app_dimensions.dart';
import 'package:my_project/constants/app_text_styles.dart';
import 'package:my_project/models/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/track_provider.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({
    super.key,
    required this.track,
    required this.player,
    required this.onPlayPause,
    required this.onSeek,
  });

  final Track track;
  final AudioPlayer player;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
  bool showControls = false;
  bool isLiked = false;
  bool _initializedControls = false;
  bool _isTogglingLike = false;

  final List<double> waveform = List.generate(
    70,
    (index) => 0.2 + ((index % 7) * 0.08),
  );

  @override
  void initState() {
    super.initState();

    // OPTIONAL: initialize liked state from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = ref.read(authProvider).user?.userName ?? '';
      final likedTracks = ref.read(userLikedTracksProvider(username));

      likedTracks.whenData((list) {
        final liked = list.any((t) => t.trackId == widget.track.trackId);
        if (mounted) {
          setState(() => isLiked = liked);
        }
      });
    });
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

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;

    final username = ref.read(authProvider).user?.userName ?? '';
    if (username.isEmpty) return;

    final currentlyLiked = isLiked;

    setState(() {
      isLiked = !currentlyLiked; // optimistic UI
      _isTogglingLike = true;
    });

    try {
      await ref
          .read(toggleTrackLikeProvider(widget.track.trackId).notifier)
          .toggle(currentlyLiked: currentlyLiked, username: username);

      // IMPORTANT:
      // nothing else needed if provider updates liked list correctly
    } catch (_) {
      // revert on failure
      if (mounted) {
        setState(() => isLiked = currentlyLiked);
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingLike = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, playerStateSnapshot) {
        final isPlaying = playerStateSnapshot.data?.playing ?? false;

        if (!_initializedControls) {
          showControls = !isPlaying;
          _initializedControls = true;
        }

        return StreamBuilder<Duration>(
          stream: widget.player.positionStream,
          initialData: widget.player.position,
          builder: (context, positionSnapshot) {
            final currentPosition = positionSnapshot.data ?? Duration.zero;

            final totalDuration =
                widget.player.duration ??
                Duration(seconds: widget.track.durationSeconds ?? 0);

            final progress = totalDuration.inMilliseconds > 0
                ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
                : 0.0;

            final elapsed = currentPosition.inSeconds;
            final totalSeconds = totalDuration.inSeconds > 0
                ? totalDuration.inSeconds
                : widget.track.durationSeconds ?? 0;

            return Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                onTap: showControls
                    ? null
                    : () => setState(() => showControls = true),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.3, -0.3),
                          radius: 1.3,
                          colors: [
                            Color(0xFF8B1A1A),
                            Color(0xFF3A0808),
                            Color(0xFF0D0303),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimensions.spaceMedium),
                          Text(
                            widget.track.title,
                            style: AppTextStyles.heading2,
                          ),
                          Text(
                            widget.track.artist?.displayName ??
                                'Unknown Artist',
                          ),

                          const Spacer(),

                          _buildBottomBar(elapsed, totalSeconds),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    if (showControls)
                      Positioned.fill(
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 60,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              widget.onPlayPause();
                              setState(() => showControls = false);
                            },
                          ),
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
  }

  Widget _buildBottomBar(int elapsed, int totalSeconds) {
    final likeCount = widget.track.likeCount ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Text(isLiked ? '${likeCount + 1}' : '$likeCount'),
            ],
          ),
        ),
      ],
    );
  }
}
