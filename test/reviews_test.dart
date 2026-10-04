import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/models/charging_station.dart';
import 'package:chargefind/models/review.dart';
import 'package:chargefind/providers/station_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = ChargingStation(
  id: 'a',
  name: 'A Hub',
  address: 'Mumbai',
  distanceKm: 1.0,
  latitude: 19.0,
  longitude: 72.8,
  pricePerKwh: 18,
  chargerTypes: [ChargerType.dcFast],
  powerKwByType: {'DC Fast': 60},
  totalSlots: 8,
  operatingStartHour: 6,
  operatingEndHour: 22,
  amenities: ['Wi-Fi'],
);

const _b = ChargingStation(
  id: 'b',
  name: 'B Point',
  address: 'Mumbai',
  distanceKm: 2.0,
  latitude: 19.1,
  longitude: 72.9,
  pricePerKwh: 16,
  chargerTypes: [ChargerType.dcFast],
  powerKwByType: {'DC Fast': 60},
  totalSlots: 8,
  operatingStartHour: 6,
  operatingEndHour: 22,
  amenities: ['Wi-Fi'],
);

void main() {
  test('review JSON round-trips', () {
    final now = DateTime.now();
    final review = Review(
      id: 'RV-1',
      stationId: 'a',
      rating: 5,
      comment: 'Fast and clean.',
      author: 'Aarav',
      createdAt: now,
    );
    final restored = Review.fromJson(review.toJson());
    expect(restored.id, 'RV-1');
    expect(restored.rating, 5);
    expect(restored.author, 'Aarav');
  });

  test('top rated sorts by average, unreviewed sink', () {
    final out = applyStationFilter(
      [_a, _b],
      '',
      const StationFilter(sort: StationSort.topRated),
      const {},
      avgByStation: const {'b': 4.5, 'a': 3.0},
    );
    expect(out.map((s) => s.id), ['b', 'a']);

    final missing = applyStationFilter(
      [_a, _b],
      '',
      const StationFilter(sort: StationSort.topRated),
      const {},
      avgByStation: const {'b': 4.0},
    );
    expect(missing.map((s) => s.id), ['b', 'a']);
  });
}
