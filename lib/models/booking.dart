import 'charger_type.dart';

enum BookingStatus { confirmed, cancelled, completed }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.completed => 'Completed',
      };

  static BookingStatus fromName(String name) => BookingStatus.values
      .firstWhere((s) => s.name == name, orElse: () => BookingStatus.confirmed);
}

/// A persisted charging-slot booking.
class Booking {
  const Booking({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.chargerType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.pricePerKwh,
    required this.estimatedPrice,
    this.energyKwh = 0,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final String stationName;
  final ChargerType chargerType;

  /// Day (clock stripped) of the booking.
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double pricePerKwh;
  final double estimatedPrice;

  /// Planned energy in kWh (0 when estimated without a vehicle profile).
  final double energyKwh;
  final BookingStatus status;
  final DateTime createdAt;

  Booking copyWith({BookingStatus? status, double? estimatedPrice}) =>
      Booking(
        id: id,
        stationId: stationId,
        stationName: stationName,
        chargerType: chargerType,
        date: date,
        startTime: startTime,
        endTime: endTime,
        pricePerKwh: pricePerKwh,
        estimatedPrice: estimatedPrice ?? this.estimatedPrice,
        energyKwh: energyKwh,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stationId': stationId,
        'stationName': stationName,
        'chargerType': chargerType.label,
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'pricePerKwh': pricePerKwh,
        'estimatedPrice': estimatedPrice,
        'energyKwh': energyKwh,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        stationId: json['stationId'] as String,
        stationName: json['stationName'] as String,
        chargerType: ChargerTypeX.fromLabel(json['chargerType'] as String),
        date: DateTime.parse(json['date'] as String),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        pricePerKwh: (json['pricePerKwh'] as num).toDouble(),
        estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
        energyKwh: (json['energyKwh'] as num?)?.toDouble() ?? 0,
        status: BookingStatusX.fromName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
