import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../../constants/app_text_styles.dart';

/// Base tile widget. All library sub-tiles compose this.
class LibraryTile extends StatelessWidget {
  final Widget leading;        // 52×52 artwork
  final String title;
  final String subtitle;       // artist / owner / platform
  final Widget? meta;          // optional third row (duration, track count…)
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const LibraryTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.meta,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.spaceSmall,
          horizontal: AppDimensions.spaceMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
              child: SizedBox(width: 52, height: 52, child: leading),
            ),

            const SizedBox(width: AppDimensions.spaceMedium),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: AppTextStyles.trackTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.trackArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (meta != null) ...[
                    const SizedBox(height: 2),
                    meta!,
                  ],
                ],
              ),
            ),

            // More button
            IconButton(
              onPressed: onMoreTap,
              icon: const Icon(Icons.more_horiz),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot-separated metadata row: "Artist Station · 3:01:16 · 50 tracks"
class TileMeta extends StatelessWidget {
  final List<String> parts;
  const TileMeta(this.parts, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      parts.where((p) => p.isNotEmpty).join(' · '),
      style: AppTextStyles.trackArtist.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Artwork image with a fallback placeholder.
class TileArtwork extends StatelessWidget {
  final String? url;
  final IconData placeholderIcon;

  const TileArtwork({
    super.key,
    required this.url,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(url!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.surface,
        child: Center(
          child: Icon(placeholderIcon, color: AppColors.textSecondary, size: 24),
        ),
      );
}