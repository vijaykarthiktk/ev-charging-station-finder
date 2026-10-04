import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/booking.dart';
import '../models/charger_type.dart';

/// Pre-confirmation review card (§4 example) and confirmation/history reuse.
class BookingSummary extends StatelessWidget {
  const BookingSummary({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Summary',
                style: text.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _row(context, 'Station', booking.stationName),
            _row(context, 'Date', formatDate(booking.date)),
            _row(context, 'Time',
                '${formatTimeOfDay(_tod(booking.startTime))} – ${formatTimeOfDay(_tod(booking.endTime))}'),
            _row(context, 'Charger', booking.chargerType.fullLabel),
            const Divider(height: 24),
            _row(context, 'Estimated Cost',
                '${formatRupees(booking.estimatedPrice)}${_energySuffix(booking.energyKwh)}',
                valueEmphasis: true),
          ],
        ),
      ),
    );
  }

  TimeOfDay _tod(DateTime d) => TimeOfDay(hour: d.hour, minute: d.minute);

  /// " · ≈10 kWh" appended to the cost when a vehicle estimate exists.
  String _energySuffix(double energyKwh) {
    if (energyKwh <= 0) return '';
    final v = energyKwh.truncateToDouble() == energyKwh
        ? energyKwh.toInt().toString()
        : energyKwh.toStringAsFixed(1);
    return ' · ≈$v kWh';
  }

  Widget _row(BuildContext context, String label, String value,
      {bool valueEmphasis = false}) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label,
                style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: (valueEmphasis ? text.bodyLarge : text.bodySmall)
                    ?.copyWith(
                        fontWeight: valueEmphasis
                            ? FontWeight.w700
                            : FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}
