import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/track_provider.dart';
import '../../models/user.dart';
import '../../models/track.dart';
import '../../models/playlist.dart';
import '../../screens/library/context_menu_sheet.dart';
import 'widgets/profile_header_section.dart';
import 'widgets/profile_completion_section.dart';
import 'widgets/profile_more_button.dart';
import 'widgets/profile_playlists_section.dart';
import 'widgets/profile_track_list_section.dart';
import 'edit_profile_screen.dart';
import 'playlist_detail_screen.dart';

const Color kBackgroundColor = Color(0xFF0F0F0F);

List<ProfileCompletionCardData> buildCompletionCards(User user) {
  final hasAvatar = user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
  final hasBio = user.bio != null && user.bio!.trim().isNotEmpty;
  const hasBanner = false;
  final hasName = user.userName != null && user.userName!.trim().isNotEmpty;
  const emailVerified = true;

  return [
    ProfileCompletionCardData(
      icon: Icons.camera_alt_outlined,
      title: 'Add a profile photo',
      description: 'Choose a photo to represent yourself on SoundCloud',
      buttonText: hasAvatar ? 'Edit photo' : 'Add photo',
      isCompleted: hasAvatar,
      showButton: true,
    ),
    ProfileCompletionCardData(
      icon: Icons.chat_bubble_outline,
      title: 'Add a bio',
      description: 'What should people know about you?',
      buttonText: hasBio ? 'Edit bio' : 'Add bio',
      isCompleted: hasBio,
      showButton: true,
    ),
    ProfileCompletionCardData(
      icon: Icons.image_outlined,
      title: 'Add a profile banner',
      description: 'Choose a banner to further personalize your profile',
      buttonText: hasBanner ? 'Edit banner' : 'Add banner',
      isCompleted: hasBanner,
      showButton: true,
    ),
    ProfileCompletionCardData(
      icon: Icons.email_outlined,
      title: 'Verify email',
      description: 'Go to your inbox and verify your account',
      buttonText: '',
      isCompleted: emailVerified,
      showButton: false,
    ),
    ProfileCompletionCardData(
      icon: Icons.person_outline,
      title: 'Add your name',
      description: "Add your name so your friends know it's you",
      buttonText: hasName ? 'Edit name' : 'Add name',
      isCompleted: hasName,
      showButton: true,
    ),
  ];
}

// ── Sealed type for mixed likes feed ──────────────────────────────────────────

sealed class _LikeItem {}

class _LikeTrack extends _LikeItem {
  final Track track;
  _LikeTrack(this.track);
}

class _LikePlaylist extends _LikeItem {
  final Playlist playlist;
  _LikePlaylist(this.playlist);
}

