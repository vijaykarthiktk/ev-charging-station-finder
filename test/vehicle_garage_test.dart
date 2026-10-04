import 'package:chargefind/models/connector_type.dart';
import 'package:chargefind/models/vehicle_profile.dart';
import 'package:chargefind/providers/vehicle_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _nexon = VehicleProfile(
    id: 'v-1',
    name: 'Nexon EV',
    batteryKwh: 40,
    connector: ConnectorType.ccs2);
const _tiago = VehicleProfile(
    id: 'v-2',
    name: 'Tiago EV',
    batteryKwh: 24,
    connector: ConnectorType.type2);

void main() {
  test('active falls back to first vehicle when nothing selected', () {
    const garage = VehicleGarage(vehicles: [_nexon, _tiago]);
    expect(garage.active?.id, 'v-1');

    const selected =
        VehicleGarage(vehicles: [_nexon, _tiago], activeId: 'v-2');
    expect(selected.active?.id, 'v-2');

    const empty = VehicleGarage();
    expect(empty.active, isNull);
  });

  test('copyWith replaces vehicles and active id', () {
    const garage = VehicleGarage(vehicles: [_nexon], activeId: 'v-1');
    final updated = garage.copyWith(
      vehicles: [_nexon, _tiago],
      activeId: () => 'v-2',
    );
    expect(updated.vehicles.length, 2);
    expect(updated.active?.id, 'v-2');

    final kept = garage.copyWith(vehicles: [_tiago]);
    expect(kept.activeId, 'v-1');
  });
}
