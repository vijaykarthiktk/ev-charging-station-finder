import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/formatters.dart';
import '../models/booking.dart';
import '../models/charger_type.dart';
import '../models/charging_slot.dart';
import '../models/charging_station.dart';
import '../models/vehicle_profile.dart';
import 'repository_providers.dart';
import 'station_provider.dart';
import 'vehicle_provider.dart';

/// Editable slot-selection state. Null = not chosen yet.
class BookingFormState {
  const BookingFormState({
    this.date,
    this.start,
    this.end,
    this.chargerType,
  });

  final DateTime? date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final ChargerType? chargerType;

  bool get hasDateTime => date != null && start != null && end != null;

  BookingFormState copyWith({
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    ChargerType? chargerType,
  }) =>
      BookingFormState(
        date: date ?? this.date,
        start: start ?? this.start,
        end: end ?? this.end,
        chargerType: chargerType ?? this.chargerType,
      );
}

class BookingFormNotifier extends Notifier<BookingFormState> {
  @override
  BookingFormState build() => const BookingFormState();

  void init({ChargerType? chargerType}) =>
      state = BookingFormState(chargerType: chargerType);

  /// Prefill the form from an existing booking (reschedule flow).
  void load({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required ChargerType chargerType,
  }) =>
      state = BookingFormState(
        date: DateTime(date.year, date.month, date.day),
        start: start,
        end: end,
        chargerType: chargerType,
      );

  void setDate(DateTime date) =>
      state = state.copyWith(date: DateTime(date.year, date.month, date.day));

  void setStart(TimeOfDay start) => state = state.copyWith(start: start);
  void setEnd(TimeOfDay end) => state = state.copyWith(end: end);
  void setCharger(ChargerType type) =>
      state = state.copyWith(chargerType: type);

  void reset() => state = const BookingFormState();
}

final bookingFormProvider =
    NotifierProvider<BookingFormNotifier, BookingFormState>(
        BookingFormNotifier.new);

/// All persisted bookings (hydrated from local storage on startup).
final bookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).fetchBookings(),
);

/// Most recent confirmed booking, or null when there is none.
final activeBookingProvider = Provider<Booking?>(
  (ref) => ref.watch(bookingsProvider).value?.where(
        (b) => b.status == BookingStatus.confirmed,
      ).firstOrNull,
);

/// Pure validation for §5. Returns user-facing messages; empty = valid.
/// [slotsForDate] is the asynchronously re-checked live grid for [form.date].
List<String> validateBookingForm({
  required ChargingStation station,
  required BookingFormState form,
  required List<ChargingSlot> slotsForDate,
  required DateTime now,
}) {
  final errors = <String>[];
  if (form.date == null) errors.add('Please select a date.');
  if (form.chargerType == null) {
    errors.add('Please select a charger type.');
  } else if (!station.chargerTypes.contains(form.chargerType)) {
    errors.add(
        '${form.chargerType!.fullLabel} is not available at this station.');
  }
  if (form.start == null) errors.add('Please select a start time.');
  if (form.end == null) errors.add('Please select an end time.');
  if (errors.isNotEmpty) return errors;

  final startMin = form.start!.minutesSinceMidnight;
  final endMin = form.end!.minutesSinceMidnight;
  if (endMin <= startMin) {
    return [...errors, 'End time must be after start time.'];
  }

  final openMin = station.operatingStartHour * 60;
  final closeMin = station.operatingEndHour * 60;
  if (startMin < openMin || endMin > closeMin) {
    return [
      ...errors,
      'Station hours are ${formatOperatingHours(station.operatingStartHour, station.operatingEndHour)}.'
    ];
  }

  if (isSameDay(form.date!, now)) {
    final startAt = DateTime(form.date!.year, form.date!.month, form.date!.day,
        form.start!.hour, form.start!.minute);
    if (!startAt
        .isAfter(now.add(AppConstants.bookingLeadTime))) {
      return [
        ...errors,
        'Start time must be at least ${AppConstants.bookingLeadTime.inMinutes} minutes from now.'
      ];
    }
  }

  final wantStart = DateTime(form.date!.year, form.date!.month, form.date!.day,
      form.start!.hour, form.start!.minute);
  final wantEnd = DateTime(form.date!.year, form.date!.month, form.date!.day,
      form.end!.hour, form.end!.minute);
  final overlapped = slotsForDate
      .where((s) =>
          s.chargerType == form.chargerType && s.overlaps(wantStart, wantEnd))
      .toList();
  if (overlapped.isEmpty || overlapped.any((s) => !s.available)) {
    return [...errors, 'That slot is no longer available. Pick another time.'];
  }
  return errors;
}

