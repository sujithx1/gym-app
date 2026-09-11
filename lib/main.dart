import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/gym_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/widgets/liquid_background.dart';
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

    return MaterialApp(
      title: 'Gym Workout Tracker',
      debugShowCheckedModeBanner: false,
      theme: GymTheme.lightTheme,
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

  final List<Widget> _pages = const [
    HomeScreen(),
    ExerciseLibraryScreen(),
    ProgressScreen(),
    ProfileScreen(),
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
            width: double.infinity,
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: GymTheme.surface,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: GymTheme.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox.expand(
              child: Row(
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? GymTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GymTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
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
