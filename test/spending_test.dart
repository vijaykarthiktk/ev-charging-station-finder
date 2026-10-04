import 'package:chargefind/models/booking.dart';
import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/providers/spending_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Booking _booking({
  required String id,
  required String stationId,
  required String stationName,
  required double energy,
  required double price,
  required BookingStatus status,
}) {
  final now = DateTime.now();
  return Booking(
    id: id,
    stationId: stationId,
    stationName: stationName,
    chargerType: ChargerType.dcFast,
    date: now,
    startTime: now,
    endTime: now.add(const Duration(hours: 1)),
    pricePerKwh: 18,
    estimatedPrice: price,
    energyKwh: energy,
    status: status,
    createdAt: now,
  );
}

void main() {
  test('spending excludes cancelled bookings', () {
    final summary = spendingSummary([
      _booking(
          id: '1',
          stationId: 'tata',
          stationName: 'Tata Hub',
          energy: 24,
          price: 432,
          status: BookingStatus.confirmed),
      _booking(
          id: '2',
          stationId: 'tata',
          stationName: 'Tata Hub',
          energy: 10,
          price: 180,
          status: BookingStatus.completed),
      _booking(
          id: '3',
          stationId: 'jio',
          stationName: 'Jio Pulse',
          energy: 99,
          price: 999,
          status: BookingStatus.cancelled),
    ]);
    expect(summary.sessions, 2);
    expect(summary.energyKwh, 34);
    expect(summary.spent, 612);
    expect(summary.topStation, 'Tata Hub');
  });

  test('empty history yields zeros and no top station', () {
    final summary = spendingSummary(const []);
    expect(summary.sessions, 0);
    expect(summary.energyKwh, 0);
    expect(summary.spent, 0);
    expect(summary.topStation, isNull);
  });
}