/// Rough cost preview: [AppConstants.kwhPerHour] kWh per booked hour.
double estimatePrice({
  required double pricePerKwh,
  required int startMinutes,
  required int endMinutes,
}) {
  final hours = (endMinutes - startMinutes) / 60;
  return hours * AppConstants.kwhPerHour * pricePerKwh;
}

/// Vehicle-aware session estimate. With a vehicle profile the energy is a
/// 20→80% top-up capped by what the plug can deliver in the window;
/// without one it falls back to the flat per-hour rate.
({double energyKwh, double price}) estimateSession({
  required double pricePerKwh,
  required double powerKw,
  required int minutes,
  VehicleProfile? vehicle,
}) {
  final hours = minutes / 60;
  final raw = vehicle == null
      ? hours * AppConstants.kwhPerHour
      : min(vehicle.batteryKwh * 0.6, powerKw * hours * 0.9);
  final energy = (raw * 10).round() / 10;
  return (energyKwh: energy, price: energy * pricePerKwh);
}

String _newBookingId() =>
    'CF-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}'
    '${Random().nextInt(1296).toRadixString(36).toUpperCase().padLeft(2, '0')}';

/// Runs the booking flow: re-check → create → persist → refresh UI.
class BookingController extends Notifier<AsyncValue<Booking?>> {
  @override
  AsyncValue<Booking?> build() => const AsyncValue.data(null);

  Future<Booking> createBooking({
    required ChargingStation station,
    required BookingFormState form,
  }) async {
    state = const AsyncLoading();
    final outcome = await AsyncValue.guard(() async {
      if (station.isOffline) throw const StationOfflineException();
      final stationRepo = ref.read(stationRepositoryProvider);
      final slots = await stationRepo.fetchLiveAvailability(station.id,
          date: form.date);
      final problems = validateBookingForm(
        station: station,
        form: form,
        slotsForDate: slots,
        now: DateTime.now(),
      );
      if (problems.isNotEmpty) {
        if (problems.any((e) => e.contains('no longer available'))) {
          throw const SlotUnavailableException();
        }
        throw BookingValidationException(problems.first);
      }
      final start = DateTime(form.date!.year, form.date!.month, form.date!.day,
          form.start!.hour, form.start!.minute);
      final end = DateTime(form.date!.year, form.date!.month, form.date!.day,
          form.end!.hour, form.end!.minute);
      final session = estimateSession(
        pricePerKwh: station.pricePerKwh,
        powerKw: station.powerKw(form.chargerType!),
        minutes: form.end!.minutesSinceMidnight -
            form.start!.minutesSinceMidnight,
        vehicle: ref.read(activeVehicleProvider),
      );
      final booking = Booking(
        id: _newBookingId(),
        stationId: station.id,
        stationName: station.name,
        chargerType: form.chargerType!,
        date: DateTime(form.date!.year, form.date!.month, form.date!.day),
        startTime: start,
        endTime: end,
        pricePerKwh: station.pricePerKwh,
        estimatedPrice: session.price,
        energyKwh: session.energyKwh,
        status: BookingStatus.confirmed,
        createdAt: DateTime.now(),
      );
      final saved =
          await ref.read(bookingRepositoryProvider).saveBooking(booking);
      await ref.read(reminderServiceProvider).scheduleReminder(
            bookingId: saved.id,
            title: 'Charging slot in 30 minutes',
            body:
                '${saved.stationName} · ${saved.chargerType.fullLabel} · ${formatTimeOfDay(TimeOfDay(hour: saved.startTime.hour, minute: saved.startTime.minute))}',
            startTime: saved.startTime,
          );
      ref.invalidate(bookingsProvider);
      ref.invalidate(availabilityProvider(station.id));
      ref.invalidate(slotsProvider);
      return saved;
    });
    state = outcome;
    if (outcome.hasError) throw outcome.error!;
    return outcome.requireValue;
  }

