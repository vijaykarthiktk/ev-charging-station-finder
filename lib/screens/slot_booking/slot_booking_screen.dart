import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/charger_type.dart';
import '../../models/charging_station.dart';
import '../../providers/booking_provider.dart';
import '../../providers/station_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/booking_summary.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import 'booking_confirmation_screen.dart';

/// Figma 03 Slot Booking: date cells, time boxes, charger boxes,
/// live validation, summary, and async re-check on confirm.
/// Pass [rescheduleBooking] to move an existing booking instead of
/// creating a new one (form prefills, confirm saves changes).
class SlotBookingScreen extends ConsumerStatefulWidget {
  const SlotBookingScreen({
    super.key,
    required this.station,
    this.rescheduleBooking,
  });

  final ChargingStation station;
  final Booking? rescheduleBooking;

  @override
  ConsumerState<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends ConsumerState<SlotBookingScreen> {
  final _dayScroll = ScrollController();

  @override
  void dispose() {
    _dayScroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill/prefetch only after the first frame: writing a provider
    // during initState trips Riverpod's build-phase guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = widget.rescheduleBooking;
      if (existing != null) {
        ref.read(bookingFormProvider.notifier).load(
              date: existing.date,
              start: TimeOfDay(
                  hour: existing.startTime.hour,
                  minute: existing.startTime.minute),
              end: TimeOfDay(
                  hour: existing.endTime.hour,
                  minute: existing.endTime.minute),
              chargerType: existing.chargerType,
            );
      } else {
        final now = DateTime.now();
        ref.read(bookingFormProvider.notifier).setDate(now);
      }
      // Scroll the date row so the selected day is visible
      // (matters when rescheduling to a day off-screen).
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDate());
    });
  }

  void _scrollToDate() {
    if (!_dayScroll.hasClients) return;
    final selected = ref.read(bookingFormProvider).date;
    if (selected == null) return;
    final i = _days.indexWhere((d) => isSameDay(d, selected));
    if (i < 0) return;
    _dayScroll.jumpTo((i * 66)
        .toDouble()
        .clamp(0, _dayScroll.position.maxScrollExtent));
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 0; i < AppConstants.bookingHorizonDays; i++)
        today.add(Duration(days: i)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final isReschedule = widget.rescheduleBooking != null;
    final form = ref.watch(bookingFormProvider);
    final controller = ref.watch(bookingControllerProvider);
    final now = DateTime.now();
    final date = form.date ?? DateTime(now.year, now.month, now.day);
    final slots = ref.watch(slotsProvider((stationId: station.id, date: date)));

    final complete = form.hasDateTime && form.chargerType != null;
    final liveErrors = complete && slots.hasValue
        ? validateBookingForm(
            station: station,
            form: form,
            slotsForDate: slots.requireValue,
            now: now,
          )
        : <String>[];

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScreenHeader(
                title: isReschedule ? 'Reschedule' : 'Select Slot',
                showBack: true,
                step: isReschedule ? null : 2,
                stepLabel: isReschedule ? null : 'Select Slot',
              ),
              const SizedBox(height: 12),
              Text(station.name,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Station hours: ${station.operatingStartHour == 0 && station.operatingEndHour == 24 ? 'Open 24 × 7' : formatOperatingHours(station.operatingStartHour, station.operatingEndHour)} · ${formatRupees(station.pricePerKwh)}/kWh',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Date'),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  controller: _dayScroll,
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) =>
                      _DayCell(day: _days[i], selected: isSameDay(_days[i], date)),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Time'),
              Row(
                children: [
                  Expanded(
                      child: _TimeBox(
                          value: form.start,
                          empty: 'Start',
                          isStart: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TimeBox(
                          value: form.end, empty: 'End', isStart: false)),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Charger'),
              for (final t in station.chargerTypes)
                _ChargerBox(station: station, type: t),
              const SizedBox(height: 12),
              slots.when(
                data: (list) {
                  final current =
                      form.chargerType ?? station.chargerTypes.first;
                  final typed =
                      list.where((s) => s.chargerType == current);
                  final free = typed.where((s) => s.available).length;
                  return Text(
                    '$free of ${typed.length} hourly windows free on ${formatDate(date)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              if (liveErrors.isNotEmpty)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in liveErrors)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Text(e,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer)),
                          ),
                      ],
                    ),
                  ),
                ),
              if (complete && liveErrors.isEmpty)
                BookingSummary(booking: _preview(station, form)),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: !complete || controller.isLoading
                  ? null
                  : () => _confirm(station, form),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isReschedule ? 'Save Changes' : 'Confirm Booking'),
            ),
          ),
        ),
      ),
    );
  }

  /// Non-persisted preview for the summary card.
  Booking _preview(ChargingStation station, BookingFormState form) {
    final session = estimateSession(
      pricePerKwh: station.pricePerKwh,
      powerKw: station.powerKw(form.chargerType!),
      minutes: form.end!.minutesSinceMidnight -
          form.start!.minutesSinceMidnight,
      vehicle: ref.read(activeVehicleProvider),
    );
    return Booking(
      id: 'preview',
      stationId: station.id,
      stationName: station.name,
      chargerType: form.chargerType!,
      date: DateTime(form.date!.year, form.date!.month, form.date!.day),
      startTime: DateTime(form.date!.year, form.date!.month, form.date!.day,
          form.start!.hour, form.start!.minute),
      endTime: DateTime(form.date!.year, form.date!.month, form.date!.day,
          form.end!.hour, form.end!.minute),
      pricePerKwh: station.pricePerKwh,
      estimatedPrice: session.price,
      energyKwh: session.energyKwh,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _confirm(
      ChargingStation station, BookingFormState form) async {
    final existing = widget.rescheduleBooking;
    try {
      if (existing != null) {
        await ref.read(bookingControllerProvider.notifier).rescheduleBooking(
            booking: existing, station: station, form: form);
        ref.read(bookingFormProvider.notifier).reset();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rescheduled.')),
        );
        Navigator.of(context).pop();
        return;
      }
      final booking = await ref
          .read(bookingControllerProvider.notifier)
          .createBooking(station: station, form: form);
      ref.read(bookingFormProvider.notifier).reset();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(booking: booking)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? e.userMessage
                : 'Something went wrong. Please try again.')),
      );
    }
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      );
}

/// 58×56 date cell: primary when selected, grey otherwise.
class _DayCell extends ConsumerWidget {
  const _DayCell({required this.day, required this.selected});
  final DateTime day;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => ref.read(bookingFormProvider.notifier).setDate(day),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 58,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${day.day} ${_month(day)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }

  String _month(DateTime d) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][d.month - 1];
}

/// Grey time box; taps open the system time picker.
class _TimeBox extends ConsumerWidget {
  const _TimeBox(
      {required this.value, required this.empty, required this.isStart});
  final TimeOfDay? value;
  final String empty;
  final bool isStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked == null) return;
        final form = ref.read(bookingFormProvider.notifier);
        isStart ? form.setStart(picked) : form.setEnd(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule,
                size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? empty : formatTimeOfDay(value!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey charger box, primary when selected.
class _ChargerBox extends ConsumerWidget {
  const _ChargerBox({required this.station, required this.type});
  final ChargingStation station;
  final ChargerType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(bookingFormProvider).chargerType == type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () =>
            ref.read(bookingFormProvider.notifier).setCharger(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color:
                selected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${type.fullLabel} · ${station.powerKw(type).toStringAsFixed(0)} kW',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    selected ? scheme.onPrimary : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
