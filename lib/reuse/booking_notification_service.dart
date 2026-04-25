import 'package:cabsudapp/reuse/notification_service.dart';

/// Manages the 5 timed reminders that accompany each reservation.
///
/// Notification IDs are derived deterministically from [bookingId]
/// so they can be cancelled or rescheduled without storing extra state.
class BookingNotificationService {
  BookingNotificationService._();
  static final BookingNotificationService instance =
      BookingNotificationService._();

  static const int _slotsPerBooking = 5;

  static const List<Duration> _offsets = [
    Duration(days: 1),
    Duration(hours: 5),
    Duration(hours: 1),
    Duration(minutes: 10),
    Duration.zero,
  ];

  static const List<String> _bodies = [
    'Your chauffeur reservation is scheduled for tomorrow.',
    'Your chauffeur reservation is in 5 hours.',
    'Your chauffeur reservation is in 1 hour.',
    'Your chauffeur will arrive in 10 minutes.',
    'Your chauffeur reservation is now.',
  ];

  static const String _title = 'CABSUD — Chauffeur Reminder';

  /// Derive 5 stable, positive 32-bit notification IDs from [bookingId].
  List<int> _idsFor(String bookingId) {
    final base = bookingId.hashCode & 0x1FFFFFFF; // 29-bit positive int
    return List.generate(_slotsPerBooking, (i) => base + i);
  }

  /// Schedule all 5 reminders for [reservationTime].
  /// Reminders whose trigger time is already in the past are silently skipped.
  Future<void> scheduleBookingReminders(
    String bookingId,
    DateTime reservationTime,
  ) async {
    final ids = _idsFor(bookingId);
    for (var i = 0; i < _slotsPerBooking; i++) {
      final triggerTime = reservationTime.subtract(_offsets[i]);
      await NotificationService.instance.scheduleNotification(
        id: ids[i],
        title: _title,
        body: _bodies[i],
        scheduledDate: triggerTime,
      );
    }
  }

  /// Cancel all 5 reminders for [bookingId] (use on booking cancellation).
  Future<void> cancelBookingReminders(String bookingId) async {
    for (final id in _idsFor(bookingId)) {
      await NotificationService.instance.cancelNotification(id);
    }
  }

  /// Cancel existing reminders then schedule new ones (use on booking update).
  Future<void> rescheduleBookingReminders(
    String bookingId,
    DateTime newReservationTime,
  ) async {
    await cancelBookingReminders(bookingId);
    await scheduleBookingReminders(bookingId, newReservationTime);
  }
}
