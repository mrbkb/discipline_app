// ============================================
// FICHIER CORRIGÉ : lib/main.dart
// ✅ Tous les warnings fixés
// ============================================
import 'package:discipline/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'core/services/auto_sync_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/alarm_notification_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/daily_snapshot_service.dart';
import 'core/services/logger_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  // ✅ FIX: Utiliser _ pour les variables inutilisées
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggerService.error(
        'Flutter framework error',
        tag: 'APP',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    LoggerService.info('Starting Discipline app', tag: 'APP');
    
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      LoggerService.info('Firebase initialized', tag: 'APP');
    } catch (e) {
      // ✅ FIX: Pas besoin du stack trace ici
      LoggerService.error('Firebase initialization failed', tag: 'APP', error: e);
    }
    
    try {
      await StorageService.init();
      LoggerService.info('Storage initialized', tag: 'APP');
    } catch (e) {
      LoggerService.error('Storage initialization failed', tag: 'APP', error: e);
    }
    
    try {
      final notifInitialized = await AlarmNotificationService.initialize();
      
      if (notifInitialized) {
        LoggerService.info('AlarmNotificationService initialized', tag: 'APP');
      } else {
        LoggerService.warning('AlarmNotificationService init failed', tag: 'APP');
      }
    } catch (e) {
      LoggerService.error('AlarmNotificationService initialization failed', tag: 'APP', error: e);
    }
    
    try {
      await AnalyticsService.init();
      LoggerService.info('Analytics initialized', tag: 'APP');
    } catch (e) {
      LoggerService.error('Analytics initialization failed', tag: 'APP', error: e);
    }

    try {
      await AutoSyncService().initialize();
      LoggerService.info('Auto-sync service initialized', tag: 'APP');
    } catch (e) {
      LoggerService.error('Auto-sync initialization failed', tag: 'APP', error: e);
    }
    
    try {
      await DailySnapshotService.checkAndCreateDailySnapshot();
    } catch (e) {
      LoggerService.warning('Daily snapshot check failed', tag: 'APP', error: e);
    }
    
    runApp(
      const ProviderScope(
        child: DisciplineApp(),
      ),
    );
  }, (error, stack) {
    // ✅ FIX: On utilise bien 'stack' ici
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
      DailySnapshotService.checkAndCreateDailySnapshot().catchError((e) {
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