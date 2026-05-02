import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/notification.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('AppNotification.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'notif-1',
        'type': 'follow',
        'message': 'John followed you',
        'is_read': false,
        'created_at': '2024-01-01T12:00:00.000Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 'notif-1');
      expect(notification.type, 'follow');
      expect(notification.message, 'John followed you');
      expect(notification.isRead, false);
    });

    test('defaults missing fields', () {
      final json = {'id': 'notif-1'};

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 'notif-1');
      expect(notification.type, '');
      expect(notification.message, '');
      expect(notification.isRead, false);
    });

    test('parses isRead as boolean', () {
      final json1 = {'id': 'notif-1', 'is_read': true};
      final json2 = {'id': 'notif-2', 'is_read': false};

      final notif1 = AppNotification.fromJson(json1);
      final notif2 = AppNotification.fromJson(json2);

      expect(notif1.isRead, true);
      expect(notif2.isRead, false);
    });

    test('parses createdAt timestamp', () {
      final json = {
        'id': 'notif-1',
        'created_at': '2024-06-15T12:00:00.000Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.createdAt, '2024-06-15T12:00:00.000Z');
    });
  });
}
