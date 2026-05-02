import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/models/follower.dart';
import 'package:my_project/providers/followers_provider.dart';
import 'package:my_project/services/followers_service.dart';

class MockFollowersService extends Mock implements FollowersService {}

class MockRef extends Mock implements Ref {}

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
  group('FollowNotifier', () {
    late MockFollowersService mockService;
    late MockRef mockRef;

    setUp(() {
      mockService = MockFollowersService();
      mockRef = MockRef();
    });

    test('initial state has isFollowing set correctly', () {
      final notifier = FollowNotifier(
        service: mockService,
        username: 'testuser',
        initiallyFollowing: false,
        ref: mockRef,
      );

      expect(notifier.state.isFollowing, false);
      expect(notifier.state.isLoading, false);
    });

    test('toggle follows user when not following', () async {
      when(() => mockService.followUser(username: 'testuser'))
          .thenAnswer((_) async {});
      when(() => mockRef.invalidate(myFollowingProvider))
          .thenReturn(null);

      final notifier = FollowNotifier(
        service: mockService,
        username: 'testuser',
        initiallyFollowing: false,
        ref: mockRef,
      );

      await notifier.toggle();

      expect(notifier.state.isFollowing, true);
      expect(notifier.state.isLoading, false);
      verify(() => mockService.followUser(username: 'testuser')).called(1);
    });

    test('toggle unfollows user when following', () async {
      when(() => mockService.unfollowUser(username: 'testuser'))
          .thenAnswer((_) async {});
      when(() => mockRef.invalidate(myFollowingProvider))
          .thenReturn(null);

      final notifier = FollowNotifier(
        service: mockService,
        username: 'testuser',
        initiallyFollowing: true,
        ref: mockRef,
      );

      await notifier.toggle();

      expect(notifier.state.isFollowing, false);
      verify(() => mockService.unfollowUser(username: 'testuser')).called(1);
    });

    test('toggle reverts on service error', () async {
      when(() => mockService.followUser(username: 'testuser'))
          .thenThrow(_dioErr());

      final notifier = FollowNotifier(
        service: mockService,
        username: 'testuser',
        initiallyFollowing: false,
        ref: mockRef,
      );

      await notifier.toggle();

      expect(notifier.state.isFollowing, false);
      expect(notifier.state.isLoading, false);
    });

    test('toggle ignores requests while loading', () async {
      when(() => mockService.followUser(username: 'testuser'))
          .thenAnswer((_) async => Future.delayed(Duration(seconds: 1)));
      when(() => mockRef.invalidate(myFollowingProvider))
          .thenReturn(null);

      final notifier = FollowNotifier(
        service: mockService,
        username: 'testuser',
        initiallyFollowing: false,
        ref: mockRef,
      );

      notifier.toggle();
      await notifier.toggle();

      verify(() => mockService.followUser(username: 'testuser')).called(1);
    });
  });

  group('BlockNotifier', () {
    late MockFollowersService mockService;

    setUp(() {
      mockService = MockFollowersService();
    });

    test('initial state has isBlocked false', () {
      final notifier = BlockNotifier(
        service: mockService,
        username: 'testuser',
      );

      expect(notifier.state.isBlocked, false);
      expect(notifier.state.isLoading, false);
    });

    test('toggle blocks user', () async {
      when(() => mockService.blockUser(username: 'testuser'))
          .thenAnswer((_) async {});

      final notifier = BlockNotifier(
        service: mockService,
        username: 'testuser',
      );

      await notifier.toggle();

      expect(notifier.state.isBlocked, true);
      expect(notifier.state.isLoading, false);
      verify(() => mockService.blockUser(username: 'testuser')).called(1);
    });

    test('toggle unblocks user when blocked', () async {
      when(() => mockService.blockUser(username: 'testuser'))
          .thenAnswer((_) async {});
      when(() => mockService.unblockUser(username: 'testuser'))
          .thenAnswer((_) async {});

      final notifier = BlockNotifier(
        service: mockService,
        username: 'testuser',
      );

      await notifier.toggle();
      expect(notifier.state.isBlocked, true);

      await notifier.toggle();

      expect(notifier.state.isBlocked, false);
      verify(() => mockService.unblockUser(username: 'testuser')).called(1);
    });

    test('toggle reverts on service error', () async {
      when(() => mockService.blockUser(username: 'testuser'))
          .thenThrow(_dioErr());

      final notifier = BlockNotifier(
        service: mockService,
        username: 'testuser',
      );

      await notifier.toggle();

      expect(notifier.state.isBlocked, false);
      expect(notifier.state.isLoading, false);
    });

    test('toggle ignores requests while loading', () async {
      when(() => mockService.blockUser(username: 'testuser'))
          .thenAnswer((_) async => Future.delayed(Duration(seconds: 1)));

      final notifier = BlockNotifier(
        service: mockService,
        username: 'testuser',
      );

      notifier.toggle();
      await notifier.toggle();

      verify(() => mockService.blockUser(username: 'testuser')).called(1);
    });
  });

  group('myFollowersProvider', () {
    test('returns follower list', () async {
      final container = ProviderContainer(
        overrides: [
          followersServiceProvider.overrideWithValue(
            MockFollowersService(),
          ),
        ],
      );

      final service = container.read(followersServiceProvider)
          as MockFollowersService;
      final response = FollowerListResponse(
        followers: [
          Follower(userId: 'u1', username: 'user1'),
        ],
        count: 1,
      );
      when(() => service.getMyFollowers()).thenAnswer((_) async => response);

      final result = await container.read(myFollowersProvider.future);

      expect(result.followers.length, 1);
      expect(result.followers[0].userId, 'u1');
    });
  });

  group('myFollowingProvider', () {
    test('returns following list', () async {
      final container = ProviderContainer(
        overrides: [
          followersServiceProvider.overrideWithValue(
            MockFollowersService(),
          ),
        ],
      );

      final service = container.read(followersServiceProvider)
          as MockFollowersService;
      final response = FollowingListResponse(
        following: [
          Follower(userId: 'u1', username: 'user1'),
        ],
        count: 1,
      );
      when(() => service.getMyFollowing()).thenAnswer((_) async => response);

      final result = await container.read(myFollowingProvider.future);

      expect(result.following.length, 1);
      expect(result.following[0].userId, 'u1');
    });
  });

  group('userFollowersProvider', () {
    test('returns followers for specific user', () async {
      final container = ProviderContainer(
        overrides: [
          followersServiceProvider.overrideWithValue(
            MockFollowersService(),
          ),
        ],
      );

      final service = container.read(followersServiceProvider)
          as MockFollowersService;
      final response = FollowerListResponse(
        followers: [
          Follower(userId: 'u1', username: 'user1'),
        ],
        count: 1,
      );
      when(() => service.getUserFollowers(username: 'targetuser'))
          .thenAnswer((_) async => response);

      final result =
          await container.read(userFollowersProvider('targetuser').future);

      expect(result.followers.length, 1);
    });
  });

  group('userFollowingProvider', () {
    test('returns following for specific user', () async {
      final container = ProviderContainer(
        overrides: [
          followersServiceProvider.overrideWithValue(
            MockFollowersService(),
          ),
        ],
      );

      final service = container.read(followersServiceProvider)
          as MockFollowersService;
      final response = FollowingListResponse(
        following: [
          Follower(userId: 'u1', username: 'user1'),
        ],
        count: 1,
      );
      when(() => service.getUserFollowing(username: 'targetuser'))
          .thenAnswer((_) async => response);

      final result =
          await container.read(userFollowingProvider('targetuser').future);

      expect(result.following.length, 1);
    });
  });
}
