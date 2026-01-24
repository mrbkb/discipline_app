// ============================================
// FICHIER MIS À JOUR : lib/presentation/screens/onboarding/notification_permission_screen.dart
// ✅ PRODUCTION: Notification de test retirée
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/alarm_notification_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/logger_service.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() => 
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState 
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isLoading = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    AnalyticsService.logScreenView('notification_permission');
  }

  Future<void> _checkPermissions() async {
    final granted = await AlarmNotificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() => _permissionsGranted = granted);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Demander les permissions
      final granted = await AlarmNotificationService.requestPermissions();
      
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Permissions refusées'),
              backgroundColor: AppColors.dangerRed,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        setState(() => _isLoading = false);
        return;
      }
      
      // ✅ PRODUCTION: Pas de notification de test
      // La ligne suivante a été RETIRÉE :
      // await AlarmNotificationService.testNotification();
      
      // 2. Programmer les notifications quotidiennes depuis UserModel
      final user = ref.read(userProvider);
      
      if (user != null) {
        LoggerService.info('Scheduling from user settings', tag: 'NOTIF_PERMISSION', data: {
          'reminderHour': user.reminderHour,
          'reminderMinute': user.reminderMinute,
          'lateReminderHour': user.lateReminderHour,
          'lateReminderMinute': user.lateReminderMinute,
          'isHardMode': user.isHardMode,
        });
        
        final scheduled = await AlarmNotificationService.scheduleDailyFromUser(user);
        
        if (!scheduled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Erreur lors de la programmation'),
                backgroundColor: AppColors.warningYellow,
              ),
            );
          }
        } else {
          LoggerService.info('Notifications scheduled successfully', tag: 'NOTIF_PERMISSION');
        }
      }
      
      setState(() {
        _permissionsGranted = true;
        _isLoading = false;
      });
      
      // 3. Analytics
      await AnalyticsService.logEvent(
        name: 'notifications_enabled',
        parameters: {'source': 'onboarding'},
      );
      
      // 4. Attendre 2 secondes pour que l'utilisateur voie le succès
      await Future.delayed(const Duration(seconds: 2));
      
      // 5. Aller à l'écran principal
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
      
    } catch (e, stack) {
      LoggerService.error('Error requesting permissions', tag: 'NOTIF_PERMISSION', error: e, stackTrace: stack);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
      
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    await AnalyticsService.logEvent(
      name: 'notifications_skipped',
      parameters: {'source': 'onboarding'},
    );
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    return Scaffold(
      backgroundColor: AppColors.midnightBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom - 48,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
              
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.lavaOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.lavaOrange,
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Reste motivé',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Active les notifications pour recevoir des rappels quotidiens et ne jamais perdre ta flamme 🔥',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Benefits with user's actual settings
              if (user != null) ...[
                _BenefitItem(
                  icon: Icons.access_time,
                  title: 'Rappel principal',
                  subtitle: 'Un rappel doux à ${user.reminderTime}',
                ),
                
                const SizedBox(height: 16),
                
                _BenefitItem(
                  icon: Icons.alarm,
                  title: 'Rappel tardif',
                  subtitle: 'Un rappel plus ferme à ${user.lateReminderTime}',
                ),
              ] else ...[
                const _BenefitItem(
                  icon: Icons.access_time,
                  title: 'Rappel principal',
                  subtitle: 'Un rappel doux à 18:00',
                ),
                
                const SizedBox(height: 16),
                
                const _BenefitItem(
                  icon: Icons.alarm,
                  title: 'Rappel tardif',
                  subtitle: 'Un rappel plus ferme à 21:00',
                ),
              ],
              
              const SizedBox(height: 16),
              
              const _BenefitItem(
                icon: Icons.emoji_events,
                title: 'Célébrations',
                subtitle: 'Des notifications pour célébrer tes victoires',
              ),
              
              const SizedBox(height: 32),
              
              // Status indicator
              if (_permissionsGranted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Notifications activées !',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Enable button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _permissionsGranted 
                      ? null 
                      : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavaOrange,
                    disabledBackgroundColor: AppColors.successGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _permissionsGranted 
                                  ? 'Continuer'
                                  : 'Activer les notifications',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 24),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skip button
              if (!_permissionsGranted)
                TextButton(
                  onPressed: _isLoading ? null : _skip,
                  child: const Text(
                    'Passer pour le moment',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavaOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.lavaOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}