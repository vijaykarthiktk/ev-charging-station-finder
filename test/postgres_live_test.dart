import 'package:chargefind/models/booking.dart';
import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/repositories/postgres_booking_repository.dart';
import 'package:chargefind/repositories/postgres_station_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart';

/// End-to-end against a real Postgres. Needs the seeded database
/// (see README "Postgres backend"); skips when unreachable.
Future<Connection?> _tryConnect() async {
  try {
    return await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 5432,
        database: 'chargefind',
        username: 'chargefind',
        password: 'chargefind',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  } catch (_) {
    return null;
  }
}

void main() {
  test('postgres roundtrip: stations, availability, booking lifecycle',
      () async {
    final conn = await _tryConnect();
    if (conn == null) {
      markTestSkipped('No local Postgres at 127.0.0.1:5432');
      return;
    }
    addTearDown(conn.close);

    final stationsRepo =
        PostgresStationRepository(Future.value(conn));
    final bookingsRepo =
        PostgresBookingRepository(Future.value(conn));

    final stations = await stationsRepo.fetchStations();
    expect(stations.length, 11);
    expect(stations.map((s) => s.id),
        containsAll(['tata-hub', 'cityone-mega', 'heritage-chademo']));

    final summary = await stationsRepo.fetchAvailability('tata-hub');
    expect(summary.total, 8);
    expect(summary.isOffline, isFalse);

    final offline =
        await stationsRepo.fetchAvailability('goego-depot');
    expect(offline.available, 0);
    expect(offline.isOffline, isTrue);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final day =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final windows = await stationsRepo.fetchLiveAvailability('tata-hub',
        date: day);
    // 16 hourly windows (06:00–22:00) × 1 charger type, all free.
    expect(windows.length, 16);
    expect(windows.every((w) => w.available), isTrue);

    final now = DateTime.now();
    final booking = Booking(
      id: 'CF-LIVE-TEST',
      stationId: 'tata-hub',
      stationName: 'Tata Power Charging Hub',
      chargerType: ChargerType.dcFast,
      date: day,
      startTime: day.add(const Duration(hours: 10)),
      endTime: day.add(const Duration(hours: 11)),
      pricePerKwh: 18,
      estimatedPrice: 180,
      energyKwh: 10,
      status: BookingStatus.confirmed,
      createdAt: now,
    );
    try {
      await bookingsRepo.saveBooking(booking);
      final all = await bookingsRepo.fetchBookings();
      expect(all.map((b) => b.id), contains('CF-LIVE-TEST'));

      // The booked window now reads busy (capacity 8 shared plugs, but
      // the overlap query must at least see this booking).
      final after = await stationsRepo.fetchLiveAvailability('tata-hub',
          date: day);
      final target = after.firstWhere(
          (w) => w.start.hour == 10 && w.chargerType == ChargerType.dcFast);
      expect(target.available, isTrue); // 1 of 8 plugs taken

      final cancelled = await bookingsRepo.updateStatus(
          'CF-LIVE-TEST', BookingStatus.cancelled);
      expect(cancelled.status, BookingStatus.cancelled);
    } finally {
      await conn.execute(
          Sql.named('DELETE FROM bookings WHERE id = @id'),
          parameters: {'id': 'CF-LIVE-TEST'});
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
