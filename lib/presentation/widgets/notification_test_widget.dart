// ============================================
// FICHIER FINAL : lib/presentation/widgets/notification_test_widget.dart
// AVEC: Affichage des heures configurées
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../providers/user_provider.dart';

class NotificationTestWidget extends ConsumerStatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  ConsumerState<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends ConsumerState<NotificationTestWidget> {
  String _status = 'Idle';
  List<String> _pendingNotifs = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    
    setState(() => _status = 'Checking...');
    
    try {
      final enabled = await NotificationService.areNotificationsEnabled();
      final pending = await NotificationService.getPendingNotifications();
      
      if (!mounted) return;
      
      setState(() {
        _status = enabled ? '✅ Enabled' : '❌ Disabled';
        _pendingNotifs = pending.map((n) => 
          '#${n.id}: ${n.title}'
        ).toList();
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '❌ Error: $e');
    }
  }

  Future<void> _testImmediate() async {
    if (!mounted) return;
    
    try {
      await NotificationService.testNotification();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification immédiate envoyée'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
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
      await NotificationService.testScheduledIn1Minute();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Notification programmée dans 1 minute !'),
          backgroundColor: AppColors.lavaOrange,
          duration: Duration(seconds: 3),
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

  /// ✅ NOUVEAU: Tester avec les heures RÉELLES du UserModel
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
    
    try {
      print('');
      print('🧪 Testing with user settings:');
      print('   Reminder: ${user.reminderTime}');
      print('   Hard mode: ${user.isHardMode}');
      print('   Notifications enabled: ${user.notificationsEnabled}');
      
      final scheduled = await NotificationService.scheduleDaily(
        hour: user.reminderHour,
        minute: user.reminderMinute,
        isHardMode: user.isHardMode,
      );
      
      if (!mounted) return;
      
      if (scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Notifications programmées avec tes réglages:\n'
              'Rappel: ${user.reminderTime}\n'
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
      await NotificationService.cancelAll();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Toutes les notifications annulées'),
          backgroundColor: AppColors.warningYellow,
          duration: Duration(seconds: 2),
        ),
      );
      
      await _checkStatus();
      
    } catch (e) {
      print('❌ Cancel all failed: $e');
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
                  'Debug Notifications',
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
          
          // ✅ NOUVEAU: User settings info
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
                    '⚙️ Tes réglages actuels:',
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lavaOrange,
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
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pending notifications
          if (_pendingNotifs.isNotEmpty) ...[
            const Text(
              'Notifications programmées:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deadGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _pendingNotifs.map((n) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        n,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.warningYellow,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucune notification programmée',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warningYellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Instructions
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
                  '💡 Comment tester:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. "Test Immédiat" → Notification instantanée\n'
                  '2. "Test 1min" → Notification dans 1 minute\n'
                  '3. "Test Réglages" → Utilise TES heures configurées',
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
          
          // Test buttons
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
              
              // ✅ NOUVEAU: Bouton pour tester avec réglages user
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