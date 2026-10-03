import 'package:postgres/postgres.dart';

import '../core/errors/app_exception.dart';
import '../models/booking.dart';
import '../models/charger_type.dart';
import 'booking_repository.dart';

/// Bookings in Postgres. Failures surface as [StorageException] with
/// user-safe messages — raw database errors never reach the UI.
class PostgresBookingRepository implements BookingRepository {
  PostgresBookingRepository(this._connection);
  final Future<Connection> _connection;

  Future<Result> _run(String sql,
      [Map<String, dynamic>? params]) async {
    try {
      final conn = await _connection;
      if (params == null) return await conn.execute(sql);
      return await conn.execute(Sql.named(sql), parameters: params);
    } catch (_) {
      throw const StorageException();
    }
  }

  Booking _row(Map<String, dynamic> m) => Booking(
        id: m['id'] as String,
        stationId: m['station_id'] as String,
        stationName: m['station_name'] as String,
        chargerType: ChargerTypeX.fromLabel(m['charger_type'] as String),
        date: m['date'] as DateTime,
        startTime: (m['start_time'] as DateTime).toLocal(),
        endTime: (m['end_time'] as DateTime).toLocal(),
        pricePerKwh: (m['price_per_kwh'] as num).toDouble(),
        estimatedPrice: (m['estimated_price'] as num).toDouble(),
        energyKwh: (m['energy_kwh'] as num).toDouble(),
        status: BookingStatusX.fromName(m['status'] as String),
        createdAt: (m['created_at'] as DateTime).toLocal(),
      );

  Map<String, dynamic> _params(Booking b) => {
        'id': b.id,
        'station_id': b.stationId,
        'station_name': b.stationName,
        'charger_type': b.chargerType.label,
        'date': DateTime(b.date.year, b.date.month, b.date.day),
        'start_time': b.startTime,
        'end_time': b.endTime,
        'price_per_kwh': b.pricePerKwh,
        'estimated_price': b.estimatedPrice,
        'energy_kwh': b.energyKwh,
        'status': b.status.name,
        'created_at': b.createdAt,
      };

  @override
  Future<List<Booking>> fetchBookings() async {
    final result =
        await _run('SELECT * FROM bookings ORDER BY created_at DESC');
    return result.map((row) => _row(row.toColumnMap())).toList();
  }

  @override
  Future<Booking> saveBooking(Booking booking) async {
    await _run(
      'INSERT INTO bookings (id, station_id, station_name, charger_type, '
      'date, start_time, end_time, price_per_kwh, estimated_price, '
      'energy_kwh, status, created_at) VALUES (@id, @station_id, '
      '@station_name, @charger_type, @date, @start_time, @end_time, '
      '@price_per_kwh, @estimated_price, @energy_kwh, @status, @created_at)',
      _params(booking),
    );
    return booking;
  }

  @override
  Future<Booking> updateBooking(Booking booking) async {
    final result = await _run(
      'UPDATE bookings SET station_id = @station_id, '
      'station_name = @station_name, charger_type = @charger_type, '
      'date = @date, start_time = @start_time, end_time = @end_time, '
      'price_per_kwh = @price_per_kwh, estimated_price = @estimated_price, '
      'energy_kwh = @energy_kwh, status = @status WHERE id = @id',
      _params(booking),
    );
    if (result.affectedRows == 0) {
      throw const StorageException('Booking not found.');
    }
    return booking;
  }

  @override
  Future<Booking> updateStatus(String id, BookingStatus status) async {
    final result = await _run(
      'UPDATE bookings SET status = @status WHERE id = @id',
      {'id': id, 'status': status.name},
    );
    if (result.affectedRows == 0) {
      throw const StorageException('Booking not found.');
    }
    final row = await _run(
      'SELECT * FROM bookings WHERE id = @id',
      {'id': id},
    );
    return _row(row.first.toColumnMap());
  }
}
