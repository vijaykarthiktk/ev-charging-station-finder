import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/models/charging_station.dart';
import 'package:chargefind/models/connector_type.dart';
import 'package:chargefind/models/vehicle_profile.dart';
import 'package:chargefind/providers/booking_provider.dart';
import 'package:chargefind/providers/station_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _tata = ChargingStation(
  id: 'tata-hub',
  name: 'Tata Power Charging Hub',
  address: 'Andheri East, Mumbai',
  distanceKm: 2.4,
  latitude: 19.1102,
  longitude: 72.8658,
  pricePerKwh: 18,
  chargerTypes: [ChargerType.dcFast],
  powerKwByType: {'DC Fast': 60},
  totalSlots: 8,
  operatingStartHour: 6,
  operatingEndHour: 22,
  amenities: ['Wi-Fi'],
  connectors: [ConnectorType.ccs2, ConnectorType.chademo],
);

const _jio = ChargingStation(
  id: 'jiobp-pulse',
  name: 'Jio-bp Pulse',
  address: 'HITEC City, Hyderabad',
  distanceKm: 3.1,
  latitude: 17.4435,
  longitude: 78.3772,
  pricePerKwh: 16,
  chargerTypes: [ChargerType.ac, ChargerType.dcFast],
  powerKwByType: {'AC': 22, 'DC Fast': 60},
  totalSlots: 12,
  operatingStartHour: 0,
  operatingEndHour: 24,
  amenities: ['Wi-Fi'],
  connectors: [ConnectorType.type2, ConnectorType.ccs2],
);

const _statiq = ChargingStation(
  id: 'statiq-point',
  name: 'Statiq Neighborhood Point',
  address: 'Green Park, New Delhi',
  distanceKm: 1.2,
  latitude: 28.5577,
  longitude: 77.2067,
  pricePerKwh: 14,
  chargerTypes: [ChargerType.ac],
  powerKwByType: {'AC': 11},
  totalSlots: 4,
  operatingStartHour: 8,
  operatingEndHour: 20,
  amenities: ['Parking'],
  connectors: [ConnectorType.type2],
);

const _all = [_tata, _jio, _statiq];

void main() {
  test('vehicle JSON round-trips', () {
    const v = VehicleProfile(
        id: 'v-1',
        name: 'Nexon EV',
        batteryKwh: 40,
        connector: ConnectorType.ccs2);
    final restored = VehicleProfile.fromJson(v.toJson());
    expect(restored.id, 'v-1');
    expect(restored.name, 'Nexon EV');
    expect(restored.batteryKwh, 40);
    expect(restored.connector, ConnectorType.ccs2);
  });

  test('estimate without vehicle falls back to flat hourly rate', () {
    final s = estimateSession(
        pricePerKwh: 18, powerKw: 60, minutes: 60, vehicle: null);
    expect(s.energyKwh, 10);
    expect(s.price, 180);
  });

  test('estimate with vehicle: 20-80% top-up capped by plug delivery', () {
    // 40 kWh pack → 24 kWh wanted; 60 kW × 1 h × 0.9 = 54 deliverable.
    final s = estimateSession(
      pricePerKwh: 18,
      powerKw: 60,
      minutes: 60,
      vehicle: const VehicleProfile(
          id: 'v-1', name: 'Nexon EV', batteryKwh: 40, connector: ConnectorType.ccs2),
    );
    expect(s.energyKwh, 24);
    expect(s.price, 432);

    // Slow AC plug caps the same car: 11 kW × 1 h × 0.9 = 9.9 kWh.
    final capped = estimateSession(
      pricePerKwh: 14,
      powerKw: 11,
      minutes: 60,
      vehicle: const VehicleProfile(
          id: 'v-1', name: 'Nexon EV', batteryKwh: 40, connector: ConnectorType.type2),
    );
    expect(capped.energyKwh, 9.9);
    expect(capped.price, closeTo(138.6, 0.01));
  });

  test('connector filter matches plug standards', () {
    final out = applyStationFilter(_all, '',
        const StationFilter(connectors: {ConnectorType.chademo}), const {});
    expect(out.map((s) => s.id), ['tata-hub']);

    final t2 = applyStationFilter(_all, '',
        const StationFilter(connectors: {ConnectorType.type2}), const {});
    expect(t2.map((s) => s.id),
        containsAll(['jiobp-pulse', 'statiq-point']));
  });

  test('favoritesOnly keeps just favorited stations', () {
    final out = applyStationFilter(_all, '',
        const StationFilter(favoritesOnly: true), const {},
        favoriteIds: {'jiobp-pulse'});
    expect(out.map((s) => s.id), ['jiobp-pulse']);
  });

  test('max distance drops far stations', () {
    final out = applyStationFilter(
        _all, '', const StationFilter(maxDistanceKm: 2), const {});
    expect(out.map((s) => s.id), ['statiq-point']);
  });

  test('openNow keeps stations open at the given time', () {
    // 10:00 — all three open (statiq 8–20, tata 6–22, jio 24×7).
    final morning = applyStationFilter(_all, '',
        const StationFilter(openNow: true), const {},
        now: DateTime(2026, 10, 3, 10, 0));
    expect(morning.length, 3);

    // 21:00 — statiq closed (8–20).
    final night = applyStationFilter(_all, '',
        const StationFilter(openNow: true), const {},
        now: DateTime(2026, 10, 3, 21, 0));
    expect(night.map((s) => s.id),
        containsAll(['tata-hub', 'jiobp-pulse']));
    expect(night.map((s) => s.id), isNot(contains('statiq-point')));
  });
}
