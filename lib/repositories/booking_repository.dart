import '../models/booking.dart';

/// Storage contract — stations, availability, and bookings all live in
/// Postgres now; Hive keeps only device-local prefs (favorites, garage).
abstract class BookingRepository {
  Future<List<Booking>> fetchBookings();
  Future<Booking> saveBooking(Booking booking);

  /// Full-object replacement (used by reschedule).
  Future<Booking> updateBooking(Booking booking);
  Future<Booking> updateStatus(String id, BookingStatus status);
}
