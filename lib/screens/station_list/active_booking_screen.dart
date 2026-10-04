import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/charger_type.dart';
import '../../providers/booking_provider.dart';
import '../../providers/station_provider.dart';
import '../../widgets/async_state_views.dart';
import '../../widgets/booking_summary.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import '../slot_booking/slot_booking_screen.dart';

/// Figma 05 My Bookings: active banner, summary, cancel, history.
class ActiveBookingScreen extends ConsumerWidget {
  const ActiveBookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: bookings.when(
            data: (list) {
              final active = list
                  .where((b) => b.status == BookingStatus.confirmed)
                  .firstOrNull;
              final past = list
                  .where((b) => b.status != BookingStatus.confirmed)
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ScreenHeader(title: 'My Bookings', showBack: true),
                  const SizedBox(height: 12),
                  if (active == null)
                    const EmptyState(
                      message:
                          'No active booking. Find a station and book a charging slot.',
                    )
                  else ...[
                    _ActiveBanner(booking: active),
                    _ReminderCaption(booking: active),
                    const SizedBox(height: 12),
                    BookingSummary(booking: active),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _reschedule(context, ref, active),
                        child: const Text('Reschedule'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _cancel(context, ref, active),
                        child: const Text('Cancel Booking'),
                      ),
                    ),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Booking History',
                        style: text.titleMedium),
                    const SizedBox(height: 8),
                    for (final b in past)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HistoryRow(booking: b),
                      ),
                  ],
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(bookingsProvider),
            ),
          ),
        ),
      ),
    );
  }

  void _reschedule(BuildContext context, WidgetRef ref, Booking booking) {
    final station = ref
        .read(stationsProvider)
        .value
        ?.where((s) => s.id == booking.stationId)
        .firstOrNull;
    if (station == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station no longer available.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SlotBookingScreen(station: station, rescheduleBooking: booking),
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, Booking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
            'Your ${booking.chargerType.fullLabel} slot at ${booking.stationName} will be released.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep it')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cancel Booking')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref
          .read(bookingControllerProvider.notifier)
          .cancelBooking(booking);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e is AppException
                ? e.userMessage
                : 'Something went wrong. Please try again.')),
      );
    }
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Booking',
                    style: text.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer)),
                SelectableText(booking.id,
                    style: text.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(booking.status.label,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onPrimaryContainer)),
          ),
        ],
      ),
    );
  }
}

class _ReminderCaption extends StatelessWidget {
  const _ReminderCaption({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final reminderAt =
        booking.startTime.subtract(const Duration(minutes: 30));
    if (!reminderAt.isAfter(DateTime.now())) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Reminder · ${formatTimeOfDay(TimeOfDay(hour: reminderAt.hour, minute: reminderAt.minute))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.booking});
  final Booking booking;

  TimeOfDay _tod(DateTime d) => TimeOfDay(hour: d.hour, minute: d.minute);

  Color _statusColor(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Theme.of(context).colorScheme.primary;
      case BookingStatus.completed:
        return AppTheme.available;
      case BookingStatus.cancelled:
        return AppTheme.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = _statusColor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.stationName, style: text.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDate(booking.date)} · ${formatTimeOfDay(_tod(booking.startTime))} – ${formatTimeOfDay(_tod(booking.endTime))}',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.chargerType.fullLabel} · ${formatRupees(booking.estimatedPrice)}',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(booking.status.label,
                style: text.bodySmall?.copyWith(
                    color: statusColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
