// ============================================
// FICHIER NETTOYÉ : lib/presentation/screens/stats/stats_screen.dart
// ✅ Tous les print() retirés (calculs purs)
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/utils/date_helper.dart';
import '../../providers/stats_provider.dart';
import '../../providers/habits_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _barAnimation;
  
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('stats');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _barAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentStats = ref.watch(currentStatsProvider);
    final habits = ref.watch(activeHabitsProvider);
    
    final weeklyData = _calculateWeeklyData(habits);
    final weeklyCompletionPercentage = weeklyData['completionPercentage'] as int;
    final bestFlamePercentage = ref.watch(bestFlamePercentageProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            backgroundColor: AppColors.midnightBlack,
            title: Text(AppStrings.statsTitle),
            centerTitle: false,
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.statsPerformance,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCompletionColor(weeklyCompletionPercentage / 100)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$weeklyCompletionPercentage%',
                          style: TextStyle(
                            color: _getCompletionColor(weeklyCompletionPercentage / 100),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 180,
                    child: AnimatedBuilder(
                      animation: _barAnimation,
                      builder: (context, child) {
                        final weeklyBars = weeklyData['bars'] as List<Map<String, dynamic>>;
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: weeklyBars.asMap().entries.map((entry) {
                            final index = entry.key;
                            final barData = entry.value;
                            final date = barData['date'] as String;
                            final completionRate = barData['completionRate'] as double;
                            final isPerfect = barData['isPerfect'] as bool;
                            
                            final delay = index * 0.08;
                            final adjustedValue = (_barAnimation.value - delay).clamp(0.0, 1.0);
                            final normalizedValue = delay < 1.0 
                                ? adjustedValue / (1.0 - delay)
                                : adjustedValue;
                            final animValue = Curves.easeOutCubic.transform(normalizedValue.clamp(0.0, 1.0));
                            
                            final targetHeight = completionRate * 140;
                            final animatedHeight = targetHeight * animValue;
                            
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: animatedHeight.clamp(20.0, 140.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            _getCompletionColor(completionRate),
                                            _getCompletionColor(completionRate)
                                                .withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: isPerfect ? [
                                          BoxShadow(
                                            color: _getCompletionColor(completionRate)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ] : null,
                                      ),
                                      child: isPerfect
                                          ? Center(
                                              child: AnimatedOpacity(
                                                opacity: animValue,
                                                duration: const Duration(milliseconds: 300),
                                                child: const Icon(
                                                  Icons.star,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedOpacity(
                                      opacity: animValue,
                                      duration: const Duration(milliseconds: 300),
                                      child: SizedBox(
                                        height: 16,
                                        child: Text(
                                          DateHelper.getDayLabel(date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: completionRate == 1.0
                                                ? AppColors.successGreen
                                                : AppColors.textSecondary,
                                            fontWeight: completionRate == 1.0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: AppColors.successGreen, label: 'Parfait'),
                      SizedBox(width: 16),
                      _LegendItem(color: AppColors.lavaOrange, label: 'Bon'),
                      SizedBox(width: 16),
                      _LegendItem(color: AppColors.warningYellow, label: 'Moyen'),
                      SizedBox(width: 16),
                      _LegendItem(color: AppColors.dangerRed, label: 'Faible'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vue d\'ensemble',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: AppColors.lavaOrange,
                          label: AppStrings.statsBestFlame,
                          value: '$bestFlamePercentage%',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star,
                          iconColor: AppColors.warningYellow,
                          label: 'Jours parfaits',
                          value: '${currentStats.perfectDays}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today,
                          iconColor: AppColors.successGreen,
                          label: AppStrings.statsTotalDays,
                          value: '${currentStats.totalActiveDays}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up,
                          iconColor: Colors.blue,
                          label: 'Taux moyen',
                          value: '$weeklyCompletionPercentage%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppStrings.statsRecords,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (habits.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune statistique',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = habits[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.deadGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                habit.emoji ?? '✨',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department,
                                      size: 14,
                                      color: AppColors.lavaOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Actuel: ${habit.currentStreak} jours',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningYellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  size: 18,
                                  color: AppColors.warningYellow,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${habit.bestStreak}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: habits.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 1.0) return AppColors.successGreen;
    if (rate >= 0.7) return AppColors.lavaOrange;
    if (rate >= 0.4) return AppColors.warningYellow;
    return AppColors.dangerRed;
  }
  
  Map<String, dynamic> _calculateWeeklyData(List<dynamic> habits) {
    final last7Days = DateHelper.getLast7Days();
    final List<Map<String, dynamic>> bars = [];
    int totalCompletionSum = 0;
    
    for (final dateString in last7Days) {
      int completedCount = 0;
      final totalHabits = habits.length;
      
      if (totalHabits > 0) {
        for (final habit in habits) {
          if (habit.completedDates.contains(dateString)) {
            completedCount++;
          }
        }
      }
      
      final completionRate = totalHabits > 0 ? completedCount / totalHabits : 0.0;
      final isPerfect = completedCount == totalHabits && totalHabits > 0;
      
      bars.add({
        'date': dateString,
        'completionRate': completionRate,
        'isPerfect': isPerfect,
        'completed': completedCount,
        'total': totalHabits,
      });
      
      totalCompletionSum += (completionRate * 100).round();
    }
    
    final averageCompletion = last7Days.isNotEmpty 
        ? (totalCompletionSum / last7Days.length).round() 
        : 0;
    
    return {
      'bars': bars,
      'completionPercentage': averageCompletion,
    };
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: iconColor,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}