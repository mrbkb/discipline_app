// ============================================
// FICHIER PRODUCTION : lib/presentation/screens/onboarding/habits_selection_screen.dart
// VERSION MINIMALISTE ET ÉPURÉE
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/logger_service.dart';
import '../../providers/habits_provider.dart';
import '../../providers/user_provider.dart';
import 'notification_permission_screen.dart';

class HabitsSelectionScreen extends ConsumerStatefulWidget {
  const HabitsSelectionScreen({super.key});

  @override
  ConsumerState<HabitsSelectionScreen> createState() => _HabitsSelectionScreenState();
}

class _HabitsSelectionScreenState extends ConsumerState<HabitsSelectionScreen> {
  final List<Map<String, dynamic>> _predefinedHabits = [
    {'title': 'Sport', 'emoji': '💪', 'color': '#FF6B35'},
    {'title': 'Lecture', 'emoji': '📚', 'color': '#4ECDC4'},
    {'title': 'Méditation', 'emoji': '🧘', 'color': '#95E1D3'},
    {'title': 'Eau (2L)', 'emoji': '💧', 'color': '#3498DB'},
    {'title': 'Sommeil 8h', 'emoji': '😴', 'color': '#9B59B6'},
    {'title': 'Coding', 'emoji': '💻', 'color': '#E74C3C'},
    {'title': 'Journal', 'emoji': '📝', 'color': '#F39C12'},
    {'title': 'Apprentissage', 'emoji': '🎓', 'color': '#2ECC71'},
    {'title': 'Cuisine', 'emoji': '🍳', 'color': '#E67E22'},
    {'title': 'Marche', 'emoji': '🚶', 'color': '#1ABC9C'},
  ];
  
  final Set<int> _selectedIndices = {};
  final TextEditingController _customController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('habits_selection');
    LoggerService.info('Habits selection screen opened', tag: 'ONBOARDING');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggleHabit(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        LoggerService.debug('Habit deselected: ${_predefinedHabits[index]['title']}', tag: 'ONBOARDING');
      } else {
        if (_selectedIndices.length < 5) {
          _selectedIndices.add(index);
          Vibration.vibrate(duration: 30);
          LoggerService.debug('Habit selected: ${_predefinedHabits[index]['title']}', tag: 'ONBOARDING');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 5 habitudes pour commencer'),
              backgroundColor: AppColors.warningYellow,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _addCustomHabit() async {
    final title = _customController.text.trim();
    if (title.isEmpty) return;
    
    if (_selectedIndices.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 habitudes'),
          backgroundColor: AppColors.warningYellow,
        ),
      );
      return;
    }
    
    setState(() {
      _predefinedHabits.add({
        'title': title,
        'emoji': '✨',
        'color': '#FF6B35',
      });
      _selectedIndices.add(_predefinedHabits.length - 1);
      _customController.clear();
    });
    
    Vibration.vibrate(duration: 30);
    LoggerService.info('Custom habit added: $title', tag: 'ONBOARDING');
  }

  Future<void> _finish() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisis au moins 1 habitude'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final selectedHabits = _selectedIndices
          .map((i) => _predefinedHabits[i])
          .toList();
      
      LoggerService.info('Creating ${selectedHabits.length} habits', tag: 'ONBOARDING');
      
      await ref.read(habitsProvider.notifier).createMultipleHabits(selectedHabits);
      await ref.read(userProvider.notifier).completeOnboarding();
      
      await AnalyticsService.logOnboardingCompleted(
        nickname: ref.read(userNicknameProvider),
        habitsCount: _selectedIndices.length,
      );
      
      LoggerService.info('Onboarding completed successfully', tag: 'ONBOARDING');
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NotificationPermissionScreen(),
          ),
        );
      }
    } catch (e, stack) {
      LoggerService.error('Failed to complete onboarding', tag: 'ONBOARDING', error: e, stackTrace: stack);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisis tes batailles',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3 à 5 habitudes pour commencer',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selection counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _selectedIndices.length >= 3
                              ? AppColors.successGreen.withValues(alpha: 0.2)
                              : AppColors.lavaOrange.withValues(alpha: 0.2),
                          _selectedIndices.length >= 3
                              ? AppColors.successGreen.withValues(alpha: 0.1)
                              : AppColors.lavaOrange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedIndices.length >= 3
                            ? AppColors.successGreen.withValues(alpha: 0.3)
                            : AppColors.lavaOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedIndices.length >= 3 ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: _selectedIndices.length >= 3
                              ? AppColors.successGreen
                              : AppColors.lavaOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedIndices.length}/5 sélectionnées',
                          style: TextStyle(
                            color: _selectedIndices.length >= 3
                                ? AppColors.successGreen
                                : AppColors.lavaOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Habits list (scrollable)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _predefinedHabits.length,
                itemBuilder: (context, index) {
                  final habit = _predefinedHabits[index];
                  final isSelected = _selectedIndices.contains(index);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _toggleHabit(index),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.lavaOrange.withValues(alpha: 0.15)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.lavaOrange
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Emoji
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.lavaOrange.withValues(alpha: 0.2)
                                    : AppColors.deadGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  habit['emoji'],
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            
                            // Title
                            Expanded(
                              child: Text(
                                habit['title'],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.lavaOrange
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.lavaOrange
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.lavaOrange
                                      : AppColors.textTertiary,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom section (custom input + finish button)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom habit input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: '+ Ajouter une habitude',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.deadGray,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _addCustomHabit(),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.lavaOrange,
                              Color(0xFFFF8C5A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 24),
                          onPressed: _addCustomHabit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Finish button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading || _selectedIndices.isEmpty
                          ? null
                          : _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavaOrange,
                        disabledBackgroundColor: AppColors.deadGray,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'C\'est parti ! 🔥',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}