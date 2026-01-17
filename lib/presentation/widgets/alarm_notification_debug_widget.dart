// ============================================
// NOUVEAU FICHIER : lib/presentation/widgets/alarm_notification_debug_widget.dart
// ✅ Widget de debug pour AlarmNotificationService
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/alarm_notification_service.dart';
import '../providers/user_provider.dart';

class AlarmNotificationDebugWidget extends ConsumerStatefulWidget {
  const AlarmNotificationDebugWidget({super.key});

  @override
  ConsumerState<AlarmNotificationDebugWidget> createState() => 
      _AlarmNotificationDebugWidgetState();
}

class _AlarmNotificationDebugWidgetState 
    extends ConsumerState<AlarmNotificationDebugWidget> {
  String _status = 'Idle';
  bool _permissionsGranted = false;
  bool _isInitialized = false;
  String? _lastScheduleResult;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    setState(() => _status = 'Checking...');
    
    try {
      final permissions = await AlarmNotificationService.areNotificationsEnabled();
      final active = await AlarmNotificationService.areAlarmsActive();
      
      if (!mounted) return;
      
      setState(() {
        _permissionsGranted = permissions;
        _isInitialized = active;
        _status = permissions ? '✅ Permissions OK' : '❌ Pas de permissions';
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '❌ Error: $e');
    }
  }

  Future<void> _testImmediate() async {
    if (!mounted) return;
    
    try {
      final success = await AlarmNotificationService.testNotification();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '✅ Notification immédiate envoyée' 
              : '❌ Échec de la notification'),
          backgroundColor: success ? AppColors.successGreen : AppColors.dangerRed,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _test1Minute() async {
    if (!mounted) return;
    
    try {
      await AlarmNotificationService.testIn1Minute();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Alarme programmée dans 1 minute !'),
          backgroundColor: AppColors.lavaOrange,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _testWithUserSettings() async {
    if (!mounted) return;
    
    final user = ref.read(userProvider);
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucun utilisateur trouvé'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    
    setState(() => _lastScheduleResult = 'En cours...');
    
    try {
      print('');
      print('🧪 [DEBUG] Testing with user settings:');
      print('   Main reminder: ${user.reminderTime}');
      print('   Late reminder: ${user.lateReminderTime}');
      print('   Hard mode: ${user.isHardMode}');
      print('   Notifications enabled: ${user.notificationsEnabled}');
      
      final scheduled = await AlarmNotificationService.scheduleDailyFromUser(user);
      
      if (!mounted) return;
      
      setState(() {
        _lastScheduleResult = scheduled 
            ? '✅ SUCCESS' 
            : '❌ FAILED';
      });
      
      if (scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Alarmes programmées:\n'
              'Principal: ${user.reminderTime}\n'
              'Tardif: ${user.lateReminderTime}\n'
              'Hard mode: ${user.isHardMode ? "ON" : "OFF"}'
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Échec de la programmation'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
      
      await _checkStatus();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _lastScheduleResult = '❌ ERROR: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _cancelAll() async {
    if (!mounted) return;
    
    try {
      await AlarmNotificationService.cancelAll();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Toutes les alarmes annulées'),
          backgroundColor: AppColors.warningYellow,
          duration: Duration(seconds: 2),
        ),
      );
      
      setState(() => _lastScheduleResult = null);
      await _checkStatus();
      
    } catch (e) {
      print('❌ Cancel all failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (!mounted) return;
    
    try {
      final granted = await AlarmNotificationService.requestPermissions();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted 
              ? '✅ Permissions accordées' 
              : '❌ Permissions refusées'),
          backgroundColor: granted ? AppColors.successGreen : AppColors.dangerRed,
        ),
      );
      
      await _checkStatus();
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lavaOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.bug_report,
                color: AppColors.lavaOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Debug Alarm Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _checkStatus,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User settings info
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavaOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.lavaOrange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Réglages utilisateur:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lavaOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Rappel principal: ${user.reminderTime}\n'
                    '• Rappel tardif: ${user.lateReminderTime}\n'
                    '• Hard mode: ${user.isHardMode ? "ON 💀" : "OFF"}\n'
                    '• Notifications: ${user.notificationsEnabled ? "ON 🔔" : "OFF 🔕"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deadGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _permissionsGranted 
                              ? AppColors.successGreen 
                              : AppColors.dangerRed,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Heure actuelle: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_lastScheduleResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dernier résultat: $_lastScheduleResult',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _lastScheduleResult!.contains('SUCCESS')
                          ? AppColors.successGreen
                          : AppColors.dangerRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info importante
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ Important:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Les alarmes AndroidAlarmManager ne peuvent pas être listées\n'
                  '• Vérifie les logs pour confirmer la programmation\n'
                  '• Utilise "Test 1min" pour vérifier que ça marche',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          const Text(
            'Actions de test:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!_permissionsGranted)
                _TestButton(
                  onPressed: _requestPermissions,
                  icon: Icons.lock_open,
                  label: 'Permissions',
                  color: AppColors.warningYellow,
                ),
              
              _TestButton(
                onPressed: _testImmediate,
                icon: Icons.notification_add,
                label: 'Test Immédiat',
                color: AppColors.successGreen,
              ),
              
              _TestButton(
                onPressed: _test1Minute,
                icon: Icons.timer,
                label: 'Test 1min',
                color: AppColors.lavaOrange,
              ),
              
              _TestButton(
                onPressed: _testWithUserSettings,
                icon: Icons.settings,
                label: 'Test Réglages',
                color: Colors.blue,
              ),
              
              _TestButton(
                onPressed: _cancelAll,
                icon: Icons.cancel,
                label: 'Annuler',
                color: AppColors.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _TestButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        minimumSize: const Size(0, 36),
      ),
    );
  }
}