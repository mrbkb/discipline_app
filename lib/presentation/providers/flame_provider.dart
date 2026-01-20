// ============================================
// FICHIER NETTOYÉ : lib/presentation/providers/flame_provider.dart
// ✅ Tous les print() retirés
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'habits_provider.dart';
import '../../core/constants/app_strings.dart';

final flameLevelProvider = Provider<double>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  
  if (habits.isEmpty) return 1.0;
  
  final completedToday = habits.where((h) => h.isCompletedToday()).length;
  final totalHabits = habits.length;
  
  return completedToday / totalHabits;
});

final flamePercentageProvider = Provider<int>((ref) {
  final level = ref.watch(flameLevelProvider);
  return (level * 100).round();
});

final flameMessageProvider = Provider<String>((ref) {
  final level = ref.watch(flameLevelProvider);
  
  if (level >= 0.8) {
    return AppStrings.flameMessagesHigh[
      DateTime.now().millisecond % AppStrings.flameMessagesHigh.length
    ];
  } else if (level >= 0.4) {
    return AppStrings.flameMessagesMedium[
      DateTime.now().millisecond % AppStrings.flameMessagesMedium.length
    ];
  } else {
    return AppStrings.flameMessagesLow[
      DateTime.now().millisecond % AppStrings.flameMessagesLow.length
    ];
  }
});

final flameColorProvider = Provider<String>((ref) {
  final level = ref.watch(flameLevelProvider);
  
  if (level >= 0.8) {
    return '#FF6B35';
  } else if (level >= 0.6) {
    return '#FFA500';
  } else if (level >= 0.4) {
    return '#FFD700';
  } else if (level >= 0.2) {
    return '#FFD60A';
  } else {
    return '#FF3B30';
  }
});