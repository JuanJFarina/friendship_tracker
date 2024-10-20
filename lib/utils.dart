import 'package:timezone/timezone.dart' as tz;

class Utils {
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

  static tz.TZDateTime nextInstanceOfNHour(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, hour);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static bool isLessThanFourHoursAway(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = nextInstanceOfNHour(hour);

    final Duration difference = scheduledDate.difference(now);

    return difference <= const Duration(hours: 4) && !difference.isNegative;
  }
}
