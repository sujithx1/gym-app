import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/treadmill_loading.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  int _selectedTabIndex = 0; // 0 = Logged Days (History), 1 = Routine Days

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final daysAsync = ref.watch(workoutDaysProvider);

    return Scaffold(
      backgroundColor: GymTheme.getBackgroundColor(context),
      body: SafeArea(
        child: TreadmillRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workoutHistoryProvider);
            ref.invalidate(workoutDaysProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: GymTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'WORKOUT TRACKER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: GymTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Workout Days & Weights',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: GymTheme.getTextPrimaryColor(context),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Segmented Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: GymTheme.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GymTheme.getBorderColor(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                title: 'Logged Days',
                                subtitle: 'Weights Lifted',
                                isSelected: _selectedTabIndex == 0,
                                onTap: () => setState(() => _selectedTabIndex = 0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildTabButton(
                                title: 'Routine Split',
                                subtitle: 'Target Weights',
                                isSelected: _selectedTabIndex == 1,
                                onTap: () => setState(() => _selectedTabIndex = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content based on selected tab
              if (_selectedTabIndex == 0)
                ..._buildHistoryList(historyAsync)
              else
                ..._buildRoutineDaysList(daysAsync),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? GymTheme.getPrimaryColor(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GymTheme.getPrimaryColor(context).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                    : GymTheme.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.8))
                    : GymTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: Logged Days with weights taken ---
  List<Widget> _buildHistoryList(AsyncValue<List<dynamic>> historyAsync) {
    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: GymTheme.periwinkle.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          size: 44,
                          color: GymTheme.periwinkleDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Workout Days Logged Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: GymTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Complete a daily workout to see your set-by-set weights recorded here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: GymTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        }

        // Calculate overall stats
        double totalVolume = 0;
        int totalSets = 0;
        for (var s in sessions) {
          totalVolume += (s['totalVolumeKg'] as num?)?.toDouble() ?? 0.0;
          totalSets += (s['totalSets'] as num?)?.toInt() ?? 0;
        }

        return [
          // Summary Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GymTheme.periwinkle,
                      GymTheme.periwinkle.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: GymTheme.periwinkle.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat('${sessions.length}', 'WORKOUT DAYS'),
                    Container(height: 36, width: 1, color: GymTheme.textPrimary.withValues(alpha: 0.2)),
                    _buildSummaryStat('${(totalVolume / 1000).toStringAsFixed(1)}k kg', 'TOTAL VOLUME'),
                    Container(height: 36, width: 1, color: GymTheme.textPrimary.withValues(alpha: 0.2)),
                    _buildSummaryStat('$totalSets', 'SETS COMPLETED'),
                  ],
                ),
              ),
            ),
          ),

          // Timeline List of Sessions
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = sessions[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _WorkoutSessionDayCard(session: session),
                );
              },
              childCount: sessions.length,
            ),
          ),
        ];
      },
      loading: () => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TreadmillLoadingIndicator(message: 'Loading workout days...'),
          ),
        ),
      ],
      error: (err, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Failed to load history: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: GymTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: GymTheme.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: Routine Split Days ---
  List<Widget> _buildRoutineDaysList(AsyncValue<List<dynamic>> daysAsync) {
    return daysAsync.when(
      data: (days) {
        if (days.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No active workout days found.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: GymTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ),
              ),
            ),
          ];
        }

        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final day = days[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _RoutineDayCard(day: day),
                );
              },
              childCount: days.length,
            ),
          ),
        ];
      },
      loading: () => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TreadmillLoadingIndicator(message: 'Loading routine split...'),
          ),
        ),
      ],
      error: (err, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Failed to load split: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Card 1: Completed Workout Session Day Card
// ==========================================
class _WorkoutSessionDayCard extends StatefulWidget {
  final Map<String, dynamic> session;

  const _WorkoutSessionDayCard({required this.session});

  @override
  State<_WorkoutSessionDayCard> createState() => _WorkoutSessionDayCardState();
}

class _WorkoutSessionDayCardState extends State<_WorkoutSessionDayCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final name = session['name'] ?? 'Workout Session';
    final formattedDate = session['formattedDate'] ?? 'Recently';
    final duration = session['durationMinutes'] ?? 0;
    final volume = (session['totalVolumeKg'] as num?)?.toDouble() ?? 0.0;
    final totalSets = session['totalSets'] ?? 0;
    final exercises = (session['exercises'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: GymTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GymTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GymTheme.mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formattedDate.toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: GymTheme.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: GymTheme.getTextSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$duration min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GymTheme.getTextSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: GymTheme.getTextSecondaryColor(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: GymTheme.getTextPrimaryColor(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stats Badges
                  Row(
                    children: [
                      _buildChip(
                        context,
                        icon: Icons.fitness_center_rounded,
                        text: '${volume.toInt()} kg volume',
                        bgColor: GymTheme.peach.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        context,
                        icon: Icons.check_circle_outline_rounded,
                        text: '$totalSets sets',
                        bgColor: GymTheme.yellow.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        context,
                        icon: Icons.list_alt_rounded,
                        text: '${exercises.length} exercises',
                        bgColor: GymTheme.periwinkle.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Exercise Breakdown List
          if (_isExpanded && exercises.isNotEmpty) ...[
            Divider(height: 1, color: GymTheme.getBorderColor(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXERCISES & WEIGHTS TAKEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: GymTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...exercises.map((ex) => _buildExerciseRow(context, ex)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required IconData icon, required String text, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: GymTheme.textPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: GymTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(BuildContext context, Map<String, dynamic> ex) {
    final exName = ex['exerciseName'] ?? 'Exercise';
    final muscle = ex['muscleGroup'] ?? 'General';
    final maxWeight = (ex['maxWeight'] as num?)?.toDouble() ?? 0.0;
    final setsList = (ex['sets'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GymTheme.getBorderColor(context).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      exName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: GymTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: GymTheme.lavender,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        muscle,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: GymTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (maxWeight > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GymTheme.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Peak: ${maxWeight.toStringAsFixed(maxWeight % 1 == 0 ? 0 : 1)} kg',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: GymTheme.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Wrap of Sets with Weights
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: setsList.map((s) {
              final setNum = s['setNumber'] ?? 1;
              final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;
              final reps = s['reps'] ?? 0;
              final weightStr = weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GymTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GymTheme.getBorderColor(context)),
                ),
                child: Text(
                  'Set $setNum: $weightStr kg × $reps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: GymTheme.getTextPrimaryColor(context),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Card 2: Planned Routine Split Day Card
// ==========================================
class _RoutineDayCard extends StatefulWidget {
  final Map<String, dynamic> day;

  const _RoutineDayCard({required this.day});

  @override
  State<_RoutineDayCard> createState() => _RoutineDayCardState();
}

class _RoutineDayCardState extends State<_RoutineDayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dayName = day['dayName'] ?? 'Day';
    final name = day['name'] ?? 'Rest Day';
    final exercises = (day['exercises'] as List<dynamic>?) ?? [];
    final isRest = exercises.isEmpty || name.toLowerCase().contains('rest');

    return Container(
      decoration: BoxDecoration(
        color: GymTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GymTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (exercises.isNotEmpty) {
                setState(() => _isExpanded = !_isExpanded);
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isRest ? GymTheme.lavender : GymTheme.periwinkle,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isRest ? Icons.nightlight_round : Icons.fitness_center_rounded,
                      color: GymTheme.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: GymTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: GymTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        if (!isRest)
                          Text(
                            '${exercises.length} planned exercises',
                            style: const TextStyle(fontSize: 12, color: GymTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                  if (exercises.isNotEmpty)
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: GymTheme.getTextSecondaryColor(context),
                    ),
                ],
              ),
            ),
          ),

          if (_isExpanded && exercises.isNotEmpty) ...[
            Divider(height: 1, color: GymTheme.getBorderColor(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: exercises.map((ex) {
                  final exName = ex['name'] ?? 'Exercise';
                  final targetSets = ex['targetSets'] ?? 3;
                  final targetReps = ex['targetReps'] ?? 10;
                  final targetWeight = (ex['targetWeight'] as num?)?.toDouble() ?? 0.0;
                  final maxLast = (ex['maxLastWeight'] as num?)?.toDouble();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: GymTheme.getTextPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target: $targetSets sets × $targetReps reps @ ${targetWeight.toInt()} kg',
                              style: const TextStyle(fontSize: 11, color: GymTheme.textMuted),
                            ),
                          ],
                        ),
                        if (maxLast != null && maxLast > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: GymTheme.mint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Last: ${maxLast.toInt()} kg',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: GymTheme.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
