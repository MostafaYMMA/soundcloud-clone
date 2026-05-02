import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/comment.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Comment.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'comment-1',
        'content': 'Great track!',
        'user_id': 'user-1',
        'track_id': 'track-1',
        'display_name': 'John Doe',
        'timestamp_in_track': 60,
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 'comment-1');
      expect(comment.content, 'Great track!');
      expect(comment.userId, 'user-1');
      expect(comment.trackId, 'track-1');
      expect(comment.userDisplayName, 'John Doe');
      expect(comment.timestampInTrack, 60);
    });

    test('parses with profile picture', () {
      final json = {
        'id': 'c1',
        'user_id': 'u1',
        'track_id': 't1',
        'display_name': 'Jane',
        'content': 'Nice!',
        'profile_picture': 'https://example.com/pic.jpg',
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.userProfilePicture, 'https://example.com/pic.jpg');
    });

    test('handles optional timestamp_in_track', () {
      final json1 = {
        'id': 'c1',
        'user_id': 'u1',
        'track_id': 't1',
        'display_name': 'User',
        'content': 'Comment',
        'timestamp_in_track': 120,
        'created_at': '2024-01-01T12:00:00.000Z',
      };
      final json2 = {
        'id': 'c2',
        'user_id': 'u2',
        'track_id': 't2',
        'display_name': 'User 2',
        'content': 'Comment 2',
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final comment1 = Comment.fromJson(json1);
      final comment2 = Comment.fromJson(json2);

      expect(comment1.timestampInTrack, 120);
      expect(comment2.timestampInTrack, isNull);
    });

    test('handles parent_comment_id for replies', () {
      final json = {
        'id': 'reply-1',
        'user_id': 'u1',
        'track_id': 't1',
        'display_name': 'Replier',
        'content': 'Thanks!',
        'parent_comment_id': 'comment-1',
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.parentCommentId, 'comment-1');
    });

    test('parses nested replies', () {
      final json = {
        'id': 'comment-1',
        'user_id': 'u1',
        'track_id': 't1',
        'display_name': 'Author',
        'content': 'Great!',
        'created_at': '2024-01-01T12:00:00.000Z',
        'replies': [
          {
            'id': 'reply-1',
            'user_id': 'u2',
            'track_id': 't1',
            'display_name': 'Replier',
            'content': 'Thanks!',
            'created_at': '2024-01-01T12:05:00.000Z',
          },
        ],
      };

      final comment = Comment.fromJson(json);

      expect(comment.replies.length, 1);
      expect(comment.replies[0].content, 'Thanks!');
    });
  });
}
