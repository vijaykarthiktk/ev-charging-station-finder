import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/availability_status.dart';
import '../models/charging_slot.dart';
import '../models/charging_station.dart';
import '../repositories/station_repository.dart';
import 'favorites_provider.dart';
import 'repository_providers.dart';
import 'review_provider.dart';
import 'station_filter.dart';

/// All stations from the (mock) backend.
final stationsProvider = FutureProvider<List<ChargingStation>>(
  (ref) => ref.watch(stationRepositoryProvider).fetchStations(),
);

/// Live plug counts for one station, today.
final availabilityProvider =
    FutureProvider.family<AvailabilitySummary, String>(
  (ref, stationId) =>
      ref.watch(stationRepositoryProvider).fetchAvailability(stationId),
);

/// Live hourly windows for one station + date. Invalidated after every
/// booking/cancellation so Detail always reflects current state.
final slotsProvider =
    FutureProvider.family<List<ChargingSlot>, ({String stationId, DateTime date})>(
  (ref, arg) => ref
      .watch(stationRepositoryProvider)
      .fetchLiveAvailability(arg.stationId, date: arg.date),
);

/// Search text typed in the station list.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Stations filtered by search query + filter sheet state, sorted.
/// Retains the loading/error states of [stationsProvider].
final filteredStationsProvider = Provider<AsyncValue<List<ChargingStation>>>(
  (ref) {
    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(stationFilterProvider);
    final favorites = ref.watch(favoritesProvider);
    return ref.watch(stationsProvider).whenData((stations) {
      final free = <String, int>{};
      for (final s in stations) {
        final v = ref.watch(availabilityProvider(s.id)).value;
        if (v != null && !v.isOffline) free[s.id] = v.available;
      }
      final avg = <String, double>{};
      for (final s in stations) {
        final summary = ref.watch(reviewSummaryProvider(s.id));
        if (summary.count > 0) avg[s.id] = summary.avg;
      }
      return applyStationFilter(stations, query, filter, free,
          favoriteIds: favorites, avgByStation: avg, now: DateTime.now());
    });
  },
);

/// Station the user is currently viewing/booking.
class SelectedStationNotifier extends Notifier<ChargingStation?> {
  @override
  ChargingStation? build() => null;

  void select(ChargingStation station) => state = station;
  void clear() => state = null;
}

final selectedStationProvider =
    NotifierProvider<SelectedStationNotifier, ChargingStation?>(
        SelectedStationNotifier.new);

/// Convenience: availability status for one station, today.
final stationStatusProvider = Provider.family<AvailabilityStatus, String>(
  (ref, stationId) {
    final summary = ref.watch(availabilityProvider(stationId)).value;
    if (summary == null) return AvailabilityStatus.offline;
    return AvailabilityStatusX.fromCounts(
      isOffline: summary.isOffline,
      available: summary.available,
      total: summary.total,
    );
  },
);
