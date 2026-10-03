import 'connector_type.dart';

/// One of the user's EVs. The garage's active vehicle drives
/// cost/energy estimates and connector matching.
class VehicleProfile {
  const VehicleProfile({
    required this.id,
    required this.name,
    required this.batteryKwh,
    required this.connector,
  });

  final String id;
  final String name;

  /// Usable battery capacity in kWh.
  final double batteryKwh;
  final ConnectorType connector;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'batteryKwh': batteryKwh,
        'connector': connector.label,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) =>
      VehicleProfile(
        id: json['id'] as String? ?? 'v-legacy',
        name: json['name'] as String? ?? 'My EV',
        batteryKwh: (json['batteryKwh'] as num).toDouble(),
        connector: ConnectorTypeX.fromLabel(json['connector'] as String),
      );
}
