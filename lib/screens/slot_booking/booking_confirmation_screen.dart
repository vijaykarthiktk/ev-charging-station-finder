import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../widgets/booking_summary.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/screen_header.dart';
import '../station_list/active_booking_screen.dart';

/// Figma 04 Booking Confirmed: seal, summary, ID chip, next actions.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ScreenHeader(
                title: 'Booking Confirmed',
                showBack: true,
                step: 4,
                stepLabel: 'Booking Confirmed',
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                  ),
                  child: Icon(Icons.check,
                      size: 44, color: scheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text('Slot booked successfully',
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(fontSize: 19)),
              const SizedBox(height: 4),
              Text('Your charger will be ready at the selected time.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              BookingSummary(booking: booking),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Booking ID',
                                style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                            SelectableText(booking.id,
                                style: text.titleMedium),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(booking.status.label,
                            style: text.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Created ${formatDate(booking.createdAt)}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ActiveBookingScreen()),
                  ),
                  child: const Text('View Active Booking'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: scheme.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to Stations'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
