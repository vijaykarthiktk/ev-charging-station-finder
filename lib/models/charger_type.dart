import 'package:flutter/material.dart';

/// Charger connector technology offered by a station.
enum ChargerType {
  ac,
  dcFast,
  dcUltraFast,
}

extension ChargerTypeX on ChargerType {
  /// "AC", "DC Fast", "DC Ultra Fast" — stable key for JSON round-trips.
  String get label => switch (this) {
        ChargerType.ac => 'AC',
        ChargerType.dcFast => 'DC Fast',
        ChargerType.dcUltraFast => 'DC Ultra Fast',
      };

  /// Full display name used in summaries.
  String get fullLabel => switch (this) {
        ChargerType.ac => 'AC Charger',
        ChargerType.dcFast => 'DC Fast Charger',
        ChargerType.dcUltraFast => 'DC Ultra Fast Charger',
      };

  /// Distinct badge color per type (pairs with the text label, not color-only).
  Color badgeColor(ColorScheme scheme) => switch (this) {
        ChargerType.ac => scheme.secondaryContainer,
        ChargerType.dcFast => scheme.primaryContainer,
        ChargerType.dcUltraFast => scheme.tertiaryContainer,
      };

  Color onBadgeColor(ColorScheme scheme) => switch (this) {
        ChargerType.ac => scheme.onSecondaryContainer,
        ChargerType.dcFast => scheme.onPrimaryContainer,
        ChargerType.dcUltraFast => scheme.onTertiaryContainer,
      };

  IconData get icon => switch (this) {
        ChargerType.ac => Icons.power_outlined,
        ChargerType.dcFast => Icons.bolt_outlined,
        ChargerType.dcUltraFast => Icons.bolt,
      };

  static ChargerType fromLabel(String label) =>
      ChargerType.values.firstWhere((t) => t.label == label,
          orElse: () => ChargerType.ac);
}
