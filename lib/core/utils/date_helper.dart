


// ============================================
// FICHIER 7/30 : lib/core/utils/date_helper.dart
// ============================================
class DateHelper {
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  static String getTodayString() {
    return formatDate(DateTime.now());
  }
  
  static String getYesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return formatDate(yesterday);
  }
  
  static DateTime getNextMidnight() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 0, 0, 1);
  }
  
  static String getDayLabel(String dateString) {
    final date = DateTime.parse(dateString);
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[date.weekday - 1];
  }
  
  static int getDaysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }
  
  static bool isToday(String dateString) {
    return dateString == getTodayString();
  }
  
  static bool isYesterday(String dateString) {
    return dateString == getYesterdayString();
  }
  
  static List<String> getLast7Days() {
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      days.add(formatDate(date));
    }
    return days;
  }
}