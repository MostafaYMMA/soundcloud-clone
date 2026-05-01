import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_text_styles.dart';
import '../../models/track.dart';
import '../../models/comment.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/auth_providers.dart';

/// Opens the comments screen as a full-screen modal.
void showCommentsScreen(BuildContext context, Track track) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CommentsScreen(track: track),
    ),
  );
}

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.track});
  final Track track;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  // Quick reply chips matching the screenshot
  static const List<String> _quickReplies = [
    'i love this 🔥',
    'on repeat!!!',
    'this is my vibe 🎧',
    'more of this',
    'fire 🔥',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment(String content) async {
    if (content.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(commentsProvider(widget.track.trackId).notifier)
          .addComment(content: content.trim());
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _timeAgo(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      return '${diff.inMinutes}m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(commentsProvider(widget.track.trackId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMedium,
                vertical: 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // balance
                ],
              ),
            ),

            // ── Track header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMedium,
                vertical: 8,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: (widget.track.coverImageUrl?.isNotEmpty ?? false)
                        ? Image.network(
                            widget.track.coverImageUrl!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ArtPlaceholder(size: 52),
                          )
                        : _ArtPlaceholder(size: 52),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.track.formattedArtist,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats row ────────────────────────────────────────────
            commentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (comments) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMedium,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text('👏', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text('🥹', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.track.likeCount ?? 0}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${comments.length} comments',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${widget.track.repostCount ?? 0} reposts',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // ── Comments list ────────────────────────────────────────
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load comments',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceSmall,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return _CommentTile(
                        comment: comments[index],
                        formatTimestamp: _formatTimestamp,
                        timeAgo: _timeAgo,
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // ── Quick reply chips ────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMedium,
                  vertical: 6,
                ),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _sendComment(_quickReplies[index]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _quickReplies[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Comment input ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                left: AppDimensions.spaceMedium,
                right: AppDimensions.spaceMedium,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppDimensions.spaceMedium,
                top: 8,
              ),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: ref.watch(authProvider).user?.avatarUrl
                                ?.isNotEmpty ==
                            true
                        ? NetworkImage(
                            ref.watch(authProvider).user!.avatarUrl!,
                          )
                        : null,
                    child: ref.watch(authProvider).user?.avatarUrl?.isNotEmpty ==
                            true
                        ? null
                        : const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment at...',
                                hintStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '0:00',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: () => _sendComment(_commentController.text),
                    child: _isSending
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white70,
                            size: 26,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.formatTimestamp,
    required this.timeAgo,
  });

  final Comment comment;
  final String Function(int?) formatTimestamp;
  final String Function(String) timeAgo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMedium,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage:
                    (comment.userProfilePicture?.isNotEmpty ?? false)
                        ? NetworkImage(comment.userProfilePicture!)
                        : null,
                child: (comment.userProfilePicture?.isNotEmpty ?? false)
                    ? null
                    : const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + timestamp + time ago
                    Row(
                      children: [
                        Text(
                          comment.userDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (comment.timestampInTrack != null) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'at',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              formatTimestamp(comment.timestampInTrack),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          '· ${timeAgo(comment.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Comment text
                    Text(
                      comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Reply + more
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Like button
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.white38,
                  size: 18,
                ),
              ),
            ],
          ),

          // ── Replies ────────────────────────────────────────────────
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 10),
              child: Column(
                children: comment.replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.surfaceLight,
                          backgroundImage: (reply.userProfilePicture
                                      ?.isNotEmpty ??
                                  false)
                              ? NetworkImage(reply.userProfilePicture!)
                              : null,
                          child:
                              (reply.userProfilePicture?.isNotEmpty ?? false)
                                  ? null
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                      size: 14,
                                    ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    reply.userDisplayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '· ${timeAgo(reply.createdAt)}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                reply.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.white38,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceLight,
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }
}