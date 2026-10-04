import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/models/charging_station.dart';
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
);

const _all = [_tata, _jio, _statiq];

void main() {
  test('default filter sorts nearest first', () {
    final out = applyStationFilter(
        _all, '', const StationFilter(), const {});
    expect(out.map((s) => s.id), ['statiq-point', 'tata-hub', 'jiobp-pulse']);
  });

  test('charger type filter keeps matching stations only', () {
    final out = applyStationFilter(_all, '',
        const StationFilter(types: {ChargerType.dcUltraFast}), const {});
    expect(out, isEmpty);

    final ac = applyStationFilter(
        _all, '', const StationFilter(types: {ChargerType.ac}), const {});
    expect(ac.map((s) => s.id), containsAll(['jiobp-pulse', 'statiq-point']));
    expect(ac.map((s) => s.id), isNot(contains('tata-hub')));
  });

  test('max price filter drops expensive stations', () {
    final out = applyStationFilter(
        _all, '', const StationFilter(maxPrice: 15), const {});
    expect(out.map((s) => s.id), ['statiq-point']);
  });

  test('availableOnly drops full and offline stations', () {
    const free = {'tata-hub': 4, 'jiobp-pulse': 0};
    final out = applyStationFilter(_all, '',
        const StationFilter(availability: AvailabilityFilter.available), free);
    // jio is full (0); statiq unknown is kept optimistically.
    expect(out.map((s) => s.id), containsAll(['tata-hub', 'statiq-point']));
    expect(out.map((s) => s.id), isNot(contains('jiobp-pulse')));
  });

  test('limited keeps only genuinely low-availability stations', () {
    const free = {'tata-hub': 4, 'jiobp-pulse': 7, 'statiq-point': 1};
    final out = applyStationFilter(_all, '',
        const StationFilter(availability: AvailabilityFilter.limited), free);
    // 4/8 and 7/12 are not limited (free*2 >= total); 1/4 is.
    expect(out.map((s) => s.id), ['statiq-point']);
  });

  test('price sort orders low to high', () {
    final out = applyStationFilter(_all, '',
        const StationFilter(sort: StationSort.priceLow), const {});
    expect(out.map((s) => s.id),
        ['statiq-point', 'jiobp-pulse', 'tata-hub']);
  });
}
