import 'charger_type.dart';
import 'connector_type.dart';

/// A physical EV charging station.
class ChargingStation {
  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.pricePerKwh,
    required this.chargerTypes,
    this.connectors = const [ConnectorType.ccs2, ConnectorType.type2],
    required this.powerKwByType,
    required this.totalSlots,
    required this.operatingStartHour,
    required this.operatingEndHour,
    required this.amenities,
    this.isOffline = false,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;

  /// Map position.
  final double latitude;
  final double longitude;

  final double pricePerKwh;
  final List<ChargerType> chargerTypes;

  /// Plug standards available at this station.
  final List<ConnectorType> connectors;

  /// Peak output per charger type, keyed by [ChargerType.label].
  final Map<String, double> powerKwByType;
  final int totalSlots;

  /// 24h bounds; endHour == 24 means midnight (24×7 when 0–24).
  final int operatingStartHour;
  final int operatingEndHour;
  final List<String> amenities;
  final bool isOffline;

  double powerKw(ChargerType type) => powerKwByType[type.label] ?? 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'distanceKm': distanceKm,
        'latitude': latitude,
        'longitude': longitude,
        'pricePerKwh': pricePerKwh,
        'chargerTypes': [for (final t in chargerTypes) t.label],
        'connectors': [for (final c in connectors) c.label],
        'powerKwByType': powerKwByType,
        'totalSlots': totalSlots,
        'operatingStartHour': operatingStartHour,
        'operatingEndHour': operatingEndHour,
        'amenities': amenities,
        'isOffline': isOffline,
      };

  factory ChargingStation.fromJson(Map<String, dynamic> json) =>
      ChargingStation(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        pricePerKwh: (json['pricePerKwh'] as num).toDouble(),
        chargerTypes: [
          for (final l in (json['chargerTypes'] as List))
            ChargerTypeX.fromLabel(l as String),
        ],
        connectors: switch (json['connectors'] as List?) {
          final List l when l.isNotEmpty => [
              for (final e in l) ConnectorTypeX.fromLabel(e as String),
            ],
          // Pre-connector payloads predate the field: assume all standards.
          _ => const [
              ConnectorType.ccs2,
              ConnectorType.chademo,
              ConnectorType.type2,
            ],
        },
        powerKwByType: {
          for (final e in (json['powerKwByType'] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
        },
        totalSlots: json['totalSlots'] as int,
        operatingStartHour: json['operatingStartHour'] as int,
        operatingEndHour: json['operatingEndHour'] as int,
        amenities: [for (final a in (json['amenities'] as List)) a as String],
        isOffline: json['isOffline'] as bool? ?? false,
      );
}
