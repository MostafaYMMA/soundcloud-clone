class Comment {
  final String id;
  final String trackId;
  final String userId;
  final String userDisplayName;
  final String? userProfilePicture;
  final String content;
  final int? timestampInTrack;
  final String? parentCommentId;
  final List<Comment> replies;
  final String createdAt;

  Comment({
    required this.id,
    required this.trackId,
    required this.userId,
    required this.userDisplayName,
    this.userProfilePicture,
    required this.content,
    this.timestampInTrack,
    this.parentCommentId,
    this.replies = const [],
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // API returns comment_id, fallback to id for safety
      id: json['comment_id']?.toString() ?? json['id']?.toString() ?? '',
      trackId: json['track_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      // API doesn't return display_name — use username or fallback
      userDisplayName:
          json['display_name']?.toString() ??
          json['username']?.toString() ??
          'Unknown',
      userProfilePicture:
          json['profile_picture']?.toString() ?? json['avatar_url']?.toString(),
      content: json['content']?.toString() ?? '',
      timestampInTrack: json['timestamp_in_track'] as int?,
      parentCommentId: json['parent_comment_id']?.toString(),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': id,
      'track_id': trackId,
      'user_id': userId,
      'display_name': userDisplayName,
      'profile_picture': userProfilePicture,
      'content': content,
      'timestamp_in_track': timestampInTrack,
      'parent_comment_id': parentCommentId,
      'replies': replies.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}
