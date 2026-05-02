import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/message.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Message.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'content': 'Hello!',
        'created_at': '2024-01-01T12:00:00.000Z',
        'is_read': true,
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg-1');
      expect(message.senderId, 'user-1');
      expect(message.content, 'Hello!');
      expect(message.isRead, true);
    });

    test('defaults missing content and isRead', () {
      final json = {'id': 'msg-1'};

      final message = Message.fromJson(json);

      expect(message.id, 'msg-1');
      expect(message.senderId, isNull);
      expect(message.content, '');
      expect(message.isRead, false);
    });

    test('parses createdAt as String', () {
      final json = {'id': 'msg-1', 'created_at': '2024-06-15T12:00:00.000Z'};

      final message = Message.fromJson(json);

      expect(message.createdAt, '2024-06-15T12:00:00.000Z');
    });

    test('createdAt is null when missing', () {
      final json = {'id': 'msg-1'};

      final message = Message.fromJson(json);

      expect(message.createdAt, isNull);
    });

    test('parses track reference', () {
      final json = {
        'id': 'msg-1',
        'track_id': 'track-1',
        'track': {
          'track_id': 'track-1',
          'title': 'Song',
          'stream_url': 'https://example.com/stream',
        },
      };

      final message = Message.fromJson(json);

      expect(message.trackId, 'track-1');
    });

    test('parses playlist reference', () {
      final json = {'id': 'msg-1', 'playlist_id': 'playlist-1'};

      final message = Message.fromJson(json);

      expect(message.playlistId, 'playlist-1');
    });
  });
}
