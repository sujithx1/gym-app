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
    final dateStr = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          'Good day, ${authState.username ?? 'Athlete'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: GymTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: GymTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // User avatar badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GymTheme.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: GymTheme.border),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: GymTheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Streak Banner
                progressAsync.when(
                  data: (data) {
                    final summary = data['summary'] ?? {};
                    final streak = summary['streakDays'] ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: GymTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GymTheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: GymTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$streak Day Streak',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: GymTheme.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Keep momentum building every single workout!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GymTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(height: 60, color: GymTheme.surface),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Today's Scheduled Workout Hero Card
                const Text(
                  "TODAY'S WORKOUT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: GymTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 10),

                todayAsync.when(
                  data: (data) {
                    final today = data['today'];
                    final activeSession = today != null
                        ? today['activeSession']
                        : null;

                    // If no active session exists for today, prompt user to create a workout manually
                    if (today == null || activeSession == null) {
                      return _buildCreateWorkoutPromptCard(context);
                    }

                    final name = today['name'] ?? 'WORKOUT SESSION';
                    final exerciseCount = today['exerciseCount'] ?? 0;
                    final totalSets = today['totalSets'] ?? 0;
                    final estMinutes = today['estimatedMinutes'] ?? 30;

                    return Container(
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: GymTheme.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GymTheme.primary.withOpacity(0.08),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: GymTheme.primaryGlow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activeSession['status'] == 'completed'
                                      ? 'SESSION COMPLETED'
                                      : 'SESSION IN PROGRESS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: GymTheme.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),

                              if (activeSession['status'] == 'completed')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GymTheme.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: GymTheme.success,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'DONE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: GymTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Workout Split Title
                          Text(
                            name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: GymTheme.textPrimary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Metadata Badges (Exercises, Sets, Est duration)
                          Row(
                            children: [
                              _buildMetaBadge(
                                Icons.fitness_center,
                                '$exerciseCount Exercises',
                              ),
                              const SizedBox(width: 12),
                              _buildMetaBadge(Icons.layers, '$totalSets Sets'),
                              const SizedBox(width: 12),
                              _buildMetaBadge(
                                Icons.access_time,
                                '~$estMinutes min',
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Start & Custom Buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TodayWorkoutScreen(
                                                todayData: today,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    label: Text(
                                      activeSession['status'] == 'in_progress'
                                          ? 'CONTINUE WORKOUT'
                                          : 'VIEW WORKOUT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: GymTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateWorkoutScreen(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: GymTheme.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+ NEW',
                                      style: TextStyle(
                                        color: GymTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => _buildSkeletonLoader(),
                  error: (_, __) => _buildCreateWorkoutPromptCard(context),
                ),
                const SizedBox(height: 28),

                // Recent Personal Records Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PERSONAL RECORDS (PRs)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: GymTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // PR Cards Carousel
                progressAsync.when(
                  data: (data) {
                    final prs = (data['personalRecords'] as List?) ?? [];
                    if (prs.isEmpty) return const SizedBox.shrink();

                    return SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: prs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final pr = prs[index];
                          return Container(
                            width: 170,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: GymTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: GymTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: GymTheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        pr['exerciseName'] ?? 'Bench Press',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: GymTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${pr['maxWeight']} kg',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: GymTheme.primary,
                                  ),
                                ),
                                Text(
                                  '× ${pr['maxReps']} reps',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: GymTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 110),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: GymTheme.textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GymTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateWorkoutPromptCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GymTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_task, size: 38, color: GymTheme.primary),
          const SizedBox(height: 12),
          const Text(
            'CREATE TODAY\'S WORKOUT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter which workout day you are doing today and pick your exercises.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: GymTheme.textMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'CREATE WORKOUT',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymTheme.border),
      ),
    );
  }
}
