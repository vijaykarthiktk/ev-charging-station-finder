import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import 'booking_provider.dart';

/// Lifetime charging stats. Cancelled bookings are excluded — they
/// never delivered energy.
({
  int sessions,
  double energyKwh,
  double spent,
  String? topStation,
}) spendingSummary(List<Booking> bookings) {
  final done = bookings
      .where((b) => b.status != BookingStatus.cancelled)
      .toList();
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final b in done) {
    counts[b.stationId] = (counts[b.stationId] ?? 0) + 1;
    names[b.stationId] = b.stationName;
  }
  String? top;
  var topCount = 0;
  counts.forEach((id, c) {
    if (c > topCount) {
      topCount = c;
      top = names[id];
    }
  });
  return (
    sessions: done.length,
    energyKwh: (done.fold<double>(0, (a, b) => a + b.energyKwh) * 10).round() / 10,
    spent: done.fold<double>(0, (a, b) => a + b.estimatedPrice),
    topStation: top,
  );
}

final spendingSummaryProvider = Provider(
  (ref) => spendingSummary(ref.watch(bookingsProvider).value ?? []),
);
