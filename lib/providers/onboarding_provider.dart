import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';

/// First-launch onboarding flag. The box is opened in main() before
/// any provider builds, so reads are synchronous.
class OnboardingSeenNotifier extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() =>
      Hive.box(AppConstants.prefsBox).get(_key, defaultValue: false)
          as bool;

  Future<void> complete() async {
    await Hive.box(AppConstants.prefsBox).put(_key, true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(
        OnboardingSeenNotifier.new);
