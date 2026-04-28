import 'package:flutter/material.dart';
import 'package:my_project/constants/app_colors.dart';
import 'package:my_project/constants/app_dimensions.dart';
import 'package:my_project/constants/app_text_styles.dart';

class VibeScreen extends StatelessWidget {
  final String vibe;

  const VibeScreen({super.key, required this.vibe});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vibe),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spaceExtraLarge),
                  Text(
                    vibe,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spaceExtraLarge),

            const TabBar(
              labelColor: AppColors.textPrimary,
              labelStyle: AppTextStyles.button,
              dividerColor: AppColors.background,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              overlayColor: WidgetStatePropertyAll(
                  AppColors.background,
                ),
              tabs: [
                Tab(text: "All"),
                Tab(text: "Trending"),
                Tab(text: "Playlists"),
                Tab(text: "Albums"),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceMedium),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceLarge,
                ),
                child: const TabBarView(
                  children: [
                    Center(child: Text("Top content")),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trending',
                          style: AppTextStyles.heading1,
                        )
                      ],
                    ),
                    Center(child: Text("Artists content")),
                    Center(child: Text("Albums content")),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}