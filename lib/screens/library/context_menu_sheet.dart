import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_text_styles.dart';
import '../../models/track.dart';
import '../../providers/auth_providers.dart';
import '../../providers/liked_tracks_provider.dart';
import '../../providers/repost_provider.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/track_provider.dart';
import '../../providers/queue_provider.dart';
import '../profile/comments_screen.dart';
import '../profile/add_to_playlist_sheet.dart';

// ── Entry point helpers ──────────────────────────────────────────────────────

void showTrackContextMenu(
  BuildContext context,
  Track track, {
  VoidCallback? onGoToProfile,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _ContextMenuSheet.track(
      track: track,
      onGoToProfile: onGoToProfile,
      rootContext: context,
    ),
  );
}

void showCollectionContextMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _ContextMenuSheet.collection(rootContext: context),
  );
}

// ── Sheet ────────────────────────────────────────────────────────────────────

class _ContextMenuSheet extends ConsumerStatefulWidget {
  final Track? track;
  final VoidCallback? onGoToProfile;
  final BuildContext rootContext;

  const _ContextMenuSheet.track({
    required Track this.track,
    this.onGoToProfile,
    required this.rootContext,
  });
  const _ContextMenuSheet.collection({required this.rootContext})
    : track = null,
      onGoToProfile = null;

  bool get isTrack => track != null;

  @override
  ConsumerState<_ContextMenuSheet> createState() => _ContextMenuSheetState();
}

