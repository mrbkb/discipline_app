// ============================================
// FICHIER OPTIMISÉ : lib/presentation/widgets/flame_widget.dart
// ✅ Taille initiale réduite + moins d'espacement
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/flame_provider.dart';

class FlameWidget extends ConsumerStatefulWidget {
  const FlameWidget({super.key});

  @override
  ConsumerState<FlameWidget> createState() => _FlameWidgetState();
}

class _FlameWidgetState extends ConsumerState<FlameWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // ✅ Animation de pulsation pour rendre la flamme vivante
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch flame level - se met à jour INSTANTANÉMENT
    final flameLevel = ref.watch(flameLevelProvider);
    final flamePercentage = ref.watch(flamePercentageProvider);

    return Container(
      height: 210,
      // ✅ FIX: Réduire la hauteur (210 au lieu de 250)
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
                  // 🔥 Flame animation avec pulsation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // ✅ Glow dynamique basé sur le niveau
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            // ✅ FIX: Taille initiale plus petite (80 au lieu de 100)
                            width: 80 + (flameLevel * 40),
                            height: 80 + (flameLevel * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _getFlameColor(flameLevel)
                                      .withValues(alpha: 0.4 * flameLevel),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // ✅ Emoji flamme avec animation
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                // ✅ FIX: Taille initiale plus petite (60 au lieu de 80)
                                fontSize: 60 + (flameLevel * 28),
                              ),
                              child: const Text('🔥'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 3),
                  // ✅ FIX: Espacement minimal (3 au lieu de 6)

                  // 🔢 Percentage avec animation de changement
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '$flamePercentage%',
                      key: ValueKey<int>(flamePercentage),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        // ✅ FIX: Taille réduite (38 au lieu de 48)
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: _getFlameColor(flameLevel),
                      ),
                    ),
                  ),

                  const SizedBox(height: 1),
                  // ✅ FIX: Espacement minimal (1 au lieu de 4)

                  // 🏷 Label
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Niveau de discipline',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // ✅ FIX: Taille réduite (11 au lieu de 14)
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // ✅ FIX: Espacement réduit (8 au lieu de 16)

                  // 📊 Progress bar avec animation fluide
                  Container(
                    width: 170,
                    // ✅ FIX: Largeur réduite (170 au lieu de 200)
                    height: 5,
                    // ✅ FIX: Hauteur réduite (5 au lieu de 8)
                    decoration: BoxDecoration(
                      color: AppColors.deadGray,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
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
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: _getFlameColor(flameLevel)
                                  .withValues(alpha: 0.3),
                              blurRadius: 3,
                              spreadRadius: 0.5,
                            ),
                          ],
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