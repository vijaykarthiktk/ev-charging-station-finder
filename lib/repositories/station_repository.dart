import '../models/charging_slot.dart';
import '../models/charging_station.dart';

/// Live plug counts for one station, today.
class AvailabilitySummary {
  const AvailabilitySummary({
    required this.total,
    required this.available,
    required this.isOffline,
  });

  final int total;
  final int available;
  final bool isOffline;
  int get occupied => total - available;
}

/// Backend contract — stations, live availability, and bookings all
/// come from Postgres now. Availability is derived from confirmed
/// bookings, so no hold/release bookkeeping is needed.
abstract class StationRepository {
  Future<List<ChargingStation>> fetchStations();
  Future<AvailabilitySummary> fetchAvailability(String stationId);

  /// Hourly windows for [date] (defaults to today) — the live slot grid
  /// the booking flow validates against.
  Future<List<ChargingSlot>> fetchLiveAvailability(
    String stationId, {
    DateTime? date,
  });
}
