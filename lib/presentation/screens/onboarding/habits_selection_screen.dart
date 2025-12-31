
// ============================================
// FICHIER 29/30 : lib/presentation/screens/onboarding/habits_selection_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/analytics_service.dart';
import '../../providers/habits_provider.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';

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
  ];
  
  final Set<int> _selectedIndices = {};
  final TextEditingController _customController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('habits_selection');
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
      } else {
        if (_selectedIndices.length < 5) {
          _selectedIndices.add(index);
          Vibration.vibrate(duration: 50);
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
    
    // Add to predefined list temporarily
    setState(() {
      _predefinedHabits.add({
        'title': title,
        'emoji': '✨',
        'color': '#FF6B35',
      });
      _selectedIndices.add(_predefinedHabits.length - 1);
      _customController.clear();
    });
    
    Vibration.vibrate(duration: 50);
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
      // Create selected habits
      final selectedHabits = _selectedIndices
          .map((i) => _predefinedHabits[i])
          .toList();
      
      await ref.read(habitsProvider.notifier).createMultipleHabits(selectedHabits);
      
      // Complete onboarding
      await ref.read(userProvider.notifier).completeOnboarding();
      
      // Analytics
      await AnalyticsService.logOnboardingCompleted(
        nickname: ref.read(userNicknameProvider),
        habitsCount: _selectedIndices.length,
      );
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
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
                  Text(
                    AppStrings.habitsTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.habitsSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selection counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIndices.length >= 3
                          ? AppColors.successGreen.withOpacity(0.2)
                          : AppColors.lavaOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndices.length}/5 sélectionnées',
                      style: TextStyle(
                        color: _selectedIndices.length >= 3
                            ? AppColors.successGreen
                            : AppColors.lavaOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Habits grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _predefinedHabits.length,
                itemBuilder: (context, index) {
                  final habit = _predefinedHabits[index];
                  final isSelected = _selectedIndices.contains(index);
                  
                  return InkWell(
                    onTap: () => _toggleHabit(index),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lavaOrange.withOpacity(0.2)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.lavaOrange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            habit['emoji'],
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            habit['title'],
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.lavaOrange
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.lavaOrange,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Custom habit input
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            hintText: '+ Ajouter une habitude',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _addCustomHabit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.lavaOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
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
                                  AppStrings.habitsStart,
                                  style: const TextStyle(
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