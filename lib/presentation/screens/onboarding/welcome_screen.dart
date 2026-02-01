// ============================================
// FICHIER MIS À JOUR : lib/presentation/screens/onboarding/welcome_screen.dart
// ✅ Sans badge "Ndjoka", design plus épuré
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/analytics_service.dart';
import 'nickname_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AnalyticsService.logScreenView('welcome');
    
    return Scaffold(
      backgroundColor: AppColors.midnightBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Flame emoji avec animation
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Text(
                      '🔥',
                      style: TextStyle(fontSize: 120),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // App Title avec gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppColors.lavaOrange,
                    Color(0xFFFFD60A),
                  ],
                ).createShader(bounds),
                child: Text(
                  AppStrings.onboardingTitle,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Slogan principal
              Text(
                AppStrings.onboardingSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 18, // Légèrement plus grand
                  fontWeight: FontWeight.w600, // Plus bold
                ),
              ),
              const SizedBox(height: 24),
              
              // ✅ OPTIONNEL : Tagline descriptif (remplace l'ancien badge)
              // Décommentez si vous voulez ajouter une ligne explicative
              /*
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavaOrange.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.lavaOrange.withValues(alpha:.25),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  AppStrings.onboardingTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lavaOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              */
              
              // ✅ ALTERNATIVE : Liste de points clés (plus moderne)
              const SizedBox(height: 8),
              const _FeatureItem(
                icon: Icons.local_fire_department,
                text: 'Système de flamme motivant',
              ),
              const SizedBox(height: 12),
              const _FeatureItem(
                icon: Icons.notifications_active,
                text: 'Rappels sans pitié',
              ),
              const SizedBox(height: 12),
              const _FeatureItem(
                icon: Icons.trending_up,
                text: 'Progrès visibles jour après jour',
              ),
              
              const Spacer(),
              
              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    AnalyticsService.logEvent(
                      name: 'onboarding_welcome_continue',
                      parameters: {},
                    );
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NicknameScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavaOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.onboardingButton,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ NOUVEAU : Widget pour les points clés
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.lavaOrange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}