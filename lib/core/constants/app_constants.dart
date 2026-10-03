/// App-wide constants.
class AppConstants {
  AppConstants._();

  /// Hive box name for persisted bookings.
  static const String bookingsBox = 'chargefind_bookings';

  /// Hive box name for favorite station ids.
  static const String favoritesBox = 'chargefind_favorites';

  /// Hive box name for the vehicle profile.
  static const String vehicleBox = 'chargefind_vehicle';

  /// Hive box name for simple app prefs (onboarding seen flag).
  static const String prefsBox = 'chargefind_prefs';

  /// Simulated network latency bounds for the mock station service.
  static const Duration minLatency = Duration(milliseconds: 500);
  static const Duration maxLatency = Duration(milliseconds: 1200);

  /// How many days ahead a user can book (today inclusive).
  static const int bookingHorizonDays = 7;

  /// Minimum lead time for a booking to count as "in the future".
  static const Duration bookingLeadTime = Duration(minutes: 15);

  /// Rough energy estimate used for price preview (kWh per booked hour).
  static const double kwhPerHour = 10;

  /// Width above which the station list switches to a 2-column grid.
  static const double wideLayoutBreakpoint = 720;

  /// Max content width for centered desktop/tablet layouts.
  static const double maxContentWidth = 860;

  static const String currencySymbol = '₹';
}
