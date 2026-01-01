
// ============================================
// FICHIER 33/35 : lib/presentation/widgets/validate_button.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/habits_provider.dart';

class ValidateButton extends ConsumerStatefulWidget {
  const ValidateButton({super.key});

  @override
  ConsumerState<ValidateButton> createState() => _ValidateButtonState();
}

class _ValidateButtonState extends ConsumerState<ValidateButton> {
  late ConfettiController _confettiController;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _validateDay() async {
    if (_isValidating) return;
    
    setState(() => _isValidating = true);
    
    // Haptic feedback
    await Vibration.vibrate(duration: 100);
    
    // Validate
    await ref.read(habitsProvider.notifier).validateDay();
    
    // Show confetti
    _confettiController.play();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journée validée ! 🔥'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCompleted = ref.watch(allCompletedProvider);
    final completedCount = ref.watch(completedTodayProvider).length;
    final totalCount = ref.watch(activeHabitsProvider).length;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.3,
          shouldLoop: false,
          colors: const [
            AppColors.lavaOrange,
            AppColors.successGreen,
            AppColors.warningYellow,
            Colors.blue,
            Colors.pink,
          ],
        ),
        
        // Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: allCompleted || totalCount == 0 ? null : _validateDay,
            style: ElevatedButton.styleFrom(
              backgroundColor: allCompleted
                  ? AppColors.successGreen
                  : AppColors.lavaOrange,
              disabledBackgroundColor: AppColors.successGreen.withValues(alpha:0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: allCompleted ? 0 : 4,
            ),
            child: _isValidating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!allCompleted && totalCount > 0) ...[
                        Text(
                          '$completedCount/$totalCount ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      Text(
                        allCompleted
                            ? AppStrings.homeValidatedButton
                            : AppStrings.homeValidateButton,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (allCompleted) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 24),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}