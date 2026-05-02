import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/models/auth_token.dart';
import 'package:my_project/models/user.dart';
import 'package:my_project/providers/auth_providers.dart';
import 'package:my_project/services/auth_service.dart';
import 'package:my_project/services/user_profile_services.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────

class MockAuthService extends Mock implements AuthService {}

class MockUserService extends Mock implements UserService {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

// ─── Helpers ──────────────────────────────────────────────────────────────

final mockUser = User(
  id: 'user-1',
  email: 'test@example.com',
  userName: 'testuser',
  avatarUrl: null,
  bio: 'Test bio',
  followers: 10,
  following: 5,
);

final mockTokens = AuthTokens(
  accessToken: 'acc-token-123',
  refreshToken: 'ref-token-456',
);

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
  group('AuthNotifier', () {
    late MockAuthService mockAuthService;
    late MockUserService mockUserService;
    late MockSecureStorage mockStorage;
    late AuthNotifier authNotifier;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUserService = MockUserService();
      mockStorage = MockSecureStorage();

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockStorage.deleteAll())
          .thenAnswer((_) async {});

      authNotifier = AuthNotifier(mockAuthService, mockUserService, mockStorage);
    });

    // ── Bootstrap tests ───────────────────────────────────────────────────────

    group('_bootstrap', () {
      test('restores user session from storage', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'acc-123');
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'ref-123');
        when(() => mockUserService.getMe('acc-123'))
            .thenAnswer((_) async => mockUser);

        final notifier = AuthNotifier(mockAuthService, mockUserService, mockStorage);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.isLoggedIn, true);
        expect(notifier.state.user?.id, 'user-1');
      });

      test('clears storage on failed bootstrap', () async {
        when(() => mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'acc-123');
        when(() => mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => 'ref-123');
        when(() => mockUserService.getMe(any()))
            .thenThrow(_dioErr(statusCode: 401));

        final notifier = AuthNotifier(mockAuthService, mockUserService, mockStorage);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.isLoggedIn, false);
        verify(() => mockStorage.deleteAll()).called(1);
      });

      test('handles missing tokens', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final notifier = AuthNotifier(mockAuthService, mockUserService, mockStorage);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.isLoggedIn, false);
      });
    });

    // ── Register tests ────────────────────────────────────────────────────────

    group('register', () {
      test('sets success message on successful registration', () async {
        when(
          () => mockAuthService.register(
            email: any(named: 'email'),
            username: any(named: 'username'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
            accountType: any(named: 'accountType'),
          ),
        ).thenAnswer((_) async {});

        await authNotifier.register(
          email: 'new@example.com',
          username: 'newuser',
          password: 'pass123',
          displayName: 'New User',
        );

        expect(authNotifier.state.successMessage, isNotNull);
        expect(authNotifier.state.error, isNull);
      });

      test('sets error on registration failure', () async {
        when(
          () => mockAuthService.register(
            email: any(named: 'email'),
            username: any(named: 'username'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
            accountType: any(named: 'accountType'),
          ),
        ).thenThrow(_dioErr(statusCode: 422));

        await authNotifier.register(
          email: 'bad@example.com',
          username: 'baduser',
          password: 'pass',
          displayName: 'Bad User',
        );

        expect(authNotifier.state.error, isNotNull);
        expect(authNotifier.state.successMessage, isNull);
      });

      test('sets isLoading during registration', () async {
        when(
          () => mockAuthService.register(
            email: any(named: 'email'),
            username: any(named: 'username'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
            accountType: any(named: 'accountType'),
          ),
        ).thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 50)));

        final future = authNotifier.register(
          email: 'test@example.com',
          username: 'testuser',
          password: 'pass123',
          displayName: 'Test User',
        );

        expect(authNotifier.state.isLoading, true);
        await future;
      });
    });

    // ── Login tests ───────────────────────────────────────────────────────────

    group('login', () {
      test('logs in and saves tokens', () async {
        when(() => mockAuthService.login('user@test.com', 'pass123'))
            .thenAnswer((_) async => mockTokens);
        when(() => mockUserService.getMe('acc-token-123'))
            .thenAnswer((_) async => mockUser);

        await authNotifier.login('user@test.com', 'pass123');

        expect(authNotifier.state.isLoggedIn, true);
        expect(authNotifier.state.user?.id, 'user-1');
        verify(() => mockStorage.write(
          key: 'access_token',
          value: 'acc-token-123',
        )).called(1);
        verify(() => mockStorage.write(
          key: 'refresh_token',
          value: 'ref-token-456',
        )).called(1);
      });

      test('handles login failure', () async {
        when(() => mockAuthService.login('bad@test.com', 'wrong'))
            .thenThrow(_dioErr(statusCode: 401));

        await authNotifier.login('bad@test.com', 'wrong');

        expect(authNotifier.state.isLoggedIn, false);
        expect(authNotifier.state.error, isNotNull);
      });

      test('handles user fetch failure after token success', () async {
        when(() => mockAuthService.login('user@test.com', 'pass123'))
            .thenAnswer((_) async => mockTokens);
        when(() => mockUserService.getMe('acc-token-123'))
            .thenThrow(_dioErr(statusCode: 403));

        await authNotifier.login('user@test.com', 'pass123');

        expect(authNotifier.state.error, isNotNull);
      });
    });

    // ── Google Login tests ────────────────────────────────────────────────────

    group('googleLogin', () {
      test('logs in via Google and saves tokens', () async {
        when(() => mockAuthService.googleLogin('google-id-token'))
            .thenAnswer((_) async => mockTokens);
        when(() => mockUserService.getMe('acc-token-123'))
            .thenAnswer((_) async => mockUser);

        await authNotifier.googleLogin('google-id-token');

        expect(authNotifier.state.isLoggedIn, true);
        expect(authNotifier.state.user?.userName, 'testuser');
      });

      test('handles invalid Google token', () async {
        when(() => mockAuthService.googleLogin('invalid-token'))
            .thenThrow(_dioErr(statusCode: 400));

        await authNotifier.googleLogin('invalid-token');

        expect(authNotifier.state.isLoggedIn, false);
        expect(authNotifier.state.error, isNotNull);
      });
    });

    // ── Facebook Login tests ──────────────────────────────────────────────────

    group('facebookLogin', () {
      test('logs in via Facebook and saves tokens', () async {
        when(() => mockAuthService.facebookLogin('facebook-token'))
            .thenAnswer((_) async => mockTokens);
        when(() => mockUserService.getMe('acc-token-123'))
            .thenAnswer((_) async => mockUser);

        await authNotifier.facebookLogin('facebook-token');

        expect(authNotifier.state.isLoggedIn, true);
      });
    });

    // ── Verify Email tests ────────────────────────────────────────────────────

    group('verifyEmail', () {
      test('sets success message on verification', () async {
        when(() => mockAuthService.verifyEmail('token-123'))
            .thenAnswer((_) async {});

        await authNotifier.verifyEmail('token-123');

        expect(authNotifier.state.successMessage, isNotNull);
        expect(authNotifier.state.error, isNull);
      });

      test('sets error on invalid token', () async {
        when(() => mockAuthService.verifyEmail('bad-token'))
            .thenThrow(_dioErr(statusCode: 400));

        await authNotifier.verifyEmail('bad-token');

        expect(authNotifier.state.error, isNotNull);
      });
    });

    // ── Resend Verification tests ─────────────────────────────────────────────

    group('resendVerification', () {
      test('sets success message', () async {
        when(() => mockAuthService.resendVerification('test@example.com'))
            .thenAnswer((_) async {});

        await authNotifier.resendVerification('test@example.com');

        expect(authNotifier.state.successMessage, isNotNull);
      });
    });

    // ── Refresh Tokens tests ──────────────────────────────────────────────────

    group('refreshTokens', () {
      test('refreshes and saves new tokens', () async {
        authNotifier.state = AuthState(
          tokens: mockTokens,
          user: mockUser,
        );

        final newTokens = AuthTokens(
          accessToken: 'new-acc',
          refreshToken: 'new-ref',
        );

        when(() => mockAuthService.refreshTokens('ref-token-456'))
            .thenAnswer((_) async => newTokens);

        await authNotifier.refreshTokens();

        expect(authNotifier.state.tokens?.accessToken, 'new-acc');
        verify(() => mockStorage.write(
          key: 'access_token',
          value: 'new-acc',
        )).called(1);
      });


      test('does nothing when not logged in', () async {
        await authNotifier.refreshTokens();

        verifyNever(() => mockAuthService.refreshTokens(any()));
      });
    });

    // ── Logout tests ──────────────────────────────────────────────────────────

    group('logout', () {
      test('clears tokens and state', () async {
        authNotifier.state = AuthState(
          tokens: mockTokens,
          user: mockUser,
        );

        when(
          () => mockAuthService.logout(
            accessToken: 'acc-token-123',
            refreshToken: 'ref-token-456',
          ),
        ).thenAnswer((_) async {});

        await authNotifier.logout();

        expect(authNotifier.state.isLoggedIn, false);
        verify(() => mockStorage.delete(key: 'access_token')).called(1);
        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      });

      test('clears tokens even on logout API failure', () async {
        authNotifier.state = AuthState(
          tokens: mockTokens,
          user: mockUser,
        );

        when(
          () => mockAuthService.logout(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenThrow(_dioErr(statusCode: 500));

        await authNotifier.logout();

        expect(authNotifier.state.isLoggedIn, false);
      });
    });

    // ── Update Current User tests ─────────────────────────────────────────────

    group('updateCurrentUser', () {
      test('updates user while preserving tokens', () async {
        authNotifier.state = AuthState(
          tokens: mockTokens,
          user: mockUser,
        );

        final updatedUser = User(
          id: mockUser.id,
          email: mockUser.email,
          userName: 'updateduser',
          avatarUrl: mockUser.avatarUrl,
          bio: mockUser.bio,
          followers: mockUser.followers,
          following: mockUser.following,
        );
        authNotifier.updateCurrentUser(updatedUser);

        expect(authNotifier.state.user?.userName, 'updateduser');
        expect(authNotifier.state.tokens, mockTokens);
      });
    });

    // ── AuthState properties tests ────────────────────────────────────────────

    group('AuthState.isLoggedIn', () {
      test('returns true when tokens present', () {
        const state = AuthState(
          tokens: AuthTokens(
            accessToken: 'acc',
            refreshToken: 'ref',
          ),
        );
        expect(state.isLoggedIn, true);
      });

      test('returns false when tokens null', () {
        const state = AuthState();
        expect(state.isLoggedIn, false);
      });
    });
  });
}
