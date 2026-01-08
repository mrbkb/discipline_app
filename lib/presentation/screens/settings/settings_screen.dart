// ============================================
// FICHIER FINAL CORRIGÉ : lib/presentation/screens/settings/settings_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/analytics_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/sync_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ FIX CRITIQUE: Watch user DIRECTEMENT dans le build
    // Pas de variable locale qui ne se rafraîchit pas !
    final user = ref.watch(userProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final isOnline = ref.watch(isOnlineProvider);

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

                  // ✅ Nickname - Se met à jour automatiquement
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
      value: '${user.totalHabitsCreated}', // ✅ Nombre total d'habitudes créées
      label: 'Habitudes',
    ),
    const SizedBox(width: 24),
    _ProfileStat(
      icon: Icons.calendar_today,
      value: '${user.totalDaysActive}', // ✅ Nombre de jours actifs
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
                    // ✅ Hard Mode - Valeur directement depuis user
                    _SettingsTile(
                      icon: Icons.whatshot,
                      iconColor: AppColors.dangerRed,
                      title: AppStrings.settingsHardMode,
                      subtitle: AppStrings.settingsHardModeDesc,
                      trailing: Switch(
                        value: user.isHardMode, // ✅ Directement depuis user
                        onChanged: (value) async {
                          await ref.read(userProvider.notifier).toggleHardMode();
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // ✅ Notifications - Valeur directement depuis user
                    _SettingsTile(
                      icon: Icons.notifications,
                      iconColor: AppColors.lavaOrange,
                      title: AppStrings.settingsNotifications,
                      subtitle: user.notificationsEnabled ? 'Activées' : 'Désactivées', // ✅ Directement depuis user
                      trailing: Switch(
                        value: user.notificationsEnabled, // ✅ Directement depuis user
                        onChanged: (value) async {
                          await ref.read(userProvider.notifier).toggleNotifications();
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // ✅ Reminder Time - Valeur directement depuis user
                    _SettingsTile(
                      icon: Icons.access_time,
                      iconColor: Colors.blue,
                      title: AppStrings.settingsReminderTime,
                      subtitle: user.reminderTime, // ✅ Directement depuis user
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTimePickerDialog(
                        context,
                        ref,
                        user.reminderTime,
                        isLateReminder: false,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // ✅ Late Reminder - Valeur directement depuis user
                    _SettingsTile(
                      icon: Icons.alarm,
                      iconColor: AppColors.warningYellow,
                      title: AppStrings.settingsLateReminder,
                      subtitle: user.lateReminderTime, // ✅ Directement depuis user
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

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Backup Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Backup Items
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
                    // ✅ Backup button - Valeur directement depuis user
                    _SettingsTile(
                      icon: Icons.cloud_upload,
                      iconColor: AppColors.successGreen,
                      title: AppStrings.settingsBackup,
                      subtitle: user.hasBackedUp // ✅ Directement depuis user
                          ? 'Dernière sauvegarde: ${_formatLastSync(user.lastSyncAt)}'
                          : 'Jamais sauvegardé',
                      trailing: syncState.status == SyncStatus.syncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: isOnline
                          ? () async {
                              await ref.read(syncNotifierProvider.notifier).backupToCloud();
                            }
                          : null,
                    ),
                    const Divider(height: 1, color: AppColors.divider),

                    // Restore button
                    _SettingsTile(
                      icon: Icons.cloud_download,
                      iconColor: Colors.blue,
                      title: AppStrings.settingsRestore,
                      subtitle: 'Récupérer depuis le cloud',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOnline && user.hasBackedUp
                          ? () => _showRestoreDialog(context, ref)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

// ============================================
// WIDGET À AJOUTER DANS settings_screen.dart
// Après la section "Backup Items"
// ============================================

// Mode local warning
if (ref.watch(isLocalModeProvider))
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warningYellow.withValues(alpha: 0.2),
              AppColors.lavaOrange.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warningYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off,
                    color: AppColors.warningYellow,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode Local',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warningYellow,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Données stockées localement uniquement',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu as créé ton compte sans connexion Internet. Tes données sont sauvegardées localement et seront automatiquement synchronisées avec le cloud dès que tu seras connecté.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isOnline
                    ? () async {
                        // Afficher un loader
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        
                        // Tenter la connexion
                        final success = await ref
                            .read(userProvider.notifier)
                            .forceConnectToFirebase();
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Fermer le loader
                          
                          if (success) {
                            // Déclencher la sync
                            await ref
                                .read(syncNotifierProvider.notifier)
                                .backupToCloud();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Connecté et synchronisé !'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Connexion échouée'),
                                backgroundColor: AppColors.dangerRed,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavaOrange,
                  disabledBackgroundColor: AppColors.deadGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isOnline ? Icons.cloud_upload : Icons.wifi_off,
                  size: 20,
                ),
                label: Text(
                  isOnline
                      ? 'Se connecter et synchroniser'
                      : 'Connexion requise',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
          // Connection status
          if (!isOnline)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warningYellow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: AppColors.warningYellow,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hors ligne - La sauvegarde nécessite une connexion',
                          style: TextStyle(
                            color: AppColors.warningYellow,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Sync status message
          if (syncState.message != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: syncState.status == SyncStatus.success
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncState.status == SyncStatus.success ? Icons.check_circle : Icons.error,
                        color: syncState.status == SyncStatus.success
                            ? AppColors.successGreen
                            : AppColors.dangerRed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          syncState.message!,
                          style: TextStyle(
                            color: syncState.status == SyncStatus.success
                                ? AppColors.successGreen
                                : AppColors.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                      subtitle: '1.0.0 (MVP)',
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

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Jamais';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  // ✅ FIX: Passer le ref pour pouvoir accéder au notifier
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

  // ✅ FIX: Passer le ref pour pouvoir accéder au notifier
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

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restaurer les données ?'),
        content: const Text(
          'Cela va remplacer toutes vos données locales par celles du cloud. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(syncNotifierProvider.notifier).restoreFromCloud();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
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