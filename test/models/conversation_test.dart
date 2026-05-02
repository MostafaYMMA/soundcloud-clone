import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/conversation.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('Participant.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'user_id': 'user-1',
        'display_name': 'John Doe',
        'profile_picture': 'https://example.com/avatar.jpg',
      };

      final participant = Participant.fromJson(json);

      expect(participant.userId, 'user-1');
      expect(participant.displayName, 'John Doe');
      expect(participant.profilePicture, 'https://example.com/avatar.jpg');
    });

    test('defaults display_name to Unknown when missing', () {
      final json = {'user_id': 'user-1'};

      final participant = Participant.fromJson(json);

      expect(participant.displayName, 'Unknown');
    });
  });

  group('Conversation.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'conversation_id': 'conv-1',
        'created_at': '2024-01-01T12:00:00.000Z',
        'participants': [
          {
            'user_id': 'user-1',
            'display_name': 'John Doe',
            'profile_picture': null,
          },
        ],
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.conversationId, 'conv-1');
      expect(conversation.createdAt, '2024-01-01T12:00:00.000Z');
      expect(conversation.participants.length, 1);
      expect(conversation.participants[0].displayName, 'John Doe');
    });

    test('handles empty participants list', () {
      final json = {
        'conversation_id': 'conv-1',
        'created_at': '2024-01-01T12:00:00.000Z',
        'participants': [],
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.participants, []);
    });
  });
}
