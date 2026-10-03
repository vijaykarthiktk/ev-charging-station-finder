/// Domain errors. UIs must show [userMessage], never raw exceptions.
sealed class AppException implements Exception {
  const AppException(this.userMessage);
  final String userMessage;

  @override
  String toString() => userMessage;
}

/// Live availability could not be fetched.
class NetworkException extends AppException {
  const NetworkException([super.userMessage =
      'Could not reach the charging network. Check your connection and try again.']);
}

/// Local booking storage failed.
class StorageException extends AppException {
  const StorageException([super.userMessage =
      'Could not save your booking on this device. Please try again.']);
}

/// The requested time window is no longer free.
class SlotUnavailableException extends AppException {
  const SlotUnavailableException([super.userMessage =
      'That slot was just taken. Please choose another time.']);
}

/// A station is offline and cannot be booked.
class StationOfflineException extends AppException {
  const StationOfflineException([super.userMessage =
      'This station is currently offline and cannot be booked.']);
}

/// Booking form failed validation (message already user-facing).
class BookingValidationException extends AppException {
  const BookingValidationException(super.userMessage);
}

/// Anything unexpected the UI should surface generically.
class UnexpectedException extends AppException {
  const UnexpectedException([super.userMessage =
      'Something went wrong. Please try again.']);
}