  /// Move [booking] to a new date/time on the same station: re-validate
  /// against live availability, then persist. Availability derives from
  /// stored bookings, so no hold bookkeeping is needed.
  Future<Booking> rescheduleBooking({
    required Booking booking,
    required ChargingStation station,
    required BookingFormState form,
  }) async {
    state = const AsyncLoading();
    final outcome = await AsyncValue.guard(() async {
      if (station.isOffline) throw const StationOfflineException();
      final stationRepo = ref.read(stationRepositoryProvider);
      final slots = await stationRepo.fetchLiveAvailability(station.id,
          date: form.date);
      final problems = validateBookingForm(
        station: station,
        form: form,
        slotsForDate: slots,
        now: DateTime.now(),
      );
      if (problems.isNotEmpty) {
        if (problems.any((e) => e.contains('no longer available'))) {
          throw const SlotUnavailableException();
        }
        throw BookingValidationException(problems.first);
      }
      final start = DateTime(
          form.date!.year,
          form.date!.month,
          form.date!.day,
          form.start!.hour,
          form.start!.minute);
      final end = DateTime(form.date!.year, form.date!.month, form.date!.day,
          form.end!.hour, form.end!.minute);
      final session = estimateSession(
        pricePerKwh: station.pricePerKwh,
        powerKw: station.powerKw(form.chargerType!),
        minutes: form.end!.minutesSinceMidnight -
            form.start!.minutesSinceMidnight,
        vehicle: ref.read(activeVehicleProvider),
      );
      final updated = Booking(
        id: booking.id,
        stationId: station.id,
        stationName: station.name,
        chargerType: form.chargerType!,
        date: DateTime(form.date!.year, form.date!.month, form.date!.day),
        startTime: start,
        endTime: end,
        pricePerKwh: station.pricePerKwh,
        estimatedPrice: session.price,
        energyKwh: session.energyKwh,
        status: booking.status,
        createdAt: booking.createdAt,
      );
      final saved =
          await ref.read(bookingRepositoryProvider).updateBooking(updated);
      final reminders = ref.read(reminderServiceProvider);
      await reminders.cancelReminder(saved.id);
      await reminders.scheduleReminder(
        bookingId: saved.id,
        title: 'Charging slot in 30 minutes',
        body:
            '${saved.stationName} · ${saved.chargerType.fullLabel} · ${formatTimeOfDay(TimeOfDay(hour: saved.startTime.hour, minute: saved.startTime.minute))}',
        startTime: saved.startTime,
      );
      ref.invalidate(bookingsProvider);
      ref.invalidate(availabilityProvider(station.id));
      ref.invalidate(slotsProvider);
      return saved;
    });
    state = outcome;
    if (outcome.hasError) throw outcome.error!;
    return outcome.requireValue;
  }

  Future<void> cancelBooking(Booking booking) async {
    state = const AsyncLoading();
    final outcome = await AsyncValue.guard(() async {
      await ref
          .read(bookingRepositoryProvider)
          .updateStatus(booking.id, BookingStatus.cancelled);
      await ref.read(reminderServiceProvider).cancelReminder(booking.id);
      ref.invalidate(bookingsProvider);
      ref.invalidate(availabilityProvider(booking.stationId));
      ref.invalidate(slotsProvider);
      return null;
    });
    state = outcome;
    if (outcome.hasError) throw outcome.error!;
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, AsyncValue<Booking?>>(
        BookingController.new);
