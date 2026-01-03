// ============================================
// FICHIER CORRIGÉ : lib/presentation/providers/flame_provider.dart
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'habits_provider.dart';
import '../../core/constants/app_strings.dart';

// ✅ FIX: Flame level provider calculé EN TEMPS RÉEL depuis les habits AUJOURD'HUI
final flameLevelProvider = Provider<double>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  
  if (habits.isEmpty) return 1.0;
  
  // ✅ Calculer combien d'habitudes sont complétées AUJOURD'HUI
  final completedToday = habits.where((h) => h.isCompletedToday()).length;
  final totalHabits = habits.length;
  
  // ✅ Niveau = pourcentage de complétion aujourd'hui
  final level = completedToday / totalHabits;
  
  print('🔥 [FlameProvider] Completed today: $completedToday/$totalHabits = ${(level * 100).toInt()}%');
  
  return level;
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