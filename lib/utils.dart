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
}
