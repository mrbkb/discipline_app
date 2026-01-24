// ============================================
// FICHIER SIMPLIFIÉ : lib/presentation/screens/settings/settings_screen.dart
// ✅ SANS boutons backup/restore manuels
// ✅ Sync 100% automatique en arrière-plan
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
//import '../../../core/services/auto_sync_service.dart';
import '../../providers/stats_provider.dart';
import '../../providers/user_provider.dart';
//import '../../providers/sync_provider.dart';
//import '../../widgets/alarm_notification_debug_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    //final isOnline = ref.watch(isOnlineProvider);
    final totalActiveDays = ref.watch(totalActiveDaysProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          const SliverAppBar(
            floating: true,
            backgroundColor: AppColors.midnightBlack,
            title: Text(AppStrings.settingsTitle),
            centerTitle: false,
          ),

          // User Profile Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lavaOrange.withValues(alpha: 0.2),
                    AppColors.cardBackground,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lavaOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.lavaOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lavaOrange,
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.lavaOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nickname
                  Text(
                    user.nickname,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.lavaOrange,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileStat(
                        icon: Icons.check_circle,
                        value: '${user.totalHabitsCreated}',
                        label: 'Habitudes',
                      ),
                      const SizedBox(width: 24),
                      _ProfileStat(
                        icon: Icons.calendar_today,
                        value: '$totalActiveDays',
                        label: 'Jours actifs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Edit nickname button
                  TextButton.icon(
                    onPressed: () => _showEditNicknameDialog(context, ref, user.nickname),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier le surnom'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lavaOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Preferences Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préférences',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Settings Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Hard Mode
                    _SettingsTile(
                      icon: Icons.whatshot,
                      iconColor: AppColors.dangerRed,
                      title: AppStrings.settingsHardMode,
                      subtitle: AppStrings.settingsHardModeDesc,
                      trailing: Switch(
                        value: user.isHardMode,
                        onChanged: (value) async {
                          await ref.read(userProvider.notifier).toggleHardMode();
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // Notifications
                    _SettingsTile(
                      icon: Icons.notifications,
                      iconColor: AppColors.lavaOrange,
                      title: AppStrings.settingsNotifications,
                      subtitle: user.notificationsEnabled ? 'Activées' : 'Désactivées',
                      trailing: Switch(
                        value: user.notificationsEnabled,
                        onChanged: (value) async {
                          await ref.read(userProvider.notifier).toggleNotifications();
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // Reminder Time
                    _SettingsTile(
                      icon: Icons.access_time,
                      iconColor: Colors.blue,
                      title: AppStrings.settingsReminderTime,
                      subtitle: user.reminderTime,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTimePickerDialog(
                        context,
                        ref,
                        user.reminderTime,
                        isLateReminder: false,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // Late Reminder
                    _SettingsTile(
                      icon: Icons.alarm,
                      iconColor: AppColors.warningYellow,
                      title: AppStrings.settingsLateReminder,
                      subtitle: user.lateReminderTime,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTimePickerDialog(
                        context,
                        ref,
                        user.lateReminderTime,
                        isLateReminder: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ✅ NOUVEAU: Auto-Sync Status (remplace la section Backup/Restore)
        /*  SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _AutoSyncStatusCard(
                isOnline: isOnline,
                user: user,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),*/

          // About Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),


// Dans le build(), après la section "À propos" :
const SliverToBoxAdapter(child: SizedBox(height: 24)),

// Widget de debug
/*const SliverToBoxAdapter(
  child: AlarmNotificationDebugWidget(),
),
*/
//const SliverToBoxAdapter(child: SizedBox(height: 100)),

          // About Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.info,
                      iconColor: Colors.blue,
                      title: 'Version',
                      subtitle: '1.0.0',
                      trailing: SizedBox.shrink(),
                    ),
                    Divider(height: 1, color: AppColors.divider),
                    _SettingsTile(
                      icon: Icons.code,
                      iconColor: AppColors.lavaOrange,
                      title: 'Développé par',
                      subtitle: 'Mr. BKB',
                      trailing: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, WidgetRef ref, String currentNickname) {
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier le surnom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nouveau surnom',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isNotEmpty) {
                await ref.read(userProvider.notifier).updateNickname(newNickname);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.lavaOrange),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }
  
  void _showTimePickerDialog(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
    {required bool isLateReminder}
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lavaOrange,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      if (isLateReminder) {
        await ref.read(userProvider.notifier).updateReminderTimes(lateReminder: timeString);
      } else {
        await ref.read(userProvider.notifier).updateReminderTimes(reminder: timeString);
      }
    }
  }
}

// ============================================
// WIDGETS INTERNES
// ============================================

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.lavaOrange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                  const SizedBox(height: 2),
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
            trailing,
          ],
        ),
      ),
    );
  }
}

// ✅ NOUVEAU: Widget de statut Auto-Sync
/*class _AutoSyncStatusCard extends StatelessWidget {
  final bool isOnline;
  final dynamic user;

  const _AutoSyncStatusCard({
    required this.isOnline,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final syncStatus = AutoSyncService().getSyncStatus();
    final isSyncing = syncStatus['isSyncing'] as bool;
    final lastSyncAt = syncStatus['lastSyncAt'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isOnline
                ? AppColors.successGreen.withValues(alpha: 0.15)
                : AppColors.textSecondary.withValues(alpha: 0.1),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.successGreen.withValues(alpha: 0.3)
              : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSyncing
                      ? Icons.sync
                      : isOnline
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                  color: isOnline ? AppColors.successGreen : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline
                          ? isSyncing
                              ? 'Synchronisation...'
                              : 'Sauvegarde automatique'
                          : 'Mode hors ligne',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? AppColors.successGreen : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline
                          ? 'Tes données sont synchronisées automatiquement'
                          : 'Sync automatique dès que tu seras en ligne',
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
          
          if (lastSyncAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dernière sync: ${_formatLastSync(lastSyncAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastSync(String lastSyncStr) {
    try {
      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      final diff = now.difference(lastSync);
      
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
      if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (e) {
      return 'Inconnue';
    }
  }
}*/