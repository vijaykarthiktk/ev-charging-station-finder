import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/onboarding_provider.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/vehicle_repository.dart';
import 'screens/station_list/onboarding_screen.dart';
import 'screens/station_list/root_shell.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // await Hive.deleteFromDisk();
  // await Hive.box('chargefind_prefs').delete('onboarding_seen');

  await Hive.openBox(AppConstants.prefsBox);
  await HiveFavoritesRepository.openBox();
  await HiveVehicleRepository.openBox();
  try {
    await ReminderService().init();
  } catch (_) {
    // Reminders are best-effort; the app works without them.
  }
  runApp(const ProviderScope(child: ChargeFindApp()));
}

class ChargeFindApp extends ConsumerWidget {
  const ChargeFindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingSeenProvider);
    return MaterialApp(
      title: 'ChargeFind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: seen ? const RootShell() : const OnboardingScreen(),
    );
  }
}
