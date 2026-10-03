import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:postgres/postgres.dart';

import '../core/config/db_config.dart';
import '../core/constants/app_constants.dart';
import '../repositories/booking_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/postgres_booking_repository.dart';
import '../repositories/postgres_station_repository.dart';
import '../repositories/station_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../services/reminder_service.dart';

/// Single shared Postgres connection for the app's lifetime.
final pgConnectionProvider = Provider<Future<Connection>>((ref) {
  final config = DbConfig.fromEnvironment();
  final future =
      Connection.open(config.endpoint, settings: config.settings);
  ref.onDispose(() => future.then((c) => c.close()));
  return future;
});

/// Stations + live availability from Postgres.
final stationRepositoryProvider = Provider<StationRepository>(
  (ref) => PostgresStationRepository(ref.watch(pgConnectionProvider)),
);

/// Bookings in Postgres. Hive keeps only device-local prefs
/// (favorites, garage) — those belong to the device, not the backend.
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => PostgresBookingRepository(ref.watch(pgConnectionProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => HiveFavoritesRepository(Hive.box(AppConstants.favoritesBox)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => HiveVehicleRepository(Hive.box(AppConstants.vehicleBox)),
);

/// Singleton reminder service (initialized in main; calls are best-effort).
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);
