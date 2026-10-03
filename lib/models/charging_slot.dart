import 'charger_type.dart';

/// One bookable hourly window on a specific date and charger type.
class ChargingSlot {
  const ChargingSlot({
    required this.id,
    required this.stationId,
    required this.date,
    required this.start,
    required this.end,
    required this.chargerType,
    required this.available,
  });

  final String id;
  final String stationId;

  /// Day (clock stripped) this window belongs to.
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final ChargerType chargerType;
  final bool available;

  /// True when [start]–[end] overlaps this window.
  bool overlaps(DateTime start, DateTime end) =>
      this.start.isBefore(end) && start.isBefore(this.end);

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationId': stationId,
        'date': date.toIso8601String(),
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'chargerType': chargerType.label,
        'available': available,
      };

  factory ChargingSlot.fromJson(Map<String, dynamic> json) => ChargingSlot(
        id: json['id'] as String,
        stationId: json['stationId'] as String,
        date: DateTime.parse(json['date'] as String),
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        chargerType: ChargerTypeX.fromLabel(json['chargerType'] as String),
        available: json['available'] as bool,
      );
}
