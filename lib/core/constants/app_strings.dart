// ============================================
// FICHIER MIS À JOUR : lib/core/constants/app_strings.dart
// ✅ Plusieurs options de slogans disponibles
// ============================================
class AppStrings {
  // App
  static const String appName = 'Discipline';
  
  // ============================================
  // ONBOARDING - SLOGANS DISPONIBLES
  // ============================================
  
  // Onboarding Title
  static const String onboardingTitle = 'DISCIPLINE';
  
  // ✅ OPTION 1 : Psychologie comportementale (RECOMMANDÉ)
  //static const String onboardingSubtitle = 'La psychologie de la perte';
  
  // ✅ OPTION 2 : Approche directe/brutale
   static const String onboardingSubtitle = 'Pas de pitié pour tes excuses';
  
  // ✅ OPTION 3 : Résultats/Transformation
  // static const String onboardingSubtitle = 'Automatise ta réussite';
  
  // ✅ OPTION 4 : Stratégique
  // static const String onboardingSubtitle = 'La stratégie anti-abandon';
  
  // ✅ OPTION 5 : Challenge
  // static const String onboardingSubtitle = 'Ton adversaire, c\'est hier';
  
  // ✅ OPTION 6 : Promesse
  // static const String onboardingSubtitle = 'Des habitudes qui tiennent';
  
  // ✅ OPTION 7 : Métaphore du feu
  // static const String onboardingSubtitle = 'La méthode du feu qui dure';
  
  // ✅ OPTION 8 : Valeur morale
  // static const String onboardingSubtitle = 'L\'art de tenir sa parole';
  
  static const String onboardingButton = 'Commencer';
  
  // ============================================
  // ONBOARDING - TAGLINE OPTIONNEL
  // ============================================
  
  // Badge ou tagline à afficher sous le slogan principal
  static const String onboardingTagline = 'Transforme tes résolutions en automatismes';
  
  // Alternatives :
  // static const String onboardingTagline = 'Sans compromis, sans excuses';
  // static const String onboardingTagline = 'Méthode scientifique prouvée';
  // static const String onboardingTagline = 'Le feu qui ne s\'éteint jamais';
  
  // ============================================
  // RESTE DU CODE INCHANGÉ
  // ============================================
  
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
  static const String statsPerformance = 'Les 7 Derniers Jours';
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
    'C\'est quoi ça ?',
    'On se réveille ou bien ?',
  ];
}