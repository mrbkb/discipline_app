
// ============================================
// FICHIER 28/30 : lib/presentation/screens/onboarding/nickname_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/analytics_service.dart';
import '../../providers/user_provider.dart';
import 'habits_selection_screen.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  final List<String> _suggestions = [
    'Boss',
    'Champion',
    'Warrior',
    'Legend',
    'Hero',
    'Titan',
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = 'Champion';
    AnalyticsService.logScreenView('nickname');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
  }

  Future<void> _continue() async {
    final nickname = _controller.text.trim();
    
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre un surnom d\'abord'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    
    // Create user with nickname
    await ref.read(userProvider.notifier).createUser(nickname: nickname);
    
    AnalyticsService.logEvent(
      name: 'onboarding_nickname_set',
      parameters: {'nickname_length': nickname.length},
    );
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const HabitsSelectionScreen(),
        ),
      );
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Title
              Text(
                AppStrings.nicknameTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 32),
              
              // Input field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusNode.hasFocus 
                        ? AppColors.lavaOrange 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.nicknameHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 20,
                ),
              ),
              const SizedBox(height: 24),
              
              // Suggestions
              Text(
                'Suggestions rapides :',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _controller.text == suggestion
                            ? AppColors.lavaOrange.withOpacity(0.2)
                            : AppColors.deadGray,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _controller.text == suggestion
                              ? AppColors.lavaOrange
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: _controller.text == suggestion
                              ? AppColors.lavaOrange
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const Spacer(),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.text.isEmpty ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavaOrange,
                    disabledBackgroundColor: AppColors.deadGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.nicknameNext,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 24),
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
