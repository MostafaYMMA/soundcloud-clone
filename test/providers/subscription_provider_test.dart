import 'package:flutter_test/flutter_test.dart';
import 'package:my_project/providers/subscription_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('SubscriptionState', () {
    test('initial state has no status', () {
      const state = SubscriptionState();

      expect(state.status, isNull);
      expect(state.isLoading, false);
      expect(state.isUpgrading, false);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('isPremium returns false when status is null', () {
      const state = SubscriptionState();

      expect(state.isPremium, false);
    });

    test('copyWith updates individual fields', () {
      const state = SubscriptionState(
        isLoading: true,
        error: null,
      );

      final updated = state.copyWith(
        isLoading: false,
      );

      expect(updated.isLoading, false);
    });

    test('copyWith preserves status when not provided', () {
      const state = SubscriptionState(
        isLoading: true,
      );

      final updated = state.copyWith(isLoading: false);

      expect(updated.status, isNull);
      expect(updated.isLoading, false);
    });

    test('copyWith can set new error', () {
      const state = SubscriptionState();

      final updated = state.copyWith(error: 'Payment failed');

      expect(updated.error, 'Payment failed');
    });

    test('copyWith can set new success message', () {
      const state = SubscriptionState();

      final updated = state.copyWith(successMessage: 'Upgraded to Pro');

      expect(updated.successMessage, 'Upgraded to Pro');
    });

    test('copyWith updates isUpgrading flag', () {
      const state = SubscriptionState(isUpgrading: false);

      final updated = state.copyWith(isUpgrading: true);

      expect(updated.isUpgrading, true);
    });

    test('isCurrentPlanFor returns false when not premium', () {
      const state = SubscriptionState();

      expect(state.isCurrentPlanFor('monthly'), false);
      expect(state.isCurrentPlanFor('yearly', isPro: true), false);
    });
  });
}
