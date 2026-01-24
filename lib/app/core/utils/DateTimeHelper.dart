import 'package:intl/intl.dart';

class DateTimeHelper {
  // Parse ISO String to DateTime
  static DateTime parse(String isoString) {
    return DateTime.parse(isoString).toLocal(); // local timezone
  }

  // Format to 'yyyy-MM-dd'
  static String formatDate(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  // Format to 'yyyy-MM-dd'
  static String formatDateMonth(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  // Format to 'hh:mm a'
  static String formatTime(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('hh:mm a').format(dateTime); // 05:48 AM
  }

  // Format to 'dd MMM, yyyy hh:mm a'
  static String formatDateTime(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('dd MMM, yyyy hh:mm a').format(dateTime); // 18 Sep, 2025 05:48 AM
  }

  // Formate to 'MMMM yy'
  static String formatMonthYear(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('MMMM yy').format(dateTime); // Sep 25
  }

  // Formate to 'MMMM yy'
  static String formatFull(String isoString) {
    final dateTime = parse(isoString);
    return DateFormat('dd MMM, yyyy hh:mm:ss a').format(dateTime); // Sep 25
  }
}
