// ============================================
// FICHIER CORRIGÉ : lib/presentation/screens/splash/splash_screen.dart
// ✅ FIX: Navigation qui ne bloque plus
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/logger_service.dart';
import '../../providers/user_provider.dart';
import '../onboarding/welcome_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    LoggerService.info('SplashScreen initState', tag: 'SPLASH');
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _animationController.forward();
    
    // Navigate after initialization
    _initializeAndNavigate();
    
    // Log screen view
    AnalyticsService.logScreenView('splash');
  }

  Future<void> _initializeAndNavigate() async {
    try {
      LoggerService.info('Starting initialization', tag: 'SPLASH');
      
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (!mounted || _hasNavigated) {
        LoggerService.warning('Not mounted or already navigated', tag: 'SPLASH');
        return;
      }
      
      LoggerService.info('Reading onboarding status', tag: 'SPLASH');
      
      // ✅ FIX CRITIQUE: Utiliser watch au lieu de read
      // et vérifier si le user existe d'abord
      final userRepo = ref.read(userRepositoryProvider);
      final userExists = userRepo.userExists();
      
      LoggerService.info('User exists: $userExists', tag: 'SPLASH', data: {
        'userExists': userExists,
      });
      
      bool shouldShowOnboarding = true;
      
      if (userExists) {
        final user = userRepo.getUser();
        shouldShowOnboarding = user?.onboardingCompleted != true;
        
        LoggerService.info('User found', tag: 'SPLASH', data: {
          'nickname': user?.nickname,
          'onboardingCompleted': user?.onboardingCompleted,
          'shouldShowOnboarding': shouldShowOnboarding,
        });
      } else {
        LoggerService.info('No user found - showing onboarding', tag: 'SPLASH');
      }
      
      // Navigate to appropriate screen
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        
        LoggerService.info('Navigating to ${shouldShowOnboarding ? 'Onboarding' : 'Home'}', tag: 'SPLASH');
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => shouldShowOnboarding 
                ? const WelcomeScreen() 
                : const HomeScreen(),
          ),
        );
      }
      
    } catch (e, stack) {
      LoggerService.error('Initialization error', tag: 'SPLASH', error: e, stackTrace: stack);
      
      // ✅ FALLBACK: En cas d'erreur, aller au welcome screen
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        LoggerService.warning('Error during init - navigating to Welcome screen', tag: 'SPLASH');
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlack,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flame animation
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        AppAssets.flameAnimation,
                        repeat: true,
                        // ✅ FIX: Fallback si fichier manquant
                        errorBuilder: (context, error, stackTrace) {
                          LoggerService.warning('Lottie animation not found', tag: 'SPLASH');
                          return const Text('🔥', style: TextStyle(fontSize: 120));
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // App name
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.lavaOrange,
                          Color(0xFFFFD60A),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'DISCIPLINE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tagline
                    const Text(
                      'Le feu qui ne s\'éteint jamais',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lavaOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}