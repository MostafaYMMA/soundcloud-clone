import 'package:dio/dio.dart';

const String _baseUrl = 'https://streamline-swp.duckdns.org/api';

class SubscriptionStatus {
  final String plan; // "Free", "Premium", or "Pro"
  final int tracksUploaded;
  final int? limit; // null = unlimited
  final String? billingCycle; // "monthly", "yearly", or null (Free)

  const SubscriptionStatus({
    required this.plan,
    required this.tracksUploaded,
    required this.limit,
    required this.billingCycle,
  });

  bool get isPremium => plan == 'Premium' || plan == 'Pro';
  bool get isMonthly => billingCycle == 'monthly';
  bool get isYearly => billingCycle == 'yearly';
  bool get isPro => plan == 'Pro';

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SubscriptionStatus(
      plan: data['plan'] as String,
      tracksUploaded: data['tracks_uploaded'] as int,
      limit: data['limit'] as int?,
      billingCycle: data['billing_cycle'] as String?,
    );
  }
}

class SubscriptionService {
  SubscriptionService({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  /// GET /subscriptions/me
  Future<SubscriptionStatus> getMySubscription({
    required String accessToken,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/subscriptions/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return SubscriptionStatus.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upgrade endpoint routing:
  /// isPro=false, isYearly=false → POST /subscriptions/upgrade/monthly         ($9.99,  plan="Premium")
  /// isPro=false, isYearly=true  → POST /subscriptions/upgrade/yearly          ($99.99, plan="Premium")
  /// isPro=true,  isYearly=false → POST /subscriptions/upgrade/pro/monthly     ($19.99, plan="Pro")
  /// isPro=true,  isYearly=true  → POST /subscriptions/upgrade/pro/yearly      ($149.99,plan="Pro")
  Future<String> upgrade({
    required String accessToken,
    required String paymentToken,
    required bool isYearly,
    required bool isPro,
  }) async {
    final String endpoint;
    final String plan;

    if (isPro) {
      endpoint = isYearly
          ? '$_baseUrl/subscriptions/upgrade/pro/yearly'
          : '$_baseUrl/subscriptions/upgrade/pro/monthly';
      plan = 'Pro';
    } else {
      endpoint = isYearly
          ? '$_baseUrl/subscriptions/upgrade/yearly'
          : '$_baseUrl/subscriptions/upgrade/monthly';
      plan = 'Premium';
    }

    try {
      final response = await _dio.post(
        endpoint,
        data: {'payment_token': paymentToken, 'plan': plan},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ?? 'Upgraded successfully';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode == 402) {
      return Exception('Payment failed. Please check your card details.');
    } else if (statusCode == 422) {
      final detail = responseData?['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg = detail.first['msg'] ?? 'Validation error';
        return Exception(msg.toString());
      }
      return Exception('Invalid request. Please try again.');
    } else if (statusCode == 401) {
      return Exception('Session expired. Please log in again.');
    }
    return Exception(
      e.message ?? 'Something went wrong. Please try again.',
    );
  }
}