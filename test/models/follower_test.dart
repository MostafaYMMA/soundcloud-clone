import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/follower.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Follower.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'user_id': 'user-1',
        'username': 'testuser',
        'display_name': 'Test User',
        'profile_picture': 'https://example.com/pic.jpg',
        'bio': 'A test user',
        'is_following': true,
        'is_premium': false,
        'followed_at': '2024-01-01T12:00:00.000Z',
      };

      final follower = Follower.fromJson(json);

      expect(follower.userId, 'user-1');
      expect(follower.username, 'testuser');
      expect(follower.displayName, 'Test User');
      expect(follower.avatarUrl, 'https://example.com/pic.jpg');
      expect(follower.bio, 'A test user');
      expect(follower.isFollowing, true);
      expect(follower.isPremium, false);
    });

    test('defaults missing optional fields', () {
      final json = {'user_id': 'user-1'};

      final follower = Follower.fromJson(json);

      expect(follower.userId, 'user-1');
      expect(follower.username, isNull);
      expect(follower.displayName, isNull);
      expect(follower.avatarUrl, isNull);
      expect(follower.isFollowing, isNull);
    });

    test('parses avatar from profile_picture or avatar_url', () {
      final json1 = {
        'user_id': 'u1',
        'profile_picture': 'https://example.com/profile.jpg',
      };
      final json2 = {
        'user_id': 'u2',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final follower1 = Follower.fromJson(json1);
      final follower2 = Follower.fromJson(json2);

      expect(follower1.avatarUrl, 'https://example.com/profile.jpg');
      expect(follower2.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('parses username from username or user_name', () {
      final json1 = {'user_id': 'u1', 'username': 'user1'};
      final json2 = {'user_id': 'u2', 'user_name': 'user2'};

      final follower1 = Follower.fromJson(json1);
      final follower2 = Follower.fromJson(json2);

      expect(follower1.username, 'user1');
      expect(follower2.username, 'user2');
    });

    test('apiIdentifier returns username when available', () {
      final json = {'user_id': 'id-123', 'username': 'testuser'};

      final follower = Follower.fromJson(json);

      expect(follower.apiIdentifier, 'testuser');
    });

    test('apiIdentifier returns userId when username missing', () {
      final json = {'user_id': 'id-123'};

      final follower = Follower.fromJson(json);

      expect(follower.apiIdentifier, 'id-123');
    });
  });

  group('Follower.copyWith', () {
    late Follower original;

    setUp(() {
      original = const Follower(
        userId: 'user-1',
        username: 'testuser',
        displayName: 'Test User',
        isFollowing: false,
      );
    });

    test('updates isFollowing', () {
      final updated = original.copyWith(isFollowing: true);

      expect(updated.isFollowing, true);
      expect(updated.userId, original.userId);
      expect(updated.username, original.username);
    });

    test('updates displayName', () {
      final updated = original.copyWith(displayName: 'Updated User');

      expect(updated.displayName, 'Updated User');
      expect(updated.userId, original.userId);
    });

    test('preserves all fields when nothing updated', () {
      final updated = original.copyWith();

      expect(updated.userId, original.userId);
      expect(updated.username, original.username);
      expect(updated.displayName, original.displayName);
      expect(updated.isFollowing, original.isFollowing);
    });
  });

  group('Follower equality', () {
    test('considers two followers equal if userId matches', () {
      final follower1 = Follower(userId: 'user-1', username: 'user1');
      final follower2 = Follower(userId: 'user-1', username: 'different');

      expect(follower1, follower2);
    });

    test('considers followers not equal if userId differs', () {
      final follower1 = Follower(userId: 'user-1', username: 'user1');
      final follower2 = Follower(userId: 'user-2', username: 'user1');

      expect(follower1, isNot(follower2));
    });
  });

  group('FollowerListResponse.fromJson', () {
    test('parses follower list', () {
      final json = {
        'followers': [
          {'user_id': 'u1', 'username': 'user1'},
          {'user_id': 'u2', 'username': 'user2'},
        ],
        'count': 2,
      };

      final response = FollowerListResponse.fromJson(json);

      expect(response.followers.length, 2);
      expect(response.followers[0].userId, 'u1');
      expect(response.count, 2);
    });

    test('handles items field as fallback', () {
      final json = {
        'items': [
          {'user_id': 'u1', 'username': 'user1'},
        ],
      };

      final response = FollowerListResponse.fromJson(json);

      expect(response.followers.length, 1);
    });

    test('handles empty follower list', () {
      final json = {'followers': []};

      final response = FollowerListResponse.fromJson(json);

      expect(response.followers, []);
    });
  });

  group('FollowingListResponse.fromJson', () {
    test('parses following list', () {
      final json = {
        'following': [
          {'user_id': 'u1', 'username': 'user1'},
        ],
        'count': 1,
      };

      final response = FollowingListResponse.fromJson(json);

      expect(response.following.length, 1);
      expect(response.following[0].userId, 'u1');
    });

    test('handles items field as fallback', () {
      final json = {
        'items': [
          {'user_id': 'u1', 'username': 'user1'},
        ],
      };

      final response = FollowingListResponse.fromJson(json);

      expect(response.following.length, 1);
    });
  });
}
