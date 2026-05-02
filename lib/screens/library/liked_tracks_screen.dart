import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_text_styles.dart';
import '../../models/track.dart';
import '../../providers/auth_providers.dart';
import '../../providers/track_provider.dart';
import '../../providers/liked_tracks_provider.dart';
import '../profile/widgets/profile_track_list_section.dart';
import 'context_menu_sheet.dart';

enum LikedTracksSortOption { recentlyAdded, firstAdded, trackName, artist }

class LikedTracksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final Future<void> Function(Track track) onTrackTap;
   final void Function(List<Track> tracks, int startIndex) onQueuePlay;
  const LikedTracksScreen({
    super.key, 
    this.onBack, 
    required this.onTrackTap,
    required this.onQueuePlay
    });

  @override
  ConsumerState<LikedTracksScreen> createState() => _LikedTracksScreenState();
}

class _LikedTracksScreenState extends ConsumerState<LikedTracksScreen> {
  LikedTracksSortOption _sortOption = LikedTracksSortOption.recentlyAdded;
  final TextEditingController _searchController = TextEditingController();
  bool _isShuffled = false;

  /// Ensures we only seed likedTracksProvider once per screen visit.
  /// Without this, every rebuild (including the one triggered by
  /// toggleLocal) calls setAll() with stale server data, stomping
  /// the optimistic heart toggle.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Track> _process(List<Track> source) {
    final query = _searchController.text.trim().toLowerCase();

    List<Track> result = query.isEmpty
        ? List.from(source)
        : source.where((t) {
            final titleMatch = t.title.toLowerCase().contains(query);
            final artistMatch = (t.artist?.displayName ?? '')
                .toLowerCase()
                .contains(query);
            return titleMatch || artistMatch;
          }).toList();

    switch (_sortOption) {
      case LikedTracksSortOption.recentlyAdded:
        break;
      case LikedTracksSortOption.firstAdded:
        result = result.reversed.toList();
        break;
      case LikedTracksSortOption.trackName:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case LikedTracksSortOption.artist:
        result.sort(
          (a, b) => (a.artist?.displayName ?? '').compareTo(
            b.artist?.displayName ?? '',
          ),
        );
        break;
    }

    return result;
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusMedium),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceLarge,
          horizontal: AppDimensions.spaceMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by', style: AppTextStyles.heading2),
            const SizedBox(height: AppDimensions.spaceMedium),
            _SortOption(
              label: 'Recently Added',
              selected: _sortOption == LikedTracksSortOption.recentlyAdded,
              onTap: () {
                Navigator.pop(context);
                setState(
                  () => _sortOption = LikedTracksSortOption.recentlyAdded,
                );
              },
            ),
            _SortOption(
              label: 'First Added',
              selected: _sortOption == LikedTracksSortOption.firstAdded,
              onTap: () {
                Navigator.pop(context);
                setState(() => _sortOption = LikedTracksSortOption.firstAdded);
              },
            ),
            _SortOption(
              label: 'Track Name',
              selected: _sortOption == LikedTracksSortOption.trackName,
              onTap: () {
                Navigator.pop(context);
                setState(() => _sortOption = LikedTracksSortOption.trackName);
              },
            ),
            _SortOption(
              label: 'Artist',
              selected: _sortOption == LikedTracksSortOption.artist,
              onTap: () {
                Navigator.pop(context);
                setState(() => _sortOption = LikedTracksSortOption.artist);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authProvider).user?.userName;

    if (username == null || username.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'You are not logged in.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final likedTracksAsync = ref.watch(userLikedTracksProvider(username));

    return likedTracksAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (tracks) {
        // ── Seed only once so optimistic toggles are never stomped ────
        if (!_seeded) {
          _seeded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(likedTracksProvider.notifier)
                .setAll(tracks.map((t) => t.trackId).toSet());
          });
        }

        final displayed = _process(tracks);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () {
              // Reset seed flag so refreshed data re-syncs the Set
              _seeded = false;
              return ref.refresh(userLikedTracksProvider(username).future);
            },
            child: CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -10,
                        child: Icon(
                          Icons.favorite,
                          size: 220,
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () => widget.onBack?.call(),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Search your likes',
                                          hintStyle: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _showSortBottomSheet,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.borderRadiusPill,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.sort,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppDimensions.spaceSmall,
                                ),
                                child: Text(
                                  'Your likes (${displayed.length})',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                      Icons.shuffle,
                                      color: _isShuffled ? AppColors.primary : AppColors.textPrimary,
                                      size: 24,
                                      ),
                                      onPressed: () {
                                      setState(() => _isShuffled = !_isShuffled);
                                      if (displayed.isNotEmpty) {
                                      final shuffled = List<Track>.from(displayed)..shuffle();
                                      widget.onQueuePlay(shuffled, 0);
                                      }
                                    },
                                  ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: displayed.isEmpty ? null : () {
                                          widget.onQueuePlay(displayed, 0);
                                      },
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.black,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Track list ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: displayed.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text(
                              'No liked tracks yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                      : ProfileTrackListSection(
                          title: '',
                          tracks: displayed,
                          onTrackTap: (track) => widget.onTrackTap(track),
                          onMoreTap: (track) =>
                              showTrackContextMenu(context, track),
                        ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
