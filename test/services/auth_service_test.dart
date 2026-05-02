import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/auth_service.dart';

class MockDio extends Mock implements Dio {}

// Helper to build a successful Dio Response
Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

// Helper to build a DioException
DioException _dioErr({int statusCode = 500, dynamic data}) => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        data: data ?? {},
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
  late AuthService sut;

  setUp(() {
    mockDio = MockDio();
    sut = AuthService(dio: mockDio);
  });

  // ── login ─────────────────────────────────────────────────────────────────

  group('AuthService.login', () {
    test('returns AuthTokens on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'access_token': 'acc', 'refresh_token': 'ref'},
        }),
      );

      final tokens = await sut.login('user@test.com', 'pass123');

      expect(tokens.accessToken, 'acc');
      expect(tokens.refreshToken, 'ref');
    });

    test('rethrows DioException on failure', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(() => sut.login('bad@test.com', 'wrong'), throwsA(isA<DioException>()));
    });
  });

  // ── register ──────────────────────────────────────────────────────────────

  group('AuthService.register', () {
    test('completes without error on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'registered'}));

      await expectLater(
        sut.register(
          email: 'new@example.com',
          username: 'newuser',
          password: 'secret',
          displayName: 'New User',
        ),
        completes,
      );
    });

    test('propagates DioException on failure', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 422));

      expect(
        () => sut.register(
          email: 'x@x.com',
          username: 'x',
          password: 'x',
          displayName: 'X',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ── verifyEmail ───────────────────────────────────────────────────────────

  group('AuthService.verifyEmail', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'ok'}));

      await expectLater(sut.verifyEmail('token123'), completes);
    });
  });

  // ── resendVerification ────────────────────────────────────────────────────

  group('AuthService.resendVerification', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'sent'}));

      await expectLater(sut.resendVerification('test@example.com'), completes);
    });
  });

  // ── googleLogin ───────────────────────────────────────────────────────────

  group('AuthService.googleLogin', () {
    test('returns AuthTokens on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'access_token': 'gacc', 'refresh_token': 'gref'},
        }),
      );

      final tokens = await sut.googleLogin('google-id-token');
      expect(tokens.accessToken, 'gacc');
      expect(tokens.refreshToken, 'gref');
    });

    test('rethrows DioException on failure', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(() => sut.googleLogin('bad-token'), throwsA(isA<DioException>()));
    });
  });

  // ── refreshTokens ─────────────────────────────────────────────────────────

  group('AuthService.refreshTokens', () {
    test('returns new AuthTokens on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => _res({
          'data': {'access_token': 'new-acc', 'refresh_token': 'new-ref'},
        }),
      );

      final tokens = await sut.refreshTokens('old-refresh');
      expect(tokens.accessToken, 'new-acc');
      expect(tokens.refreshToken, 'new-ref');
    });

    test('propagates DioException when refresh fails', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(() => sut.refreshTokens('expired-refresh'), throwsA(isA<DioException>()));
    });
  });

  // ── logout ────────────────────────────────────────────────────────────────

  group('AuthService.logout', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'logged out'}));

      await expectLater(
        sut.logout(accessToken: 'acc', refreshToken: 'ref'),
        completes,
      );
    });
  });

  // ── forgotPassword ────────────────────────────────────────────────────────

  group('AuthService.forgotPassword', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'sent'}));

      await expectLater(sut.forgotPassword('user@example.com'), completes);
    });
  });

  // ── resetPassword ─────────────────────────────────────────────────────────

  group('AuthService.resetPassword', () {
    test('completes on success', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => _res({'message': 'reset ok'}));

      await expectLater(sut.resetPassword('reset-token', 'newPass123'), completes);
    });

    test('propagates DioException on invalid token', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(_dioErr(statusCode: 400));

      expect(
        () => sut.resetPassword('bad-token', 'pass'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
