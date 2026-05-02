import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/models/user.dart';
import 'package:my_project/services/user_profile_services.dart';

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
  late UserService sut;

  setUp(() {
    mockDio = MockDio();
    sut = UserService(dio: mockDio);
  });

  group('UserService.getMe', () {
    test('returns current user', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => _res({
          'data': {
            'id': 'user-1',
            'email': 'user@example.com',
            'username': 'testuser',
          },
        }),
      );

      final user = await sut.getMe('token-123');

      expect(user.id, 'user-1');
      expect(user.email, 'user@example.com');
    });

    test('throws exception on authentication failure', () async {
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(() => sut.getMe('invalid-token'), throwsA(isA<DioException>()));
    });
  });

  group('UserService.getUserByUsername', () {
    test('returns user profile', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({
          'data': {
            'id': 'user-1',
            'username': 'testuser',
            'email': 'test@example.com',
          },
        }),
      );

      final user = await sut.getUserByUsername('testuser');

      expect(user.userName, 'testuser');
    });

    test('throws exception when user not found', () async {
      when(() => mockDio.get(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.getUserByUsername('nonexistent'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('UserService.updateMe', () {
    test('updates user profile', () async {
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'id': 'user-1', 'username': 'updated_user'},
        }),
      );

      final user = await sut.updateMe(
        accessToken: 'token',
        displayName: 'Updated User',
      );

      expect(user, isA<User>());
    });

    test('throws exception on update failure', () async {
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(
        () => sut.updateMe(accessToken: 'token', displayName: 'New Name'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('UserService.updatePrivacy', () {
    test('updates privacy setting', () async {
      when(
        () => mockDio.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'is_private': true},
        }),
      );

      final isPrivate = await sut.updatePrivacy(
        accessToken: 'token',
        isPrivate: true,
      );

      expect(isPrivate, true);
    });
  });

  group('UserService.getSocialLinks', () {
    test('returns social links', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => _res({
          'data': [
            {'platform': 'twitter', 'url': 'https://twitter.com/user'},
          ],
        }),
      );

      final links = await sut.getSocialLinks('token');

      expect(links.length, 1);
      expect(links[0]['platform'], 'twitter');
    });
  });

  group('UserService.updateSocialLinks', () {
    test('updates social links', () async {
      when(
        () => mockDio.put(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.updateSocialLinks(
          accessToken: 'token',
          socialLinks: [
            {'platform': 'twitter', 'url': 'https://twitter.com/user'},
          ],
        ),
        completes,
      );
    });
  });

  group('UserService.followUser', () {
    test('follows user', () async {
      when(
        () => mockDio.post(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.followUser(accessToken: 'token', username: 'testuser'),
        completes,
      );
    });
  });

  group('UserService.blockUser', () {
    test('blocks user', () async {
      when(
        () => mockDio.post(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _res({}));

      await expectLater(
        sut.blockUser(accessToken: 'token', username: 'testuser'),
        completes,
      );
    });
  });
}
