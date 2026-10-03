import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Format a rupee amount with Indian digit grouping: ₹1,23,456.
String formatRupees(num amount) {
  final rounded = amount.round();
  final digits = rounded.abs().toString();
  final tail = digits.length > 3 ? digits.substring(digits.length - 3) : digits;
  var head = digits.length > 3 ? digits.substring(0, digits.length - 3) : '';
  final groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.add(head);
  groups.add(tail);
  final sign = rounded < 0 ? '-' : '';
  return '$sign${AppConstants.currencySymbol}${groups.join(',')}';
}

/// "12 October 2026"
String formatDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// "10:00 AM"
String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// "10:00 AM – 11:00 AM"
String formatTimeRange(TimeOfDay start, TimeOfDay end) =>
    '${formatTimeOfDay(start)} – ${formatTimeOfDay(end)}';

/// "6:00 AM – 10:00 PM" from 24h bounds (end == 24 means midnight).
String formatOperatingHours(int startHour, int endHour) {
  TimeOfDay tod(int h) => TimeOfDay(hour: h % 24, minute: 0);
  return formatTimeRange(tod(startHour), tod(endHour));
}

extension TimeOfDayCompare on TimeOfDay {
  int get minutesSinceMidnight => hour * 60 + minute;
}

/// "10 kWh" / "9.9 kWh" — drops the decimal for whole numbers.
String formatKwh(double energyKwh) {
  final v = energyKwh.truncateToDouble() == energyKwh
      ? energyKwh.toInt().toString()
      : energyKwh.toStringAsFixed(1);
  return '$v kWh';
}

/// Day-only equality, ignoring clock time.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
