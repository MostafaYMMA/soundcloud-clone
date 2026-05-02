import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/models/notification.dart';
import 'package:my_project/providers/notifications_provider.dart';
import 'package:my_project/services/notifications_service.dart';

class MockNotificationsService extends Mock implements NotificationsService {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('NotificationsNotifier', () {
    late MockNotificationsService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockNotificationsService();
      container = ProviderContainer(
        overrides: [
          notificationsServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    test('build fetches notifications', () async {
      final notifications = [
        AppNotification(
          id: 'notif-1',
          type: 'follow',
          message: 'User followed you',
          isRead: false,
          createdAt: '2024-01-01T10:00:00Z',
        ),
      ];

      when(() => mockService.getNotifications())
          .thenAnswer((_) async => notifications);

      final result = await container.read(notificationsProvider.future);

      expect(result.length, 1);
      expect(result[0].id, 'notif-1');
    });

    test('build throws on service error', () async {
      when(() => mockService.getNotifications())
          .thenThrow(Exception('Network error'));

      expect(
        () => container.read(notificationsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('markAsRead updates notification locally', () async {
      final notifications = [
        AppNotification(
          id: 'notif-1',
          type: 'follow',
          message: 'User followed you',
          isRead: false,
          createdAt: '2024-01-01T10:00:00Z',
        ),
      ];

      when(() => mockService.getNotifications())
          .thenAnswer((_) async => notifications);
      when(() => mockService.markNotificationAsRead(id: 'notif-1'))
          .thenAnswer((_) async {});
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 0);

      final notifier = container.read(notificationsProvider.notifier);

      await notifier.markAsRead('notif-1');

      final state = container.read(notificationsProvider);
      expect(state, isA<AsyncData>());
    });

    test('markAllAsRead updates all notifications', () async {
      final notifications = [
        AppNotification(
          id: 'notif-1',
          type: 'follow',
          message: 'User followed you',
          isRead: false,
          createdAt: '2024-01-01T10:00:00Z',
        ),
        AppNotification(
          id: 'notif-2',
          type: 'like',
          message: 'User liked your track',
          isRead: false,
          createdAt: '2024-01-01T11:00:00Z',
        ),
      ];

      when(() => mockService.getNotifications())
          .thenAnswer((_) async => notifications);
      when(() => mockService.markAllAsRead())
          .thenAnswer((_) async {});
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 0);

      final notifier = container.read(notificationsProvider.notifier);

      await notifier.markAllAsRead();

      final state = container.read(notificationsProvider);
      expect(state, isA<AsyncData>());
    });

    test('deleteNotification removes from list', () async {
      final notifications = [
        AppNotification(
          id: 'notif-1',
          type: 'follow',
          message: 'User followed you',
          isRead: false,
          createdAt: '2024-01-01T10:00:00Z',
        ),
      ];

      when(() => mockService.getNotifications())
          .thenAnswer((_) async => notifications);
      when(() => mockService.deleteNotification(id: 'notif-1'))
          .thenAnswer((_) async {});
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 0);

      final notifier = container.read(notificationsProvider.notifier);

      await notifier.deleteNotification('notif-1');

      final state = container.read(notificationsProvider);
      expect(state, isA<AsyncData>());
    });

    test('refresh reloads notifications', () async {
      final notifications = [
        AppNotification(
          id: 'notif-1',
          type: 'follow',
          message: 'User followed you',
          isRead: false,
          createdAt: '2024-01-01T10:00:00Z',
        ),
      ];

      when(() => mockService.getNotifications())
          .thenAnswer((_) async => notifications);
      when(() => mockService.getUnreadCount()).thenAnswer((_) async => 0);

      final notifier = container.read(notificationsProvider.notifier);

      await notifier.refresh();

      final state = container.read(notificationsProvider);
      expect(state, isA<AsyncData>());
      verify(() => mockService.getNotifications()).called(greaterThan(1));
    });
  });
}
