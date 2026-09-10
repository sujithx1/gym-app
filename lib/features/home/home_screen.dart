import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import '../workout/today_workout_screen.dart';
import '../workout/create_workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayWorkoutProvider);
    final progressAsync = ref.watch(progressOverviewProvider);
    final authState = ref.watch(authProvider);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, ${authState.username ?? 'Sujith'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: GymTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GymTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // User avatar badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: GymTheme.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'S',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: GymTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hero Workout Card
                todayAsync.when(
                  data: (data) {
                    final today = data['today'];
                    final activeSession = today != null ? today['activeSession'] : null;

                    if (today == null) {
                      return _buildCreateWorkoutCard(context);
                    }

                    final name = today['name'] ?? 'CHEST + TRICEPS';
                    final exerciseCount = today['exerciseCount'] ?? 5;
                    final totalSets = today['totalSets'] ?? 18;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: GymTheme.mint,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: GymTheme.border.withOpacity(0.6)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'TODAY\'S TRAINING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: GymTheme.textPrimary,
                                  ),
                                ),
                              ),

                              // Abstract geometric visual accent
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: GymTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: GymTheme.primary.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: GymTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            '$exerciseCount exercises  •  $totalSets sets',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GymTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TodayWorkoutScreen(todayData: today),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GymTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: Text(
                                activeSession != null && activeSession['status'] == 'in_progress'
                                    ? 'CONTINUE WORKOUT'
                                    : 'START WORKOUT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(height: 200, decoration: BoxDecoration(color: GymTheme.mint, borderRadius: BorderRadius.circular(28))),
                  error: (_, __) => _buildCreateWorkoutCard(context),
                ),
                const SizedBox(height: 24),

                // Daily Progress Section
                progressAsync.when(
                  data: (data) {
                    final summary = data['summary'] ?? {};
                    final completedSets = summary['totalSetsCompleted'] ?? 12;
                    final targetSets = 18;
                    final progressRatio = (completedSets / targetSets).clamp(0.0, 1.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TODAY\'S PROGRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: GymTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: GymTheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: GymTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$completedSets / $targetSets sets',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: GymTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${(progressRatio * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: GymTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 10,
                                  backgroundColor: GymTheme.surfaceElevated,
                                  valueColor: const AlwaysStoppedAnimation<Color>(GymTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Small pastel stat cards grid
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: GymTheme.lavender,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$completedSets',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: GymTheme.textPrimary,
                                            ),
                                          ),
                                          const Text(
                                            'Sets completed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: GymTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: GymTheme.blue,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '4',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: GymTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Exercises',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: GymTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Streak Card
                progressAsync.when(
                  data: (data) {
                    final summary = data['summary'] ?? {};
                    final streak = summary['streakDays'] ?? 12;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: GymTheme.peach,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: GymTheme.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT STREAK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: GymTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$streak DAYS',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: GymTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Keep the momentum going',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: GymTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Visual dot progress row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(12, (index) {
                              final bool isActive = index < streak;
                              return Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isActive ? GymTheme.primary : GymTheme.surface.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
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
                const Text(
                  'PERSONAL RECORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: GymTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                // PR Cards Carousel
                progressAsync.when(
                  data: (data) {
                    final prs = (data['personalRecords'] as List?) ?? [
                      {'exerciseName': 'Bench Press', 'maxWeight': 80.0, 'maxReps': 6},
                      {'exerciseName': 'Barbell Squat', 'maxWeight': 120.0, 'maxReps': 5},
                      {'exerciseName': 'Deadlift', 'maxWeight': 150.0, 'maxReps': 3},
                    ];

                    return SizedBox(
                      height: 115,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: prs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final pr = prs[index];
                          final colors = [GymTheme.yellow, GymTheme.lavender, GymTheme.mint, GymTheme.blue];
                          final cardBg = colors[index % colors.length];

                          return Container(
                            width: 165,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  pr['exerciseName'] ?? 'Bench Press',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: GymTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${pr['maxWeight']} kg',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: GymTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${pr['maxReps']} reps',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: GymTheme.textSecondary,
                                  ),
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

  Widget _buildCreateWorkoutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GymTheme.mint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY\'S TRAINING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Workout Day',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your workday name and add your exercises to begin.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GymTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GymTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text(
                'CREATE WORKOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

