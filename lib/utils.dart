import 'package:timezone/timezone.dart' as tz;

class Utils {
  static int difference = getTimezoneDifference();
  static DateTime? getNextBirthday(DateTime? birthdate, DateTime today) {
    if (birthdate == null) return null;

    DateTime nextBirthday =
        DateTime(today.year, birthdate.month, birthdate.day);

    if ((nextBirthday.month < today.month) ||
        (nextBirthday.month == today.month && nextBirthday.day < today.day)) {
      return DateTime(today.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday;
  }

  static int getDaysToNextBirthdate(DateTime? birthdate) {
    DateTime today = DateTime.now();
    DateTime? next = getNextBirthday(birthdate, today);
    if (next == null) {
      return -1;
    }
    if (next.month == today.month && next.day == today.day) {
      return 0;
    }
    int days = next.difference(DateTime.now()).inDays;
    return days + 1;
  }

  static int getTimezoneDifference() {
    final DateTime now = DateTime.now();
    final tz.TZDateTime tznow = tz.TZDateTime.now(tz.local);
    return tznow.hour - now.hour;
  }

  static tz.TZDateTime nextInstanceOfNHour(int hour, {int minutes = 0}) {
    DateTime now = DateTime.now();
    DateTime scheduledDate =
        DateTime(now.year, now.month, now.day, hour, minutes);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return tz.TZDateTime(tz.local, scheduledDate.year, scheduledDate.month,
            scheduledDate.day, hour, minutes)
        .add(Duration(hours: difference));
  }

  static bool isLessThanFourHoursAway(int hour) {
    final DateTime now = DateTime.now();
    final DateTime scheduledDateTime =
        DateTime(now.year, now.month, now.day, hour);

    final Duration durationDiff = scheduledDateTime.difference(now);

    return durationDiff <= const Duration(hours: 4) && !durationDiff.isNegative;
  }
}
