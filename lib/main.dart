import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/gym_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/widgets/liquid_background.dart';
import 'core/widgets/treadmill_loading.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/exercises/exercise_library_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  runApp(const ProviderScope(child: GymWorkoutApp()));
}

class GymWorkoutApp extends ConsumerWidget {
  const GymWorkoutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gym Workout Tracker',
      debugShowCheckedModeBanner: false,
      theme: GymTheme.lightTheme,
      darkTheme: GymTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return GlobalTreadmillOverlay(child: child ?? const SizedBox.shrink());
      },
      home: authState.isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    HomeScreen(
      onNavigateTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
    const ExerciseLibraryScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: LiquidBackground(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: GymTheme.periwinkle.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              const Color(0xFF292C3E).withValues(alpha: 0.95),
                              const Color(0xFF1F2130).withValues(alpha: 0.90),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.72),
                              Colors.white.withValues(alpha: 0.42),
                              GymTheme.periwinkle.withValues(alpha: 0.18),
                            ],
                      stops: Theme.of(context).brightness == Brightness.dark
                          ? const [0.0, 1.0]
                          : const [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF383C52)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.4,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Soft liquid sheen highlight
                      Positioned(
                        top: 0,
                        left: 16,
                        right: 16,
                        height: 1.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.grid_view_outlined,
                            Icons.grid_view_rounded,
                            'Home',
                          ),
                          _buildNavItem(
                            1,
                            Icons.fitness_center_outlined,
                            Icons.fitness_center_rounded,
                            'Workout',
                          ),
                          _buildNavItem(
                            2,
                            Icons.show_chart_rounded,
                            Icons.insights_rounded,
                            'Progress',
                          ),
                          _buildNavItem(
                            3,
                            Icons.person_outline_rounded,
                            Icons.person_rounded,
                            'Profile',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? GymTheme.primary.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.2,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GymTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? Colors.white : GymTheme.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : GymTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
