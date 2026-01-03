// ============================================
// FICHIER FINAL : lib/main.dart
// ============================================
import 'package:discipline/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/daily_snapshot_service.dart'; // ✅ NOUVEAU
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Hive
  await StorageService.init();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Initialize Analytics
  await AnalyticsService.init();
  
  // ✅ NOUVEAU: Créer le snapshot quotidien si nécessaire
  await DailySnapshotService.checkAndCreateDailySnapshot();
  
  runApp(
    const ProviderScope(
      child: DisciplineApp(),
    ),
  );
}

class DisciplineApp extends ConsumerStatefulWidget {
  const DisciplineApp({super.key});

  @override
  ConsumerState<DisciplineApp> createState() => _DisciplineAppState();
}

class _DisciplineAppState extends ConsumerState<DisciplineApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // ✅ Observer les changements de cycle de vie de l'app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ Quand l'app revient au premier plan, vérifier et créer snapshot
    if (state == AppLifecycleState.resumed) {
      DailySnapshotService.checkAndCreateDailySnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}