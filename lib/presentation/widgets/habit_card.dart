// ============================================
// FICHIER PRODUCTION : lib/presentation/widgets/habit_card.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/logger_service.dart';
import '../../data/models/habit_model.dart';
import '../providers/habits_provider.dart';

class HabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;

  const HabitCard({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    if (_isAnimating || _isDisposed) return;
    
    setState(() => _isAnimating = true);
    
    try {
      await _controller.forward();
      
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 50);
      }
      
      await ref.read(habitsProvider.notifier).toggleHabitCompletion(widget.habit.id);
      
      await _controller.reverse();
    } catch (e, stack) {
      LoggerService.error('Error toggling habit', tag: 'HABIT_CARD', error: e, stackTrace: stack);
      
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isAnimating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.habit.isCompletedToday();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
        key: Key(widget.habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.dangerRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.archive_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          if (!mounted) return false;
          
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Archiver cette habitude ?'),
              content: const Text(
                'Tu pourras la restaurer plus tard depuis les paramètres.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                  ),
                  child: const Text('Archiver'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) async {
          try {
            await ref.read(habitsProvider.notifier).archiveHabit(widget.habit.id);
            
            if (mounted && !_isDisposed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.habit.title} archivée'),
                  backgroundColor: AppColors.dangerRed,
                  action: SnackBarAction(
                    label: 'Annuler',
                    textColor: Colors.white,
                    onPressed: () {
                      // TODO: Implement undo
                    },
                  ),
                ),
              );
            }
          } catch (e, stack) {
            LoggerService.error('Error archiving habit', tag: 'HABIT_CARD', error: e, stackTrace: stack);
          }
        },
        child: InkWell(
          onTap: _toggleCompletion,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.successGreen.withValues(alpha: 0.1)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? AppColors.successGreen
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Emoji
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successGreen.withOpacity(0.2)
                        : AppColors.deadGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.habit.emoji ?? '✨',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.successGreen
                              : AppColors.textPrimary,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: widget.habit.currentStreak > 0
                                ? AppColors.lavaOrange
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${AppStrings.homeStreak} ${widget.habit.currentStreak} ${AppStrings.homeDays}',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.habit.currentStreak > 0
                                  ? AppColors.lavaOrange
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (widget.habit.bestStreak > 0) ...[
                            const Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: AppColors.warningYellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.habit.bestStreak}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.warningYellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successGreen
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.successGreen
                          : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}