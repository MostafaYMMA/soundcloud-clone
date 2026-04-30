import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/music_providers.dart';
import '../../models/user.dart';
import '../../models/track.dart';
import '../../models/playlist.dart';
import 'widgets/profile_header_section.dart';
import 'widgets/profile_completion_section.dart';
import 'widgets/profile_more_button.dart';
import 'widgets/profile_playlists_section.dart';
import 'widgets/profile_track_list_section.dart';
import 'edit_profile_screen.dart';
import 'playlist_detail_screen.dart';
import '../../providers/music_providers.dart';
import '../../providers/track_provider.dart';

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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.onTrackTap, this.onNavigate});

  /// Passed down from RootScreen via LibraryScreen — plays a track
  final Future<void> Function(Track)? onTrackTap;

  /// Passed down from RootScreen via LibraryScreen — pushes a sub-screen
  /// while keeping the mini player visible
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
    ref.invalidate(userTracksProvider(username));
    ref.invalidate(userLikedTracksProvider(username));
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

  /// Opens playlist detail. Uses onNavigate to keep mini player visible,
  /// falls back to Navigator.push if onNavigate wasn't provided.
  void _openPlaylistDetail(Playlist playlist) {
    final screen = PlaylistDetailScreen(
      playlist: playlist,
      onTrackTap: widget.onTrackTap ?? (_) async {},
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

    // Map Playlist → Track shape so ProfilePlaylistsSection can render cards
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
        // Match the tapped card back to its Playlist by id
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
    final tracksAsync = ref.watch(userTracksProvider(username));
    return tracksAsync.when(
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
          onMoreTap: (_) {},
        );
      },
    );
  }

  // ── Likes section ──────────────────────────────────────────────────────────

  Widget _buildLikesSection(String username) {
    final likedAsync = ref.watch(userLikedTracksProvider(username));
    return likedAsync.when(
      loading: () => const _SectionLoadingPlaceholder(title: 'Likes'),
      error: (_, __) => const _SectionErrorPlaceholder(title: 'Likes'),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const _SectionEmptyPlaceholder(
            title: 'Likes',
            message: 'No liked tracks yet',
          );
        }
        return ProfileTrackListSection(
          title: 'Likes',
          showSeeAll: tracks.length > 3,
          tracks: tracks.take(3).toList(),
          onSeeAllTap: () {},
          onTrackTap: (t) => widget.onTrackTap?.call(t),
          onMoreTap: (_) {},
        );
      },
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