class _ContextMenuSheetState extends ConsumerState<_ContextMenuSheet> {
  bool _isLiking = false;
  bool _isReposting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.track?.isLiked == true) {
        final current = ref.read(likedTracksProvider);
        if (!current.contains(widget.track!.trackId)) {
          ref.read(likedTracksProvider.notifier).setAll({
            ...current,
            widget.track!.trackId,
          });
        }
      }
      if (widget.track?.isReposted == true) {
        final current = ref.read(repostedTracksProvider);
        if (!current.contains(widget.track!.trackId)) {
          ref.read(repostedTracksProvider.notifier).setAll({
            ...current,
            widget.track!.trackId,
          });
        }
      }
    });
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    if (widget.track == null || _isLiking) return;
    final trackId = widget.track!.trackId;
    final notifier = ref.read(likedTracksProvider.notifier);
    final wasLiked = ref.read(likedTracksProvider).contains(trackId);
    setState(() => _isLiking = true);
    notifier.toggleLocal(trackId); // optimistic

    // Read token directly to avoid stale engagementServiceProvider
    final token = ref.read(authProvider).tokens?.accessToken ?? '';
    debugPrint('Like token empty: ${token.isEmpty}');

    try {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      final url = wasLiked
          ? 'https://streamline-swp.duckdns.org/api/likes/tracks/$trackId'
          : 'https://streamline-swp.duckdns.org/api/likes/tracks/$trackId';
      if (wasLiked) {
        await dio.delete(url);
      } else {
        await dio.post(url);
      }
      debugPrint('Like success, wasLiked=$wasLiked');
    } catch (e) {
      notifier.toggleLocal(trackId); // rollback
      debugPrint('Like error: $e');
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  // ── Repost ────────────────────────────────────────────────────────────────

  Future<void> _toggleRepost() async {
    if (widget.track == null || _isReposting) return;
    final trackId = widget.track!.trackId;
    final notifier = ref.read(repostedTracksProvider.notifier);
    final wasReposted = ref.read(repostedTracksProvider).contains(trackId);
    setState(() => _isReposting = true);
    notifier.toggleLocal(trackId); // optimistic
    try {
      await ref
          .read(toggleRepostProvider(trackId).notifier)
          .toggle(currentlyReposted: wasReposted);
    } catch (e) {
      // 400 means "already reposted" or "not reposted" — keep optimistic state
      // Only rollback on auth errors (401/403)
      final msg = e.toString();
      if (msg.contains('not logged in') || msg.contains('permission')) {
        notifier.toggleLocal(trackId); // rollback only on auth error
      }
      debugPrint('Repost: $e');
    } finally {
      if (mounted) setState(() => _isReposting = false);
    }
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  String _trackUrl() =>
      'https://streamline-swp.duckdns.org/tracks/${widget.track?.trackId ?? ''}';

  void _dismissThen(VoidCallback action) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 350), action);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _trackUrl()));
    if (widget.rootContext.mounted) {
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _shareSms() async {
    final uri = Uri(scheme: 'sms', queryParameters: {'body': _trackUrl()});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _shareWhatsApp() async {
    final encoded = Uri.encodeComponent(_trackUrl());
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse('https://wa.me/?text=$encoded');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // Get the position of the widget for iOS share sheet
  Rect _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Rect.zero;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size;
  }

  Future<void> _shareSnapchat() async {
    try {
      await Share.share(
        _trackUrl(),
        subject: widget.track?.title ?? '',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _shareInstagram() async {
    try {
      await Share.share(
        _trackUrl(),
        subject: widget.track?.title ?? '',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  void _showQrCode() {
    final url = _trackUrl();
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!widget.rootContext.mounted) return;
      showDialog(
        context: widget.rootContext,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan to listen',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track?.title ?? '',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _shareMore() async {
    try {
      await Share.share(
        _trackUrl(),
        subject: widget.track?.title ?? '',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final likedIds = widget.isTrack
        ? ref.watch(likedTracksProvider)
        : const <String>{};
    final isLiked = widget.isTrack
        ? likedIds.contains(widget.track!.trackId)
        : false;
    final repostedIds = widget.isTrack
        ? ref.watch(repostedTracksProvider)
        : const <String>{};
    final isReposted = widget.isTrack
        ? repostedIds.contains(widget.track!.trackId)
        : false;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.borderRadiusMedium),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (widget.isTrack) _TrackHeader(track: widget.track!),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _ShareRow(
                      onCopyLink: _copyLink,
                      onSms: _shareSms,
                      onQrCode: _showQrCode,
                      onWhatsApp: _shareWhatsApp,
                      onInstagramStories: _shareInstagram,
                      onSnapchat: _shareSnapchat,
                      onMore: _shareMore,
                    ),
                    const _Divider(),

                    // Like
                    _MenuItem(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      iconColor: isLiked ? AppColors.primary : null,
                      label: isLiked ? 'Liked' : 'Like',
                      labelColor: isLiked ? AppColors.primary : null,
                      closeOnTap: false,
                      onTap: _toggleLike,
                    ),

                    if (widget.isTrack) ...[
                      // Play next
                      _MenuItem(
                        icon: Icons.queue_play_next,
                        label: 'Play next',
                        onTap: () {
                          ref
                              .read(queueProvider.notifier)
                              .playNext(widget.track!);
                        },
                      ),
                      // Play last
                      _MenuItem(
                        icon: Icons.add_to_queue,
                        label: 'Play last',
                        onTap: () {
                          ref
                              .read(queueProvider.notifier)
                              .playLast(widget.track!);
                        },
                      ),
                      // Add to playlist
                      _MenuItem(
                        icon: Icons.playlist_add,
                        label: 'Add to playlist',
                        closeOnTap: false,
                        onTap: () => _dismissThen(() {
                          if (widget.rootContext.mounted) {
                            showAddToPlaylistSheet(
                              widget.rootContext,
                              widget.track!,
                            );
                          }
                        }),
                      ),
                    ],

                    const _Divider(),

                    _MenuItem(
                      icon: Icons.person_outline,
                      label: 'Go to profile',
                      onTap: () {
                        if (widget.onGoToProfile != null) {
                          widget.onGoToProfile!();
                        }
                      },
                    ),

                    // View comments
                    if (widget.isTrack)
                      _MenuItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'View comments',
                        closeOnTap: false,
                        onTap: () => _dismissThen(() {
                          if (widget.rootContext.mounted) {
                            showCommentsScreen(
                              widget.rootContext,
                              widget.track!,
                            );
                          }
                        }),
                      ),

                    // Repost
                    _MenuItem(
                      icon: isReposted ? Icons.repeat_on : Icons.repeat,
                      iconColor: isReposted ? AppColors.primary : null,
                      label: isReposted ? 'Reposted' : 'Repost on SoundCloud',
                      labelColor: isReposted ? AppColors.primary : null,
                      closeOnTap: false,
                      onTap: _toggleRepost,
                    ),

                    const _Divider(),

                    _MenuItem(
                      icon: Icons.graphic_eq,
                      label: 'Behind this track',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.flag_outlined,
                      label: 'Report',
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Track header ─────────────────────────────────────────────────────────────

class _TrackHeader extends StatelessWidget {
  final Track track;
  const _TrackHeader({required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: AppDimensions.spaceMedium,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceLight.withOpacity(0.8),
            AppColors.background,
          ],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -8,
                  top: 8,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: Colors.grey.shade800, width: 1),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusSmall,
                  ),
                  child: (track.artworkUrl ?? '').isNotEmpty
                      ? Image.network(
                          track.artworkUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(72),
                        )
                      : _placeholder(72),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTextStyles.heading2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(track.formattedArtist, style: AppTextStyles.artistName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: AppColors.surfaceLight,
    child: const Icon(Icons.music_note, color: AppColors.textSecondary),
  );
}

// ── Share row ─────────────────────────────────────────────────────────────────

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.onCopyLink,
    required this.onSms,
    required this.onQrCode,
    required this.onWhatsApp,
    required this.onInstagramStories,
    required this.onSnapchat,
    required this.onMore,
  });

  final VoidCallback onCopyLink;
  final VoidCallback onSms;
  final VoidCallback onQrCode;
  final VoidCallback onWhatsApp;
  final VoidCallback onInstagramStories;
  final VoidCallback onSnapchat;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMedium,
        AppDimensions.spaceMedium,
        AppDimensions.spaceMedium,
        AppDimensions.spaceSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARE',
            style: AppTextStyles.artistName.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ShareButton(
                  icon: Icons.copy_outlined,
                  label: 'Copy link',
                  onTap: onCopyLink,
                ),
                _ShareButton(
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  onTap: onSms,
                ),
                _ShareButton(
                  icon: Icons.qr_code_2,
                  label: 'QR code',
                  onTap: onQrCode,
                ),
                _ShareButton(
                  customChild: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'W',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  label: 'WhatsApp',
                  onTap: onWhatsApp,
                ),
                _ShareButton(
                  customChild: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Color(0xFFF58529),
                          Color(0xFFDD2A7B),
                          Color(0xFF8134AF),
                          Color(0xFF515BD4),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  label: 'Stories',
                  onTap: onInstagramStories,
                ),
                _ShareButton(
                  customChild: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFC00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  label: 'Snapchat',
                  onTap: onSnapchat,
                ),
                _ShareButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: onMore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    this.icon,
    this.customChild,
    required this.label,
    required this.onTap,
  }) : assert(icon != null || customChild != null);

  final IconData? icon;
  final Widget? customChild;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppDimensions.spaceLarge),
        child: Column(
          children: [
            customChild ??
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 22),
                ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.artistName.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool closeOnTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.closeOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      title: Text(
        label,
        style: AppTextStyles.trackTitle.copyWith(
          color: labelColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: () {
        if (closeOnTap) Navigator.pop(context);
        onTap();
      },
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 0.5,
    color: AppColors.divider,
    indent: AppDimensions.spaceMedium,
    endIndent: AppDimensions.spaceMedium,
  );
}
