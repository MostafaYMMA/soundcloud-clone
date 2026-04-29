import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../providers/auth_providers.dart';

// ── State ────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionStatus? status;
  final bool isLoading;
  final bool isUpgrading;
  final String? error;
  final String? successMessage;

  const SubscriptionState({
    this.status,
    this.isLoading = false,
    this.isUpgrading = false,
    this.error,
    this.successMessage,
  });

  bool get isPremium => status?.isPremium ?? false;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    bool? isLoading,
    bool? isUpgrading,
    String? error,
    String? successMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isUpgrading: isUpgrading ?? this.isUpgrading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._ref) : super(const SubscriptionState());

  final Ref _ref;
  final _service = SubscriptionService();

  String? get _token => _ref.read(authProvider).tokens?.accessToken;

  /// Fetch current subscription status from backend.
  Future<void> fetchStatus() async {
    final token = _token;
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final status = await _service.getMySubscription(accessToken: token);
      state = state.copyWith(isLoading: false, status: status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Upgrade to Premium using a Stripe payment token.
  /// [paymentToken] comes from flutter_stripe after the user enters card details.
  Future<bool> upgrade({required String paymentToken}) async {
    final token = _token;
    if (token == null) {
      state = state.copyWith(error: 'Not logged in.');
      return false;
    }

    state = state.copyWith(isUpgrading: true);
    try {
      final message = await _service.upgrade(
        accessToken: token,
        paymentToken: paymentToken,
        plan: 'Premium',
      );
      // Refresh status after successful upgrade
      await fetchStatus();
      state = state.copyWith(isUpgrading: false, successMessage: message);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpgrading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
  void clearSuccess() => state = state.copyWith(successMessage: null);
}

// ── Provider ─────────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      (ref) => SubscriptionNotifier(ref),
    );
