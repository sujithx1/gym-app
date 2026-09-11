import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/treadmill_loading.dart';
import '../workout/today_workout_screen.dart';
import '../workout/create_workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final progressAsync = ref.watch(progressOverviewProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: GymTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayWorkoutProvider);
            ref.invalidate(progressOverviewProvider);
          },
          color: GymTheme.primary,
          backgroundColor: GymTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Editorial Tag + Title + Avatar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY OVERVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: GymTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello, ${authState.username ?? 'Sujith'} 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: GymTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // User avatar badge with liquid glass border
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: GymTheme.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: GymTheme.periwinkle.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (authState.username ?? 'S')[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: GymTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'WORKOUT DASHBOARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: GymTheme.textMuted,
                      ),
                    ),
                    Text(
                      'LIQUID GLASS ✨',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: GymTheme.periwinkleDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2x2 Glowing Liquid Glass Card Grid (Distinct Actions)
                todayAsync.when(
                  data: (data) {
                    final today = data['today'];
                    final activeSession = today != null ? today['activeSession'] : null;

                    final workoutName = today != null ? (today['name'] ?? 'Chest & Arms') : 'Chest & Triceps';
                    final workoutStatus = activeSession != null && activeSession['status'] == 'in_progress'
                        ? 'In Progress • Resume'
                        : (today != null ? '${today['exerciseCount'] ?? 5} exercises' : 'Ready to start');

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Card 1: Create Workout Day -> Opens CreateWorkoutScreen
                        _buildGlowingGridCard(
                          context: context,
                          tag: 'WORKOUT DAY',
                          title: 'Create Workout Day',
                          subtitle: 'Build custom split',
                          icon: Icons.fitness_center_rounded,
                          backgroundColor: GymTheme.periwinkle,
                          glowColor: GymTheme.periwinkleDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateWorkoutScreen(),
                              ),
                            );
                          },
                        ),

                        // Card 2: Exercise Creation -> Navigates to Exercise Library Screen
                        _buildGlowingGridCard(
                          context: context,
                          tag: 'EXERCISE CREATOR',
                          title: 'Exercise Creation',
                          subtitle: 'Add new movement',
                          icon: Icons.add_circle_rounded,
                          backgroundColor: GymTheme.yellow,
                          glowColor: GymTheme.yellowDark,
                          onTap: () {
                            onNavigateTab?.call(1);
                          },
                        ),

                        // Card 3: Progression -> Navigates to Progress Analytics Tab
                        _buildGlowingGridCard(
                          context: context,
                          tag: 'ANALYTICS',
                          title: 'Progression',
                          subtitle: 'Strength & volume',
                          icon: Icons.show_chart_rounded,
                          backgroundColor: GymTheme.mint,
                          glowColor: GymTheme.mintDark,
                          onTap: () {
                            onNavigateTab?.call(2);
                          },
                        ),

                        // Card 4: Daily Workout Session -> Opens TodayWorkoutScreen
                        _buildGlowingGridCard(
                          context: context,
                          tag: 'TODAY\'S SESSION',
                          title: 'Daily Workout',
                          subtitle: workoutStatus.isNotEmpty ? workoutStatus : workoutName,
                          icon: Icons.bolt_rounded,
                          backgroundColor: GymTheme.peach,
                          glowColor: GymTheme.peachDark,
                          onTap: () {
                            if (today != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TodayWorkoutScreen(todayData: today),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateWorkoutScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 240,
                    child: Center(
                      child: TreadmillLoadingIndicator(message: 'Loading workout dashboard...'),
                    ),
                  ),
                  error: (_, __) => _buildFallbackGrid(context),
                ),
                const SizedBox(height: 24),

                // Large Progress Percentage Card (Matching 89% Card in Reference Image)
                progressAsync.when(
                  data: (data) {
                    final summary = data['summary'] ?? {};
                    final completedSets = summary['totalSetsCompleted'] ?? 15;
                    final targetSets = 18;
                    final progressRatio = (completedSets / targetSets).clamp(0.0, 1.0);
                    final percentInt = (progressRatio * 100).toInt();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: GymTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: GymTheme.periwinkle.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'YOUR WEEKLY GOAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: GymTheme.textMuted,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: GymTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: GymTheme.primary.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Big bold percentage layout (matching reference image 89% text)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$percentInt%',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: GymTheme.textPrimary,
                                  letterSpacing: -1.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Of the weekly volume plan completed ($completedSets of $targetSets sets)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: GymTheme.textSecondary.withValues(alpha: 0.8),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Smooth progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 12,
                              backgroundColor: GymTheme.surfaceElevated,
                              valueColor: const AlwaysStoppedAnimation<Color>(GymTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Streak Pill Badge Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daily Streak Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: GymTheme.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: GymTheme.yellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${summary['streakDays'] ?? 12} DAYS 🔥',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: GymTheme.textPrimary,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 28),

                // Personal Records Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PERSONAL RECORDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: GymTheme.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onNavigateTab?.call(2),
                      child: const Text(
                        'View All ↗',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GymTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // PR Cards Carousel with Pastel Fills & ↗ Badges
                progressAsync.when(
                  data: (data) {
                    final prs = (data['personalRecords'] as List?) ?? [
                      {'exerciseName': 'Bench Press', 'maxWeight': 80.0, 'maxReps': 6},
                      {'exerciseName': 'Barbell Squat', 'maxWeight': 120.0, 'maxReps': 5},
                      {'exerciseName': 'Deadlift', 'maxWeight': 150.0, 'maxReps': 3},
                    ];

                    return SizedBox(
                      height: 135,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: prs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final pr = prs[index];
                          final colors = [
                            GymTheme.periwinkle,
                            GymTheme.yellow,
                            GymTheme.mint,
                            GymTheme.peach,
                          ];
                          final cardBg = colors[index % colors.length];

                          return Container(
                            width: 175,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pr['exerciseName'] ?? 'Bench Press',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: GymTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: GymTheme.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.north_east_rounded, size: 14, color: GymTheme.primary),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pr['maxWeight']} kg',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: GymTheme.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      '${pr['maxReps']} reps PR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: GymTheme.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingGridCard({
    required BuildContext context,
    required String tag,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: GymTheme.primary,
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: GymTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 15,
                    color: GymTheme.primary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: GymTheme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: GymTheme.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: GymTheme.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGlowingGridCard(
          context: context,
          tag: 'WORKOUT DAY',
          title: 'Create Workout Day',
          subtitle: 'Build custom split',
          icon: Icons.fitness_center_rounded,
          backgroundColor: GymTheme.periwinkle,
          glowColor: GymTheme.periwinkleDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()));
          },
        ),
        _buildGlowingGridCard(
          context: context,
          tag: 'EXERCISE CREATOR',
          title: 'Exercise Creation',
          subtitle: 'Add new movement',
          icon: Icons.add_circle_rounded,
          backgroundColor: GymTheme.yellow,
          glowColor: GymTheme.yellowDark,
          onTap: () {
            onNavigateTab?.call(1);
          },
        ),
      ],
    );
  }
}

