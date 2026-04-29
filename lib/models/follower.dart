// models/follower.dart

/// Represents a single follower entry.
/// Mapped from the API's FollowerListResponse → items[].
///
/// ⚠️  NOTE: The OpenAPI spec only references the schema by name
/// (`FollowerListResponse`, `FollowingListResponse`) without expanding the
/// fields.  The model below uses the fields that are universally present in
/// social-graph APIs of this type.  Adjust field names to match your actual
/// backend once you inspect a live response or the full schema.
class Follower {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool? isFollowing; // whether *the current user* follows them back

  const Follower({
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.isFollowing,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isFollowing: json['is_following'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    if (displayName != null) 'display_name': displayName,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (bio != null) 'bio': bio,
    if (isFollowing != null) 'is_following': isFollowing,
  };

  Follower copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isFollowing,
  }) {
    return Follower(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Follower &&
          runtimeType == other.runtimeType &&
          username == other.username;

  @override
  int get hashCode => username.hashCode;
}

// ─── FollowerListResponse wrapper ─────────────────────────────────────────────

class FollowerListResponse {
  final List<Follower> followers;
  final int? total;

  const FollowerListResponse({required this.followers, this.total});

  factory FollowerListResponse.fromJson(Map<String, dynamic> json) {
    final List raw = json['followers'] as List? ?? [];
    return FollowerListResponse(
      followers: raw
          .map((e) => Follower.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int?,
    );
  }
}

// ─── FollowingListResponse wrapper ───────────────────────────────────────────

/// "Following" entries share the same shape as followers in most APIs.
/// Reuse [Follower] and wrap in a dedicated response class for type-safety.
class FollowingListResponse {
  final List<Follower> following;
  final int? total;

  const FollowingListResponse({required this.following, this.total});

  factory FollowingListResponse.fromJson(Map<String, dynamic> json) {
    final List raw = json['following'] as List? ?? [];
    return FollowingListResponse(
      following: raw
          .map((e) => Follower.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int?,
    );
  }
}
