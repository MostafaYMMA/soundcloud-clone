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

  /// Returns true only when BOTH the billing cycle AND the plan tier match.
  /// This ensures Artist Pro Yearly and Artist Yearly never both highlight.
  bool isCurrentPlanFor(String billingType, {bool isPro = false}) {
    if (!isPremium) return false;

    final cycleMatches = billingType.toLowerCase() == 'monthly'
        ? (status?.isMonthly ?? false)
        : (status?.isYearly ?? false);

    final tierMatches = isPro
        ? (status?.isPro ?? false)
        : !(status?.isPro ?? false);

    return cycleMatches && tierMatches;
  }

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
  SubscriptionNotifier(this._ref) : super(const SubscriptionState()) {
    _ref.listen(authProvider, (previous, next) {
      final prevToken = previous?.tokens?.accessToken;
      final nextToken = next.tokens?.accessToken;
      if (prevToken != nextToken) {
        state = const SubscriptionState();
        if (nextToken != null) fetchStatus();
      }
    });
  }

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

  /// Upgrade to a plan.
  /// [isPro]    true  → Artist Pro  ($19.99/mo or $149.99/yr)
  /// [isPro]    false → Artist      ($9.99/mo  or $99.99/yr)
  /// [isYearly] true  → yearly billing, false → monthly
  Future<bool> upgrade({
    required String paymentToken,
    required bool isYearly,
    required bool isPro,
  }) async {
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
        isYearly: isYearly,
        isPro: isPro,
      );
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