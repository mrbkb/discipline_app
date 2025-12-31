
// ============================================
// FICHIER 22/30 : lib/presentation/providers/flame_provider.dart
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'habits_provider.dart';
import '../../core/constants/app_strings.dart';

// Flame level provider (0.0 - 1.0)
final flameLevelProvider = Provider<double>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  
  if (habits.isEmpty) return 1.0;
  
  // Calculate average health score
  double totalHealth = 0;
  for (final habit in habits) {
    totalHealth += habit.healthScore;
  }
  
  return totalHealth / habits.length;
});

// Flame percentage provider (0 - 100)
final flamePercentageProvider = Provider<int>((ref) {
  final level = ref.watch(flameLevelProvider);
  return (level * 100).round();
});

// Flame message provider
final flameMessageProvider = Provider<String>((ref) {
  final level = ref.watch(flameLevelProvider);
  
  if (level >= 0.8) {
    // High flame (80-100%)
    return AppStrings.flameMessagesHigh[
      DateTime.now().millisecond % AppStrings.flameMessagesHigh.length
    ];
  } else if (level >= 0.4) {
    // Medium flame (40-79%)
    return AppStrings.flameMessagesMedium[
      DateTime.now().millisecond % AppStrings.flameMessagesMedium.length
    ];
  } else {
    // Low flame (0-39%)
    return AppStrings.flameMessagesLow[
      DateTime.now().millisecond % AppStrings.flameMessagesLow.length
    ];
  }
});

// Flame color provider
final flameColorProvider = Provider<String>((ref) {
  final level = ref.watch(flameLevelProvider);
  
  if (level >= 0.8) {
    return '#FF6B35'; // Lava Orange
  } else if (level >= 0.6) {
    return '#FFA500'; // Orange
  } else if (level >= 0.4) {
    return '#FFD700'; // Gold
  } else if (level >= 0.2) {
    return '#FFD60A'; // Yellow
  } else {
    return '#FF3B30'; // Red (danger)
  }
});
