import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/models/auth_token.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('AuthTokens.fromJson', () {
    test('parses tokens from data wrapper', () {
      final tokens = AuthTokens.fromJson({
        'data': {'access_token': 'access123', 'refresh_token': 'refresh456'},
      });
      expect(tokens.accessToken, 'access123');
      expect(tokens.refreshToken, 'refresh456');
    });

    test('parses tokens from flat json without data wrapper', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'accessABC',
        'refresh_token': 'refreshXYZ',
      });
      expect(tokens.accessToken, 'accessABC');
      expect(tokens.refreshToken, 'refreshXYZ');
    });

    test('defaults access_token to empty string when missing', () {
      final tokens = AuthTokens.fromJson({
        'data': {'refresh_token': 'r'},
      });
      expect(tokens.accessToken, '');
    });

    test('defaults refresh_token to empty string when missing', () {
      final tokens = AuthTokens.fromJson({
        'data': {'access_token': 'a'},
      });
      expect(tokens.refreshToken, '');
    });

    test('handles empty data map', () {
      final tokens = AuthTokens.fromJson({'data': <String, dynamic>{}});
      expect(tokens.accessToken, '');
      expect(tokens.refreshToken, '');
    });
  });

  group('AuthTokens.toJson', () {
    test('serializes both tokens correctly', () {
      const tokens = AuthTokens(
        accessToken: 'myAccess',
        refreshToken: 'myRefresh',
      );
      final json = tokens.toJson();
      expect(json['access_token'], 'myAccess');
      expect(json['refresh_token'], 'myRefresh');
    });

    test('round-trips through fromJson and toJson', () {
      final original = {
        'data': {'access_token': 'a', 'refresh_token': 'r'},
      };
      final tokens = AuthTokens.fromJson(original);
      final json = tokens.toJson();
      expect(json['access_token'], 'a');
      expect(json['refresh_token'], 'r');
    });
  });

  group('AuthTokens.isValid', () {
    test('returns true when both tokens are non-empty', () {
      const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');
      expect(tokens.isValid, isTrue);
    });

    test('returns false when access_token is empty', () {
      const tokens = AuthTokens(accessToken: '', refreshToken: 'r');
      expect(tokens.isValid, isFalse);
    });

    test('returns false when refresh_token is empty', () {
      const tokens = AuthTokens(accessToken: 'a', refreshToken: '');
      expect(tokens.isValid, isFalse);
    });

    test('returns false when both tokens are empty', () {
      const tokens = AuthTokens(accessToken: '', refreshToken: '');
      expect(tokens.isValid, isFalse);
    });
  });
}
