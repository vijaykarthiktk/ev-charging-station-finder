import 'package:postgres/postgres.dart';

import '../core/errors/app_exception.dart';
import '../models/charger_type.dart';
import '../models/charging_slot.dart';
import '../models/charging_station.dart';
import '../models/connector_type.dart';
import 'station_repository.dart';

/// Stations + live availability from Postgres. Availability is derived
/// from confirmed bookings: a window stays bookable until overlapping
/// bookings fill every plug.
class PostgresStationRepository implements StationRepository {
  PostgresStationRepository(this._connection);
  final Future<Connection> _connection;

  Future<Result> _run(String sql,
      [Map<String, dynamic>? params]) async {
    try {
      final conn = await _connection;
      if (params == null) return await conn.execute(sql);
      return await conn.execute(Sql.named(sql), parameters: params);
    } catch (_) {
      throw const NetworkException();
    }
  }

  ChargingStation _stationRow(Map<String, dynamic> m) => ChargingStation(
        id: m['id'] as String,
        name: m['name'] as String,
        address: m['address'] as String,
        distanceKm: (m['distance_km'] as num).toDouble(),
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        pricePerKwh: (m['price_per_kwh'] as num).toDouble(),
        chargerTypes: [
          for (final l in (m['charger_types'] as List))
            ChargerTypeX.fromLabel(l as String),
        ],
        connectors: [
          for (final l in (m['connectors'] as List))
            ConnectorTypeX.fromLabel(l as String),
        ],
        powerKwByType: {
          for (final e in (m['power_kw'] as Map).entries)
            e.key as String: (e.value as num).toDouble(),
        },
        totalSlots: m['total_slots'] as int,
        operatingStartHour: m['operating_start_hour'] as int,
        operatingEndHour: m['operating_end_hour'] as int,
        amenities: [
          for (final a in (m['amenities'] as List)) a as String,
        ],
        isOffline: m['is_offline'] as bool,
      );

  Future<ChargingStation> _station(String stationId) async {
    final result = await _run(
      'SELECT * FROM stations WHERE id = @id',
      {'id': stationId},
    );
    if (result.isEmpty) {
      throw const UnexpectedException('Station not found.');
    }
    return _stationRow(result.first.toColumnMap());
  }

  @override
  Future<List<ChargingStation>> fetchStations() async {
    final result =
        await _run('SELECT * FROM stations ORDER BY distance_km');
    return result.map((row) => _stationRow(row.toColumnMap())).toList();
  }

  @override
  Future<AvailabilitySummary> fetchAvailability(String stationId) async {
    final station = await _station(stationId);
    if (station.isOffline) {
      return AvailabilitySummary(
          total: station.totalSlots, available: 0, isOffline: true);
    }
    final now = DateTime.now().toUtc();
    final result = await _run(
      "SELECT COUNT(*) AS busy FROM bookings "
      "WHERE station_id = @id AND status = 'confirmed' "
      "AND start_time < @until AND end_time > @now",
      {
        'id': stationId,
        'now': now,
        'until': now.add(const Duration(hours: 1)),
      },
    );
    final busy = result.first.toColumnMap()['busy'] as int;
    final available = (station.totalSlots - busy).clamp(0, station.totalSlots);
    return AvailabilitySummary(
      total: station.totalSlots,
      available: available,
      isOffline: false,
    );
  }

  @override
  Future<List<ChargingSlot>> fetchLiveAvailability(
    String stationId, {
    DateTime? date,
  }) async {
    final station = await _station(stationId);
    final d = date ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final dayEnd = day.add(const Duration(days: 1));

    final held = station.isOffline
        ? const <_Window>[]
        : await _confirmedWindows(stationId, day, dayEnd);

    final slots = <ChargingSlot>[];
    for (final type in station.chargerTypes) {
      for (var hour = station.operatingStartHour;
          hour < station.operatingEndHour;
          hour++) {
        final start = DateTime(day.year, day.month, day.day, hour);
        final end = start.add(const Duration(hours: 1));
        final overlapping = held
            .where((w) =>
                w.chargerType == type.label &&
                w.start.isBefore(end) &&
                start.isBefore(w.end))
            .length;
        slots.add(ChargingSlot(
          id: '${stationId}_${day.year}-${day.month}-${day.day}_${hour}_${type.label}',
          stationId: stationId,
          date: day,
          start: start,
          end: end,
          chargerType: type,
          available:
              !station.isOffline && overlapping < station.totalSlots,
        ));
      }
    }
    return slots;
  }

  Future<List<_Window>> _confirmedWindows(
      String stationId, DateTime day, DateTime dayEnd) async {
    final result = await _run(
      "SELECT start_time, end_time, charger_type FROM bookings "
      "WHERE station_id = @id AND status = 'confirmed' "
      "AND start_time < @dayEnd AND end_time > @dayStart",
      {'id': stationId, 'dayStart': day, 'dayEnd': dayEnd},
    );
    return [
      for (final row in result)
        _Window(
          start: (row.toColumnMap()['start_time'] as DateTime).toLocal(),
          end: (row.toColumnMap()['end_time'] as DateTime).toLocal(),
          chargerType: row.toColumnMap()['charger_type'] as String,
        ),
    ];
  }
}

class _Window {
  const _Window(
      {required this.start, required this.end, required this.chargerType});
  final DateTime start;
  final DateTime end;
  final String chargerType;
}
