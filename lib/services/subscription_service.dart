import 'package:dio/dio.dart';

const String _baseUrl = 'https://streamline-swp.duckdns.org/api';

class SubscriptionStatus {
  final String plan; // "Free" or "Premium"
  final int tracksUploaded;
  final int? limit; // null for Premium (unlimited)

  const SubscriptionStatus({
    required this.plan,
    required this.tracksUploaded,
    required this.limit,
  });

  bool get isPremium => plan == 'Premium';

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SubscriptionStatus(
      plan: data['plan'] as String,
      tracksUploaded: data['tracks_uploaded'] as int,
      limit: data['limit'] as int?,
    );
  }
}

class SubscriptionService {
  SubscriptionService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// GET /subscriptions/me
  /// Returns the current user's plan, tracks uploaded, and upload limit.
  Future<SubscriptionStatus> getMySubscription({
    required String accessToken,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/subscriptions/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return SubscriptionStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /subscriptions/upgrade
  /// Sends a Stripe payment token and plan name to upgrade the user.
  /// Returns success message on 200.
  Future<String> upgrade({
    required String accessToken,
    required String paymentToken, // e.g. "tok_visa" in test mode
    required String plan, // "Premium"
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/subscriptions/upgrade',
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
      // Validation error from backend
      final detail = responseData?['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg = detail.first['msg'] ?? 'Validation error';
        return Exception(msg.toString());
      }
      return Exception('Invalid request. Please try again.');
    } else if (statusCode == 401) {
      return Exception('Session expired. Please log in again.');
    }
    return Exception(e.message ?? 'Something went wrong. Please try again.');
  }
}
