import 'package:chargefind/models/booking.dart';
import 'package:chargefind/models/charger_type.dart';
import 'package:chargefind/models/charging_slot.dart';
import 'package:chargefind/models/charging_station.dart';
import 'package:chargefind/providers/booking_provider.dart';
import 'package:chargefind/repositories/station_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChargingStation get _tata => const ChargingStation(
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

BookingFormState _form({
  DateTime? date,
  TimeOfDay? start,
  TimeOfDay? end,
  ChargerType? charger,
}) =>
    BookingFormState(
        date: date, start: start, end: end, chargerType: charger);

/// Deterministic stand-in for the backend: all windows free except
/// the 10:00 block, 3 of 8 plugs free right now.
class _FakeStationRepository implements StationRepository {
  @override
  Future<List<ChargingStation>> fetchStations() async => [_tata];

  @override
  Future<AvailabilitySummary> fetchAvailability(String stationId) async =>
      const AvailabilitySummary(total: 8, available: 3, isOffline: false);

  @override
  Future<List<ChargingSlot>> fetchLiveAvailability(String stationId,
      {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    return [
      for (var h = 6; h < 22; h++)
        ChargingSlot(
          id: 'w$h',
          stationId: stationId,
          date: day,
          start: DateTime(day.year, day.month, day.day, h),
          end: DateTime(day.year, day.month, day.day, h + 1),
          chargerType: ChargerType.dcFast,
          available: h != 10,
        ),
    ];
  }
}

void main() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  test('station JSON round-trips', () {
    final restored = ChargingStation.fromJson(_tata.toJson());
    expect(restored.id, 'tata-hub');
    expect(restored.chargerTypes, [ChargerType.dcFast]);
    expect(restored.powerKw(ChargerType.dcFast), 60);
  });

  test('booking JSON round-trips', () {
    final real = Booking(
      id: 'CF-1',
      stationId: 'tata-hub',
      stationName: 'Tata Power Charging Hub',
      chargerType: ChargerType.dcFast,
      date: tomorrow,
      startTime: tomorrow.add(const Duration(hours: 10)),
      endTime: tomorrow.add(const Duration(hours: 11)),
      pricePerKwh: 18,
      estimatedPrice: 180,
      status: BookingStatus.confirmed,
      createdAt: now,
    );
    final restored = Booking.fromJson(real.toJson());
    expect(restored.id, 'CF-1');
    expect(restored.startTime.hour, 10);
    expect(restored.status, BookingStatus.confirmed);
  });

  test('estimatePrice: 1h at ₹18/kWh ≈ ₹180', () {
    expect(
      estimatePrice(pricePerKwh: 18, startMinutes: 600, endMinutes: 660),
      180,
    );
  });

  test('validation flags every missing field', () {
    final errors = validateBookingForm(
      station: _tata,
      form: _form(),
      slotsForDate: const [],
      now: now,
    );
    expect(errors, contains('Please select a date.'));
    expect(errors, contains('Please select a charger type.'));
    expect(errors, contains('Please select a start time.'));
    expect(errors, contains('Please select an end time.'));
  });

  test('validation rejects end before start', () {
    final errors = validateBookingForm(
      station: _tata,
      form: _form(
        date: tomorrow,
        charger: ChargerType.dcFast,
        start: const TimeOfDay(hour: 11, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ),
      slotsForDate: const [],
      now: now,
    );
    expect(errors, contains('End time must be after start time.'));
  });

  test('validation rejects outside operating hours', () {
    final errors = validateBookingForm(
      station: _tata,
      form: _form(
        date: tomorrow,
        charger: ChargerType.dcFast,
        start: const TimeOfDay(hour: 22, minute: 0),
        end: const TimeOfDay(hour: 23, minute: 0),
      ),
      slotsForDate: const [],
      now: now,
    );
    expect(errors.any((e) => e.contains('Station hours are')), isTrue);
  });

  test('unavailable window fails validation', () async {
    final repo = _FakeStationRepository();
    final slots =
        await repo.fetchLiveAvailability('tata-hub', date: tomorrow);
    // 16 hourly windows (06:00–22:00) × 1 charger type.
    expect(slots.length, 16);

    final errors = validateBookingForm(
      station: _tata,
      form: _form(
        date: tomorrow,
        charger: ChargerType.dcFast,
        start: const TimeOfDay(hour: 10, minute: 0),
        end: const TimeOfDay(hour: 11, minute: 0),
      ),
      slotsForDate: slots,
      now: now,
    );
    expect(errors, contains('That slot is no longer available. Pick another time.'));

    final summary = await repo.fetchAvailability('tata-hub');
    expect(summary.available, 3);
    expect(summary.occupied, 5);
  });

  test('validation passes for a genuinely free window', () async {
    final repo = _FakeStationRepository();
    final slots =
        await repo.fetchLiveAvailability('tata-hub', date: tomorrow);
    final free =
        slots.where((s) => s.available).first;
    final errors = validateBookingForm(
      station: _tata,
      form: _form(
        date: tomorrow,
        charger: ChargerType.dcFast,
        start: TimeOfDay(hour: free.start.hour, minute: 0),
        end: TimeOfDay(
            hour: free.start.hour + 1, minute: 0),
      ),
      slotsForDate: slots,
      now: now,
    );
    expect(errors, isEmpty);
  });
}
