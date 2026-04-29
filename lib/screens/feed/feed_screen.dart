import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/constants/app_dimensions.dart';
import 'package:my_project/constants/app_text_styles.dart';
import 'package:my_project/providers/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final following = ref.watch(followingFeedProvider);
    final discover = ref.watch(discoverFeedProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text("Feed")),

        body: Column(
          children: [
            // ─── RESTORED ORIGINAL TAB BUTTONS ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceExtraLarge,
              ),
              decoration: const BoxDecoration(color: AppColors.background),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusPill,
                  ),
                  color: AppColors.surfaceLight,
                ),
                labelColor: AppColors.textPrimary,
                labelStyle: AppTextStyles.button,
                dividerColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceExtraLarge,
                ),
                overlayColor: const WidgetStatePropertyAll(
                  AppColors.background,
                ),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceSmall,
                        horizontal: AppDimensions.spaceMedium,
                      ),
                      child: Text('Following'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceSmall,
                        horizontal: AppDimensions.spaceMedium,
                      ),
                      child: Text('Discover'),
                    ),
                  ),
                ],
              ),
            ),

            // ─── FEED CONTENT ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // FOLLOWING
                  following.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                    data: (state) {
                      if (state.items.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Your Feed appears to be empty",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Follow some artists or like tracks and try again",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];

                          final image = item.coverImageUrl ?? '';
                          final title = item.title;
                          final artist = item.artist.displayName;

                          return _buildFeedItem(image, title, artist);
                        },
                      );
                    },
                  ),

                  // DISCOVER
                  discover.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                    data: (state) {
                      return PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];

                          final image = item.coverImageUrl ?? '';
                          final title = item.title;
                          final artist = item.artist.displayName;

                          return _buildFeedItem(image, title, artist);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TikTok-style feed item ───────────────────────────────────────────────
  Widget _buildFeedItem(String image, String title, String artist) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image.isNotEmpty
            ? Image.network(image, fit: BoxFit.cover)
            : Container(color: Colors.black),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),

        Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                artist,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: const [
              Icon(Icons.favorite, color: Colors.white, size: 32),
              SizedBox(height: 20),
              Icon(Icons.comment, color: Colors.white, size: 32),
              SizedBox(height: 20),
              Icon(Icons.share, color: Colors.white, size: 32),
            ],
          ),
        ),
      ],
    );
  }
}
