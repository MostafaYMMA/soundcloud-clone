import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/followers_service.dart';

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
  late FollowersService sut;

  setUp(() {
    mockDio = MockDio();
    sut = FollowersService(dio: mockDio);
  });

  group('FollowersService.followUser', () {
    test('completes on success', () async {
      when(() => mockDio.post(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.followUser(username: 'testuser'), completes);
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.post(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.followUser(username: 'invalid'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('FollowersService.unfollowUser', () {
    test('completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.unfollowUser(username: 'testuser'), completes);
    });

    test('rethrows DioException on failure', () async {
      when(() => mockDio.delete(any())).thenThrow(_dioErr(statusCode: 404));

      expect(
        () => sut.unfollowUser(username: 'invalid'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('FollowersService.blockUser', () {
    test('completes on success', () async {
      when(() => mockDio.post(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.blockUser(username: 'testuser'), completes);
    });
  });

  group('FollowersService.unblockUser', () {
    test('completes on success', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _res({}));

      await expectLater(sut.unblockUser(username: 'testuser'), completes);
    });
  });

  group('FollowersService.getMyFollowers', () {
    test('returns follower list response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({
          'data': {
            'followers': [
              {'user_id': 'user-1', 'username': 'follower1'}
            ],
            'total_count': 1,
          },
        }),
      );

      final response = await sut.getMyFollowers();

      expect(response, isNotNull);
    });
  });

  group('FollowersService.getMyFollowing', () {
    test('returns following list response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({
          'data': {
            'following': [
              {'user_id': 'user-2', 'username': 'following1'}
            ],
            'total_count': 1,
          },
        }),
      );

      final response = await sut.getMyFollowing();

      expect(response, isNotNull);
    });
  });

  group('FollowersService.getUserFollowers', () {
    test('returns user followers', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({
          'data': {
            'followers': [],
            'total_count': 0,
          },
        }),
      );

      final response = await sut.getUserFollowers(username: 'testuser');

      expect(response, isNotNull);
    });
  });

  group('FollowersService.getUserFollowing', () {
    test('returns user following list', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _res({
          'data': {
            'following': [],
            'total_count': 0,
          },
        }),
      );

      final response = await sut.getUserFollowing(username: 'testuser');

      expect(response, isNotNull);
    });
  });
}
