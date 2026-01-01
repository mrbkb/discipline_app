// ============================================
// FICHIER CORRIGÉ : lib/presentation/widgets/flame_widget.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/flame_provider.dart';

class FlameWidget extends ConsumerWidget {
  const FlameWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flameLevel = ref.watch(flameLevelProvider);
    final flamePercentage = ref.watch(flamePercentageProvider);

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 Flame animation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getFlameColor(flameLevel)
                                  .withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Flame emoji
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.9, end: 1.0),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Text(
                              '🔥',
                              style: TextStyle(
                                fontSize:
                                    120 * flameLevel.clamp(0.5, 1.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 🔢 Percentage (anti-overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$flamePercentage%',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _getFlameColor(flameLevel),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 🏷 Label sécurisé
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Niveau de discipline',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📊 Progress bar
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.deadGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: flameLevel.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getFlameColor(flameLevel),
                              _getFlameColor(flameLevel)
                                  .withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getFlameColor(double level) {
    if (level >= 0.8) return AppColors.lavaOrange;
    if (level >= 0.6) return const Color(0xFFFFA500);
    if (level >= 0.4) return const Color(0xFFFFD700);
    if (level >= 0.2) return AppColors.warningYellow;
    return AppColors.dangerRed;
  }
}