// ── Profile Screen ─────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.onTrackTap, this.onNavigate});

  final Future<void> Function(Track)? onTrackTap;
  final void Function(Widget)? onNavigate;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool isProfileSectionExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllSections());
  }

  void _loadAllSections() {
    final username = ref.read(authProvider).user?.userName;
    if (username == null || username.isEmpty) return;

    ref.read(playlistProvider.notifier).fetchUserPlaylists(username);
    ref.invalidate(userRepostsProvider(username));
    ref.invalidate(userLikedTracksProvider(username));
    ref.invalidate(userLikedPlaylistsProvider);
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (mounted) {
      final username = ref.read(authProvider).user?.userName;
      if (username != null && username.isNotEmpty) {
        ref.read(playlistProvider.notifier).fetchUserPlaylists(username);
      }
      setState(() {});
    }
  }

  void _openPlaylistDetail(Playlist playlist) {
    final screen = PlaylistDetailScreen(
      playlist: playlist,
      onTrackTap: widget.onTrackTap ?? (_) async {},
      // Pass onBack so the back button pops the sub-screen correctly
      // instead of navigating all the way back to login
      onBack: widget.onNavigate != null
          ? () => widget.onNavigate!(
              // Pop by pushing the profile screen itself back
              ProfileScreen(
                onTrackTap: widget.onTrackTap,
                onNavigate: widget.onNavigate,
              ),
            )
          : null,
    );

    if (widget.onNavigate != null) {
      widget.onNavigate!(screen);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  // ── Playlists section ──────────────────────────────────────────────────────

  Widget _buildPlaylistsSection() {
    final playlistState = ref.watch(playlistProvider);

    if (playlistState.isLoadingUserPlaylists) {
      return const _SectionLoadingPlaceholder(title: 'Playlists');
    }

    if (playlistState.userPlaylists.isEmpty) {
      return const _SectionEmptyPlaceholder(
        title: 'Playlists',
        message: 'No playlists yet',
      );
    }

    final username = ref.read(authProvider).user?.userName ?? '';
    final asTracks = playlistState.userPlaylists.map((p) {
      return Track(
        trackId: p.id,
        title: p.name,
        coverImageUrl: p.coverUrl.isNotEmpty ? p.coverUrl : null,
        streamUrl: '',
        visibility: 'public',
        processingStatus: '',
        playCount: 0,
        artist: TrackArtist(
          userId: p.userId,
          username: username,
          displayName: username,
          followerCount: 0,
        ),
      );
    }).toList();

    return ProfilePlaylistsSection(
      title: 'Playlists',
      tracks: asTracks,
      onTrackTap: (track) {
        final playlist = playlistState.userPlaylists.firstWhere(
          (p) => p.id == track.trackId,
          orElse: () => playlistState.userPlaylists.first,
        );
        _openPlaylistDetail(playlist);
      },
    );
  }

  // ── Reposts section ────────────────────────────────────────────────────────

  Widget _buildRepostsSection(String username) {
    final repostsAsync = ref.watch(userRepostsProvider(username));
    return repostsAsync.when(
      loading: () => const _SectionLoadingPlaceholder(title: 'Reposts'),
      error: (_, __) => const _SectionErrorPlaceholder(title: 'Reposts'),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _SectionEmptyPlaceholder(
            title: 'Reposts',
            message: 'No reposts yet',
          );
        }
        return ProfileTrackListSection(
          title: 'Reposts',
          showSeeAll: tracks.length > 3,
          tracks: tracks.take(3).toList(),
          onSeeAllTap: () {},
          onTrackTap: (t) => widget.onTrackTap?.call(t),
          onMoreTap: (t) => showTrackContextMenu(context, t),
        );
      },
    );
  }

  // ── Likes section — mixed tracks + playlists ───────────────────────────────

  Widget _buildLikesSection(String username) {
    final likedTracksAsync = ref.watch(userLikedTracksProvider(username));
    final likedPlaylistsAsync = ref.watch(userLikedPlaylistsProvider);

    if (likedTracksAsync.isLoading || likedPlaylistsAsync.isLoading) {
      return const _SectionLoadingPlaceholder(title: 'Likes');
    }

    final tracks = likedTracksAsync.valueOrNull ?? [];
    final playlists = likedPlaylistsAsync.valueOrNull ?? [];

    final List<_LikeItem> items = [
      ...tracks.map((t) => _LikeTrack(t)),
      ...playlists.map((p) => _LikePlaylist(p)),
    ];

    if (items.isEmpty) {
      return const _SectionEmptyPlaceholder(
        title: 'Likes',
        message: 'No liked tracks or playlists yet',
      );
    }

    final preview = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Likes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (items.length > 3)
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          itemCount: preview.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = preview[index];
            return switch (item) {
              _LikeTrack(:final track) => _LikeTrackRow(
                track: track,
                onTap: () => widget.onTrackTap?.call(track),
                onMoreTap: () => showTrackContextMenu(context, track),
              ),
              _LikePlaylist(:final playlist) => _LikePlaylistRow(
                playlist: playlist,
                onTap: () => _openPlaylistDetail(playlist),
              ),
            };
          },
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final size = MediaQuery.of(context).size;
    final double sectionGap = (size.height * 0.018).clamp(18.0, 26.0);

    if (user == null) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Text(
              'No profile data found',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final username = user.userName ?? '';
    final cards = buildCompletionCards(user);
    final completeCount = cards.where((c) => c.isCompleted).length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeaderSection(
                user: user,
                onBackPressed: () => Navigator.of(context).maybePop(),
                onMorePressed: () => showProfileMore(context, user: user),
                onEditPressed: _openEditProfile,
                onShufflePressed: () {},
                onPlayPressed: () {},
              ),
              SizedBox(height: sectionGap),
              ProfileCompletionSection(
                cards: cards,
                completeCount: completeCount,
                isExpanded: isProfileSectionExpanded,
                onToggleExpanded: () => setState(
                  () => isProfileSectionExpanded = !isProfileSectionExpanded,
                ),
                onCardButtonPressed: (_) => _openEditProfile(),
              ),
              SizedBox(height: sectionGap),
              _buildPlaylistsSection(),
              SizedBox(height: sectionGap),
              if (username.isNotEmpty) _buildRepostsSection(username),
              SizedBox(height: sectionGap),
              if (username.isNotEmpty) _buildLikesSection(username),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Like row widgets ───────────────────────────────────────────────────────────

class _LikeTrackRow extends StatelessWidget {
  const _LikeTrackRow({
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
            child:
                (track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty)
                ? Image.network(
                    track.coverImageUrl!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _ThumbPlaceholder(isTrack: true),
                  )
                : const _ThumbPlaceholder(isTrack: true),
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

class _LikePlaylistRow extends StatelessWidget {
  const _LikePlaylistRow({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

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
            child: playlist.coverUrl.isNotEmpty
                ? Image.network(
                    playlist.coverUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const _ThumbPlaceholder(isTrack: false),
                  )
                : const _ThumbPlaceholder(isTrack: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
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
                    playlist.owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: (screenWidth * 0.04).clamp(13.0, 15.0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount} tracks',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: (screenWidth * 0.037).clamp(12.0, 14.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // No 3 dots for playlists
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.isTrack});
  final bool isTrack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFF2A2A2A),
      child: Icon(
        isTrack ? Icons.music_note : Icons.queue_music,
        color: Colors.white54,
      ),
    );
  }
}

// ── Helper placeholder widgets ─────────────────────────────────────────────────

class _SectionLoadingPlaceholder extends StatelessWidget {
  const _SectionLoadingPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
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
    );
  }
}

class _SectionEmptyPlaceholder extends StatelessWidget {
  const _SectionEmptyPlaceholder({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SectionErrorPlaceholder extends StatelessWidget {
  const _SectionErrorPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Failed to load.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
