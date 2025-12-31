
// ============================================
// FICHIER 8/30 : lib/core/utils/streak_calculator.dart
// ============================================
import 'package:discipline/core/utils/date_helper.dart';

class StreakCalculator {
  static int calculateCurrentStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    
    // Sort dates in descending order
    final sortedDates = List<String>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    final today = DateHelper.getTodayString();
    final yesterday = DateHelper.getYesterdayString();
    
    // If not completed today or yesterday, streak is broken
    if (sortedDates.first != today && sortedDates.first != yesterday) {
      return 0;
    }
    
    int streak = 0;
    DateTime currentDate = sortedDates.first == today 
        ? DateTime.now() 
        : DateTime.now().subtract(const Duration(days: 1));
    
    for (final dateString in sortedDates) {
      final expectedDate = DateHelper.formatDate(currentDate);
      
      if (dateString == expectedDate) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  static int findBestStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<String>.from(completedDates)..sort();
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = DateTime.parse(sortedDates[i - 1]);
      final currDate = DateTime.parse(sortedDates[i]);
      
      final daysDiff = currDate.difference(prevDate).inDays;
      
      if (daysDiff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }
  
  static bool shouldResetStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return false;
    
    final sortedDates = List<String>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    
    final yesterday = DateHelper.getYesterdayString();
    
    // If last completion was not yesterday, streak should be reset
    return sortedDates.first != yesterday;
  }
}