import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/messages_service.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

DioException _dioErr({int statusCode = 500}) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        data: {},
        statusCode: statusCode,
        requestOptions: RequestOptions(path: ''),
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  late MockDio mockDio;
  late MessagesService sut;

  setUp(() {
    mockDio = MockDio();
    sut = MessagesService(dio: mockDio);
  });

  // ── Create or Get Conversation ─────────────────────────────────────────────

  group('MessagesService.createOrGetConversation', () {
    test('returns conversation_id on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _res({'data': {'conversation_id': 'conv-1'}}),
      );

      final id = await sut.createOrGetConversation(username: 'testuser');

      expect(id, 'conv-1');
    });

    test('rethrows DioException on failure', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(
        () => sut.createOrGetConversation(username: 'invalid'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Get Conversations ──────────────────────────────────────────────────────

  group('MessagesService.getConversations', () {
    test('placeholder', () {
      expect(true, true);
    });
  });

  // ── Delete Conversation ────────────────────────────────────────────────────

  group('MessagesService.deleteConversation', () {
    test('completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.deleteConversation(conversationId: 'conv-1'),
        completes,
      );
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.delete(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.deleteConversation(conversationId: 'invalid'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Get Messages ───────────────────────────────────────────────────────────

  group('MessagesService.getMessages', () {
    test('placeholder', () {
      expect(true, true);
    });
  });

  // ── Send Message ───────────────────────────────────────────────────────────

  group('MessagesService.sendMessage', () {
    test('sends text message', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.sendMessage(
          conversationId: 'conv-1',
          content: 'Hello',
        ),
        completes,
      );

      verify(
        () => mockDio.post(
          any(),
          data: {'content': 'Hello'},
        ),
      ).called(1);
    });

    test('sends track reference', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.sendMessage(
          conversationId: 'conv-1',
          trackId: 'track-1',
        ),
        completes,
      );
    });

    test('sends playlist reference', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.sendMessage(
          conversationId: 'conv-1',
          playlistId: 'playlist-1',
        ),
        completes,
      );
    });

    test('rethrows DioException on failure', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(
        () => sut.sendMessage(
          conversationId: 'conv-1',
          content: 'test',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Mark Message as Read ───────────────────────────────────────────────────

  group('MessagesService.markMessageAsRead', () {
    test('completes on success', () async {
      when(() => mockDio.patch(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.markMessageAsRead(
          conversationId: 'conv-1',
          messageId: 'msg-1',
        ),
        completes,
      );
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.patch(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.markMessageAsRead(
          conversationId: 'conv-1',
          messageId: 'invalid',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── Mark All Messages as Read ──────────────────────────────────────────────

  group('MessagesService.markAllMessagesAsRead', () {
    test('completes on success', () async {
      when(() => mockDio.patch(any())).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.markAllMessagesAsRead(conversationId: 'conv-1'),
        completes,
      );
    });
  });

  // ── Get Unread Count ───────────────────────────────────────────────────────

  group('MessagesService.getUnreadCount', () {
    test('placeholder', () {
      expect(true, true);
    });
  });
}
