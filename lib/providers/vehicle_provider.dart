import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/vehicle_profile.dart';
import 'repository_providers.dart';

/// The garage: owned vehicles + the active one used for estimates.
class VehicleGarage {
  const VehicleGarage({this.vehicles = const [], this.activeId});

  final List<VehicleProfile> vehicles;
  final String? activeId;

  VehicleProfile? get active {
    if (vehicles.isEmpty) return null;
    return vehicles.where((v) => v.id == activeId).firstOrNull ??
        vehicles.first;
  }

  VehicleGarage copyWith({
    List<VehicleProfile>? vehicles,
    String? Function()? activeId,
  }) =>
      VehicleGarage(
        vehicles: vehicles ?? this.vehicles,
        activeId: activeId != null ? activeId() : this.activeId,
      );
}

String _newVehicleId() =>
    'v-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

class VehicleGarageNotifier extends Notifier<VehicleGarage> {
  @override
  VehicleGarage build() {
    final doc = ref.watch(vehicleRepositoryProvider).loadGarage();
    return VehicleGarage(vehicles: doc.vehicles, activeId: doc.activeId);
  }

  Future<void> _persist() => ref
      .read(vehicleRepositoryProvider)
      .saveGarage(state.vehicles, state.activeId);

  Future<void> addVehicle({
    required String name,
    required double batteryKwh,
    required connector,
  }) async {
    final vehicle = VehicleProfile(
      id: _newVehicleId(),
      name: name.trim().isEmpty ? 'My EV' : name.trim(),
      batteryKwh: batteryKwh,
      connector: connector,
    );
    try {
      state = state.copyWith(
        vehicles: [...state.vehicles, vehicle],
        activeId: state.activeId == null ? () => vehicle.id : null,
      );
      await _persist();
    } catch (_) {
      throw const StorageException();
    }
  }

  Future<void> updateVehicle(VehicleProfile vehicle) async {
    try {
      state = state.copyWith(
        vehicles: [
          for (final v in state.vehicles)
            if (v.id == vehicle.id) vehicle else v,
        ],
      );
      await _persist();
    } catch (_) {
      throw const StorageException();
    }
  }

  Future<void> removeVehicle(String id) async {
    try {
      final rest = state.vehicles.where((v) => v.id != id).toList();
      state = state.copyWith(
        vehicles: rest,
        activeId: state.activeId == id
            ? () => rest.isEmpty
                ? null
                : rest.first.id
            : null,
      );
      await _persist();
    } catch (_) {
      throw const StorageException();
    }
  }

  Future<void> selectVehicle(String id) async {
    try {
      state = state.copyWith(activeId: () => id);
      await _persist();
    } catch (_) {
      throw const StorageException();
    }
  }
}

final vehicleProvider =
    NotifierProvider<VehicleGarageNotifier, VehicleGarage>(
        VehicleGarageNotifier.new);

/// Vehicle driving session estimates, or null when no vehicle is set.
final activeVehicleProvider = Provider(
  (ref) => ref.watch(vehicleProvider).active,
);
