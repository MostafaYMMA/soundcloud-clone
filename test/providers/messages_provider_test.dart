import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/providers/messages_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('ConversationsNotifier', () {
    test('can be instantiated', () {
      final notifier = ConversationsNotifier();
      expect(notifier, isNotNull);
    });
  });

  group('MessagesNotifier', () {
    test('can be instantiated for a conversation', () {
      final notifier = MessagesNotifier();
      expect(notifier, isNotNull);
    });
  });
}
