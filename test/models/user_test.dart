import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/user.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('User.fromJson', () {
    final fullJson = {
      'id': 'user-1',
      'email': 'test@example.com',
      'username': 'testuser',
      'avatar_url': 'https://example.com/avatar.jpg',
      'location': 'Cairo',
      'bio': 'Music lover',
      'followers': 200,
      'following': 50,
    };

    test('parses all standard fields', () {
      final user = User.fromJson(fullJson);
      expect(user.id, 'user-1');
      expect(user.email, 'test@example.com');
      expect(user.userName, 'testuser');
      expect(user.location, 'Cairo');
      expect(user.bio, 'Music lover');
      expect(user.followers, 200);
      expect(user.following, 50);
    });

    test('resolves absolute avatar_url unchanged', () {
      final user = User.fromJson(fullJson);
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('resolves relative avatar_url by prepending base URL', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['avatar_url'] = '/media/avatar.jpg';
      final user = User.fromJson(json);
      expect(user.avatarUrl, 'https://streamline-swp.duckdns.org/api/media/avatar.jpg');
    });

    test('resolves api/ prefixed avatar_url correctly', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['avatar_url'] = 'api/media/avatar.jpg';
      final user = User.fromJson(json);
      expect(user.avatarUrl, 'https://streamline-swp.duckdns.org/api/media/avatar.jpg');
    });

    test('avatarUrl is null when both avatar_url and profile_picture are absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('avatar_url');
      final user = User.fromJson(json);
      expect(user.avatarUrl, isNull);
    });

    test('falls back to profile_picture when avatar_url is absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('avatar_url')
        ..['profile_picture'] = 'https://example.com/pic.jpg';
      final user = User.fromJson(json);
      expect(user.avatarUrl, 'https://example.com/pic.jpg');
    });

    test('falls back to user_id key when id is absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('id')
        ..['user_id'] = 'uid-alt';
      final user = User.fromJson(json);
      expect(user.id, 'uid-alt');
    });

    test('falls back to display_name when username is absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('username')
        ..['display_name'] = 'Display Name';
      final user = User.fromJson(json);
      expect(user.userName, 'Display Name');
    });

    test('reads follower_count as alternative followers key', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('followers')
        ..['follower_count'] = 999;
      final user = User.fromJson(json);
      expect(user.followers, 999);
    });

    test('reads following_count as alternative following key', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('following')
        ..['following_count'] = 42;
      final user = User.fromJson(json);
      expect(user.following, 42);
    });

    test('parses followers from string representation', () {
      final json = Map<String, dynamic>.from(fullJson)..['followers'] = '150';
      final user = User.fromJson(json);
      expect(user.followers, 150);
    });

    test('followers is null for invalid string', () {
      final json = Map<String, dynamic>.from(fullJson)..['followers'] = 'not-a-number';
      final user = User.fromJson(json);
      expect(user.followers, isNull);
    });

    test('defaults email to empty string when missing', () {
      final user = User.fromJson({});
      expect(user.email, '');
    });

    test('id and userName are null when both alternatives are missing', () {
      final user = User.fromJson({'email': 'e@e.com'});
      expect(user.id, isNull);
      expect(user.userName, isNull);
    });

    test('avatarUrl is null for empty string', () {
      final json = Map<String, dynamic>.from(fullJson)..['avatar_url'] = '';
      final user = User.fromJson(json);
      expect(user.avatarUrl, isNull);
    });
  });
}
