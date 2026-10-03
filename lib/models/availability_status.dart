import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Semantic live-availability state. Always rendered as color + icon + text.
enum AvailabilityStatus {
  available,
  limited,
  full,
  offline,
}

extension AvailabilityStatusX on AvailabilityStatus {
  String get label => switch (this) {
        AvailabilityStatus.available => 'Available',
        AvailabilityStatus.limited => 'Limited',
        AvailabilityStatus.full => 'Full',
        AvailabilityStatus.offline => 'Offline',
      };

  IconData get icon => switch (this) {
        AvailabilityStatus.available => Icons.check_circle,
        AvailabilityStatus.limited => Icons.warning_amber_rounded,
        AvailabilityStatus.full => Icons.cancel,
        AvailabilityStatus.offline => Icons.cloud_off,
      };

  Color get color => switch (this) {
        AvailabilityStatus.available => AppTheme.available,
        AvailabilityStatus.limited => AppTheme.limited,
        AvailabilityStatus.full => AppTheme.full,
        AvailabilityStatus.offline => AppTheme.offline,
      };

  /// Derive from free/total plug counts.
  static AvailabilityStatus fromCounts({
    required bool isOffline,
    required int available,
    required int total,
  }) {
    if (isOffline) return AvailabilityStatus.offline;
    if (available <= 0) return AvailabilityStatus.full;
    if (available * 2 < total) return AvailabilityStatus.limited;
    return AvailabilityStatus.available;
  }
}
