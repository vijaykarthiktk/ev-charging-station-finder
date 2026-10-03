import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/vehicle_profile.dart';

/// The user's garage: vehicles + which one is active. Null active means
/// "no vehicle set" (estimates fall back to a flat per-hour rate).
abstract class VehicleRepository {
  ({List<VehicleProfile> vehicles, String? activeId}) loadGarage();
  Future<void> saveGarage(List<VehicleProfile> vehicles, String? activeId);
}

class HiveVehicleRepository implements VehicleRepository {
  HiveVehicleRepository(this._box);
  final Box _box;

  static const _key = 'garage';
  static const _legacyKey = 'vehicle';

  @override
  ({List<VehicleProfile> vehicles, String? activeId}) loadGarage() {
    try {
      final raw = _box.get(_key);
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final vehicles = [
          for (final v in (data['vehicles'] as List? ?? const []))
            VehicleProfile.fromJson(Map<String, dynamic>.from(v as Map)),
        ];
        return (
          vehicles: vehicles,
          activeId: data['activeId'] as String?
        );
      }
      // Migrate the pre-garage single vehicle, if present.
      final legacy = _box.get(_legacyKey);
      if (legacy is Map) {
        final v = VehicleProfile.fromJson(Map<String, dynamic>.from(legacy));
        return (vehicles: [v], activeId: v.id);
      }
      return (vehicles: const [], activeId: null);
    } catch (_) {
      throw const StorageException(
          'Could not load your vehicles from this device.');
    }
  }

  @override
  Future<void> saveGarage(
      List<VehicleProfile> vehicles, String? activeId) async {
    try {
      await _box.put(_key, {
        'vehicles': [for (final v in vehicles) v.toJson()],
        'activeId': activeId,
      });
    } catch (_) {
      throw const StorageException();
    }
  }

  static Future<Box> openBox() =>
      Hive.openBox(AppConstants.vehicleBox);
}
