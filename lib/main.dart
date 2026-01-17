// ============================================
// FICHIER PRODUCTION : lib/main.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:discipline/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'core/services/auto_sync_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/daily_snapshot_service.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  // Capturer toutes les erreurs
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Capturer les erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggerService.error(
        'Flutter framework error',
        tag: 'APP',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    
    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    LoggerService.info('Starting Discipline app', tag: 'APP');
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      LoggerService.info('Firebase initialized', tag: 'APP');
    } catch (e, stack) {
      LoggerService.error('Firebase initialization failed', tag: 'APP', error: e, stackTrace: stack);
    }
    
    // Initialize Hive
    try {
      await StorageService.init();
      LoggerService.info('Storage initialized', tag: 'APP');
    } catch (e, stack) {
      LoggerService.error('Storage initialization failed', tag: 'APP', error: e, stackTrace: stack);
    }
    
    // Initialize Notifications
    try {
      await NotificationService.init();
      LoggerService.info('Notifications initialized', tag: 'APP');
    } catch (e, stack) {
      LoggerService.error('Notifications initialization failed', tag: 'APP', error: e, stackTrace: stack);
    }
    
    // Initialize Analytics
    try {
      await AnalyticsService.init();
      LoggerService.info('Analytics initialized', tag: 'APP');
    } catch (e, stack) {
      LoggerService.error('Analytics initialization failed', tag: 'APP', error: e, stackTrace: stack);
    }

    // Initialize Auto-Sync Service
try {
  await AutoSyncService().initialize();
  LoggerService.info('Auto-sync service initialized', tag: 'APP');
} catch (e, stack) {
  LoggerService.error('Auto-sync initialization failed', tag: 'APP', error: e, stackTrace: stack);
}
    
    // Create daily snapshot if needed
    try {
      await DailySnapshotService.checkAndCreateDailySnapshot();
    } catch (e, stack) {
      LoggerService.warning('Daily snapshot check failed', tag: 'APP', error: e);
    }
    
    runApp(
      const ProviderScope(
        child: DisciplineApp(),
      ),
    );
  }, (error, stack) {
    // Capturer les erreurs Dart non gérées
    LoggerService.critical(
      'Uncaught error in app',
      tag: 'APP',
      error: error,
      stackTrace: stack,
    );
  });
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
    WidgetsBinding.instance.addObserver(this);
    LoggerService.debug('App lifecycle observer added', tag: 'APP');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LoggerService.debug('App lifecycle observer removed', tag: 'APP');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    LoggerService.debug('App lifecycle changed: ${state.name}', tag: 'APP');
    
    if (state == AppLifecycleState.resumed) {
      // Check and create snapshot when app comes to foreground
      DailySnapshotService.checkAndCreateDailySnapshot().catchError((e, stack) {
        LoggerService.warning('Snapshot check failed on resume', tag: 'APP', error: e);
      });
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