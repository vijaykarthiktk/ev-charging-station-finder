import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/charger_type.dart';
import '../models/charging_station.dart';
import '../models/connector_type.dart';

enum StationSort { nearest, priceLow, mostAvailable, topRated }

enum AvailabilityFilter { any, available, limited }

/// List-screen filter state (mirrors the Figma 07 Filters screen).
class StationFilter {
  const StationFilter({
    this.types = const {},
    this.connectors = const {},
    this.availability = AvailabilityFilter.any,
    this.openNow = false,
    this.favoritesOnly = false,
    this.sort = StationSort.nearest,
    this.maxPrice = maxPriceBound,
    this.maxDistanceKm = maxDistanceBound,
  });

  final Set<ChargerType> types;
  final Set<ConnectorType> connectors;
  final AvailabilityFilter availability;
  final bool openNow;
  final bool favoritesOnly;
  final StationSort sort;
  final double maxPrice;
  final double maxDistanceKm;

  static const double maxPriceBound = 30;
  static const double minPriceBound = 10;
  static const double maxDistanceBound = 10;
  static const double minDistanceBound = 1;

  bool get isActive =>
      types.isNotEmpty ||
      connectors.isNotEmpty ||
      availability != AvailabilityFilter.any ||
      openNow ||
      favoritesOnly ||
      sort != StationSort.nearest ||
      maxPrice < maxPriceBound ||
      maxDistanceKm < maxDistanceBound;

  StationFilter copyWith({
    Set<ChargerType>? types,
    Set<ConnectorType>? connectors,
    AvailabilityFilter? availability,
    bool? openNow,
    bool? favoritesOnly,
    StationSort? sort,
    double? maxPrice,
    double? maxDistanceKm,
  }) =>
      StationFilter(
        types: types ?? this.types,
        connectors: connectors ?? this.connectors,
        availability: availability ?? this.availability,
        openNow: openNow ?? this.openNow,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        sort: sort ?? this.sort,
        maxPrice: maxPrice ?? this.maxPrice,
        maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      );
}

class StationFilterNotifier extends Notifier<StationFilter> {
  @override
  StationFilter build() => const StationFilter();

  void apply(StationFilter filter) => state = filter;
  void reset() => state = const StationFilter();
}

final stationFilterProvider =
    NotifierProvider<StationFilterNotifier, StationFilter>(
        StationFilterNotifier.new);

/// Pure filter + sort. [freeByStation] maps station id → free plugs;
/// stations with unknown availability are kept for `available` but
/// dropped for `limited` (limited must be confirmed, never assumed).
List<ChargingStation> applyStationFilter(
  List<ChargingStation> stations,
  String query,
  StationFilter filter,
  Map<String, int> freeByStation, {
  Set<String> favoriteIds = const {},
  Map<String, double> avgByStation = const {},
  DateTime? now,
}) {
  final q = query.trim().toLowerCase();
  final nowMin =
      (now ?? DateTime.now()).hour * 60 + (now ?? DateTime.now()).minute;
  final list = stations.where((s) {
    if (q.isNotEmpty) {
      final haystack =
          '${s.name} ${s.address} ${s.chargerTypes.map((t) => t.label).join(' ')}'
              .toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    if (filter.types.isNotEmpty &&
        !s.chargerTypes.any(filter.types.contains)) {
      return false;
    }
    if (filter.connectors.isNotEmpty &&
        !s.connectors.any(filter.connectors.contains)) {
      return false;
    }
    if (s.pricePerKwh > filter.maxPrice) return false;
    if (s.distanceKm > filter.maxDistanceKm) return false;
    if (filter.favoritesOnly && !favoriteIds.contains(s.id)) return false;
    if (filter.openNow) {
      if (s.isOffline) return false;
      final openMin = s.operatingStartHour * 60;
      final closeMin = s.operatingEndHour * 60;
      if (nowMin < openMin || nowMin >= closeMin) return false;
    }
    switch (filter.availability) {
      case AvailabilityFilter.any:
        break;
      case AvailabilityFilter.available:
        if (s.isOffline) return false;
        final free = freeByStation[s.id];
        if (free != null && free <= 0) return false;
      case AvailabilityFilter.limited:
        final free = freeByStation[s.id];
        if (free == null || free <= 0 || free * 2 >= s.totalSlots) {
          return false;
        }
    }
    return true;
  }).toList();
  switch (filter.sort) {
    case StationSort.nearest:
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    case StationSort.priceLow:
      list.sort((a, b) => a.pricePerKwh.compareTo(b.pricePerKwh));
    case StationSort.mostAvailable:
      list.sort((a, b) =>
          (freeByStation[b.id] ?? -1).compareTo(freeByStation[a.id] ?? -1));
    case StationSort.topRated:
      // Unreviewed stations sink to the bottom, never assumed good.
      list.sort((a, b) => (avgByStation[b.id] ?? -1)
          .compareTo(avgByStation[a.id] ?? -1));
  }
  return list;
}
