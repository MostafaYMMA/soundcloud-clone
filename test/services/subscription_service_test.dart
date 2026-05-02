import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_project/services/subscription_service.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _res(dynamic data, {int statusCode = 200}) => Response(
  data: data,
  statusCode: statusCode,
  requestOptions: RequestOptions(path: ''),
);

DioException _dioErr({int statusCode = 500, dynamic responseData}) =>
    DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(
        data: responseData ?? {},
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
  late SubscriptionService sut;

  setUp(() {
    mockDio = MockDio();
    sut = SubscriptionService(dio: mockDio);
  });

  group('SubscriptionStatus', () {
    test('parses free plan', () {
      final json = {
        'data': {
          'plan': 'Free',
          'tracks_uploaded': 2,
          'limit': 5,
          'billing_cycle': null,
        },
      };

      final status = SubscriptionStatus.fromJson(json);

      expect(status.plan, 'Free');
      expect(status.isPremium, false);
      expect(status.isPro, false);
    });

    test('parses premium monthly plan', () {
      final json = {
        'data': {
          'plan': 'Premium',
          'tracks_uploaded': 50,
          'limit': null,
          'billing_cycle': 'monthly',
        },
      };

      final status = SubscriptionStatus.fromJson(json);

      expect(status.plan, 'Premium');
      expect(status.isPremium, true);
      expect(status.isMonthly, true);
      expect(status.isPro, false);
    });

    test('parses pro yearly plan', () {
      final json = {
        'data': {
          'plan': 'Pro',
          'tracks_uploaded': 150,
          'limit': null,
          'billing_cycle': 'yearly',
        },
      };

      final status = SubscriptionStatus.fromJson(json);

      expect(status.plan, 'Pro');
      expect(status.isPremium, true);
      expect(status.isPro, true);
      expect(status.isYearly, true);
    });
  });

  group('SubscriptionService.getMySubscription', () {
    test('returns subscription status', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => _res({
          'data': {
            'plan': 'Premium',
            'tracks_uploaded': 10,
            'limit': null,
            'billing_cycle': 'monthly',
          },
        }),
      );

      final status = await sut.getMySubscription(accessToken: 'token');

      expect(status.plan, 'Premium');
      expect(status.isPremium, true);
    });

    test('throws exception on auth failure', () async {
      when(
        () => mockDio.get(any(), options: any(named: 'options')),
      ).thenThrow(_dioErr(statusCode: 401));

      expect(
        () => sut.getMySubscription(accessToken: 'invalid'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SubscriptionService.upgrade', () {
    test('upgrades to premium monthly', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _res({'message': 'Upgraded to Premium'}));

      final message = await sut.upgrade(
        accessToken: 'token',
        paymentToken: 'pay-token-123',
        isYearly: false,
        isPro: false,
      );

      expect(message, 'Upgraded to Premium');
    });

    test('upgrades to premium yearly', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _res({'message': 'Upgraded'}));

      final message = await sut.upgrade(
        accessToken: 'token',
        paymentToken: 'pay-token-123',
        isYearly: true,
        isPro: false,
      );

      expect(message, isA<String>());
    });

    test('upgrades to pro monthly', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _res({'message': 'Upgraded to Pro'}));

      final message = await sut.upgrade(
        accessToken: 'token',
        paymentToken: 'pay-token-123',
        isYearly: false,
        isPro: true,
      );

      expect(message, 'Upgraded to Pro');
    });

    test('upgrades to pro yearly', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _res({'message': 'Upgraded'}));

      final message = await sut.upgrade(
        accessToken: 'token',
        paymentToken: 'pay-token-123',
        isYearly: true,
        isPro: true,
      );

      expect(message, isA<String>());
    });

    test('throws exception on payment failure (402)', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(_dioErr(statusCode: 402));

      expect(
        () => sut.upgrade(
          accessToken: 'token',
          paymentToken: 'invalid-card',
          isYearly: false,
          isPro: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws exception on validation error (422)', () async {
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(_dioErr(statusCode: 422));

      expect(
        () => sut.upgrade(
          accessToken: 'token',
          paymentToken: 'token',
          isYearly: false,
          isPro: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
