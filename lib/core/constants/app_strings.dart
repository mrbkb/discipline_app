

// ============================================
// FICHIER 3/30 : lib/core/constants/app_strings.dart
// ============================================
class AppStrings {
  // App
  static const String appName = 'Discipline';
  
  // Onboarding
  static const String onboardingTitle = 'DISCIPLINE';
  static const String onboardingSubtitle = 'Transforme tes résolutions\nen automatismes';
  static const String onboardingButton = 'Commencer';
  
  static const String nicknameTitle = 'Comment on t\'appelle ?';
  static const String nicknameHint = 'Champion';
  static const String nicknameNext = 'Suivant';
  
  static const String habitsTitle = 'Choisis 3 batailles';
  static const String habitsSubtitle = 'à gagner cette semaine';
  static const String habitsStart = 'C\'est parti ! 🔥';
  static const String habitsAdd = '+ Ajouter';
  
  // Home
  static const String homeValidateButton = 'VALIDER LA JOURNÉE';
  static const String homeValidatedButton = 'JOURNÉE VALIDÉE ✓';
  static const String homeStreak = 'Streak:';
  static const String homeDays = 'jours';
  
  // Stats
  static const String statsTitle = 'Statistiques';
  static const String statsPerformance = 'Performance 7 Derniers Jours';
  static const String statsRecords = 'Records Personnels';
  static const String statsSuccessRate = 'Taux de réussite:';
  static const String statsBestFlame = 'Meilleure Flamme:';
  static const String statsTotalDays = 'Total Jours Actifs:';
  
  // Settings
  static const String settingsTitle = 'Paramètres';
  static const String settingsNickname = 'Surnom';
  static const String settingsHardMode = 'Mode Hard';
  static const String settingsHardModeDesc = 'Notifications "violentes"';
  static const String settingsNotifications = 'Notifications';
  static const String settingsReminderTime = 'Rappel principal';
  static const String settingsLateReminder = 'Rappel tardif';
  static const String settingsBackup = 'Sauvegarder mes données';
  static const String settingsRestore = 'Restaurer';
  
  // Flame Messages
  static const List<String> flameMessagesHigh = [
    'Le feu brûle fort aujourd\'hui 🔥',
    'Tu es inarrêtable !',
    'Continue comme ça, champion !',
  ];
  
  static const List<String> flameMessagesMedium = [
    'Bon début, mais on peut mieux',
    'Le feu faiblit un peu...',
    'Allez, on se ressaisit !',
  ];
  
  static const List<String> flameMessagesLow = [
    'Le feu est presque éteint 😰',
    'Ekié, c\'est quoi ça ?',
    'On se réveille ou bien ?',
  ];
}
