// ============================================
// FICHIER CORRIGÉ : lib/presentation/widgets/notification_test_widget.dart
// ============================================
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  String _status = 'Idle';
  List<String> _pendingNotifs = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  /// ✅ FIX: Toujours vérifier mounted avant setState()
  Future<void> _checkStatus() async {
    if (!mounted) return; // ✅ Check avant de commencer
    
    setState(() => _status = 'Checking...');
    
    try {
      final enabled = await NotificationService.areNotificationsEnabled();
      final pending = await NotificationService.getPendingNotifications();
      
      // ✅ FIX CRITIQUE: Vérifier mounted APRÈS les appels async
      if (!mounted) return;
      
      setState(() {
        _status = enabled ? '✅ Enabled' : '❌ Disabled';
        _pendingNotifs = pending.map((n) => 
          '#${n.id}: ${n.title}'
        ).toList();
      });
      
    } catch (e) {
      if (!mounted) return; // ✅ Check avant setState()
      setState(() => _status = '❌ Error: $e');
    }
  }

  Future<void> _testImmediate() async {
    if (!mounted) return;
    
    try {
      await NotificationService.showStreakMilestone('Test', 7);
      
      if (!mounted) return; // ✅ Check avant d'utiliser context
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification immédiate envoyée'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Test immediate failed: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _testScheduled() async {
    if (!mounted) return;
    
    try {
      final now = DateTime.now();
      
      await NotificationService.scheduleDaily(
        hour: now.hour,
        minute: now.minute,
        isHardMode: false,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notifications programmées'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Refresh status
      await _checkStatus();
      
    } catch (e) {
      print('❌ Test scheduled failed: $e');
      
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
      
      // Refresh status
      await _checkStatus();
      
    } catch (e) {
      print('❌ Cancel all failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lavaOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Éviter débordement
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
          
          // Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deadGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
          ],
          
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
                onPressed: _testScheduled,
                icon: Icons.schedule,
                label: 'Programmer',
                color: AppColors.lavaOrange,
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

// ============================================
// Widget helper pour les boutons de test
// ============================================
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

// ============================================
// COMMENT L'UTILISER DANS settings_screen.dart
// ============================================
/*

1. Importer le widget :
   import '../../widgets/notification_test_widget.dart';

2. Ajouter dans le CustomScrollView, AVANT "About Section" :

   // DEBUG: Notification testing
   const SliverToBoxAdapter(
     child: NotificationTestWidget(),
   ),

3. Pour RETIRER le widget plus tard (production) :
   - Simplement commenter ou supprimer le SliverToBoxAdapter
   - Ou entourer d'une condition : if (kDebugMode) ...

*/