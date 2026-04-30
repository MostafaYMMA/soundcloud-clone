import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_text_styles.dart';
import '../../models/follower.dart';
import '../../providers/followers_provider.dart';
import 'widgets/user_tile.dart';
import 'true_friends_screen.dart';

class FollowingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const FollowingScreen({super.key, this.onBack});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.toLowerCase().trim(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Follower> _applySearch(List<Follower> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((f) {
      final name = (f.displayName ?? f.username ?? f.userId).toLowerCase();
      final user = (f.username ?? f.userId).toLowerCase();
      return name.contains(_searchQuery) || user.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(myFollowingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          onPressed: () => widget.onBack?.call(),
        ),
        title: const Text('Following', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMedium,
              vertical: AppDimensions.spaceSmall,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search following...',
                hintStyle: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceSmall,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusPill,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Rest of the content ────────────────────────────────────
          Expanded(
            child: followingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: AppColors.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: AppDimensions.spaceSmall),
                    Text(
                      err.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceMedium),
                    TextButton(
                      onPressed: () => ref.invalidate(myFollowingProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

              data: (response) {
                final filtered = _applySearch(response.following);

                return CustomScrollView(
                  slivers: [
                    // ── "People who follow you back" banner ────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.spaceMedium,
                          0,
                          AppDimensions.spaceMedium,
                          AppDimensions.spaceMedium,
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrueFriendsScreen(
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceMedium,
                              vertical: AppDimensions.spaceMedium,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusSmall,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textSecondary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.group_outlined,
                                    color: AppColors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(
                                  width: AppDimensions.spaceMedium,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'People who follow you back',
                                        style: AppTextStyles.trackTitle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'See your true friends',
                                        style: AppTextStyles.artistName,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Empty state ────────────────────────────────
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'You are not following anyone yet.'
                                : 'No results for "$_searchQuery".',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      // ── Following list ─────────────────────────
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final follower = filtered[index];

                          // Build the key — username may be null from this endpoint
                          // so we fall back to an empty string (button will be disabled)
                          final followKey = follower.username != null
                              ? (
                                  userId: follower.userId,
                                  username: follower.username!,
                                )
                              : null;

                          final followState = followKey != null
                              ? ref.watch(followProvider(followKey))
                              : null;

                          return UserTile(
                            avatarUrl: follower.avatarUrl,
                            userName:
                                follower.displayName ??
                                follower.username ??
                                follower.userId,
                            location: null,
                            followers: null,
                            isFollowing: followState?.isFollowing ?? false,
                            isFollowLoading: followState?.isLoading ?? false,
                            onFollowTap: followKey == null
                                ? null
                                : () => ref
                                      .read(followProvider(followKey).notifier)
                                      .toggle(),
                            onTap: () {},
                          );
                        }, childCount: filtered.length),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
