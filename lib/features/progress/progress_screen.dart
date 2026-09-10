import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _selectedExercise = 'Bench Press';

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROGRESS & ANALYTICS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(progressOverviewProvider);
        },
        color: GymTheme.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Attendance Section
              const Text(
                'WEEKLY ATTENDANCE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
              ),
              const SizedBox(height: 10),

              progressAsync.when(
                data: (data) {
                  final summary = data['summary'] ?? {};
                  final weekly = (summary['weeklyAttendance'] as List?) ?? [true, true, false, true, true, false, false];
                  final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GymTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GymTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final bool done = i < weekly.length ? (weekly[i] as bool) : false;
                        return Column(
                          children: [
                            Text(days[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted)),
                            const SizedBox(height: 8),
                            Container(
                              height: 36,
                              width: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: done ? GymTheme.primary : GymTheme.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: done ? GymTheme.primary : GymTheme.border),
                              ),
                              child: done
                                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                                  : const Text('—', style: TextStyle(color: GymTheme.textMuted)),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
                loading: () => Container(height: 80, color: GymTheme.surface),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Overview Metrics 3-Column Grid
              progressAsync.when(
                data: (data) {
                  final summary = data['summary'] ?? {};
                  final streak = summary['streakDays'] ?? 12;
                  final totalWorkouts = summary['totalWorkouts'] ?? 48;
                  final totalVolume = (summary['totalVolumeKg'] as num?)?.toDouble() ?? 182450.0;

                  return Row(
                    children: [
                      Expanded(child: _buildMetricCard('STREAK', '$streak Days', 'Current streak', GymTheme.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('WORKOUTS', '$totalWorkouts', 'Total sessions', GymTheme.textPrimary)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('VOLUME', '${(totalVolume / 1000).toStringAsFixed(1)}k kg', 'Lifetime lifted', GymTheme.secondary)),
                    ],
                  );
                },
                loading: () => Container(height: 90, color: GymTheme.surface),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),

              // Strength Progress Line Chart Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STRENGTH PROGRESS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
                  ),
                  DropdownButton<String>(
                    value: _selectedExercise,
                    dropdownColor: GymTheme.surface,
                    style: const TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    underline: const SizedBox(),
                    items: ['Bench Press', 'Barbell Back Squats', 'Deadlift', 'Overhead Press']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExercise = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Chart Container
              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                decoration: BoxDecoration(
                  color: GymTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GymTheme.border),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: GymTheme.border, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            int index = val.toInt();
                            if (index >= 0 && index < months.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(months[index], style: const TextStyle(color: GymTheme.textMuted, fontSize: 11)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 50),
                          FlSpot(1, 60),
                          FlSpot(2, 65),
                          FlSpot(3, 72.5),
                          FlSpot(4, 80),
                        ],
                        isCurved: true,
                        color: GymTheme.primary,
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: GymTheme.primary.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Personal Records Section
              const Text(
                'PERSONAL RECORDS (PRs)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
              ),
              const SizedBox(height: 12),

              progressAsync.when(
                data: (data) {
                  final prs = (data['personalRecords'] as List?) ?? [];
                  return Column(
                    children: prs.map((pr) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: GymTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GymTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: GymTheme.primaryGlow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.emoji_events, color: GymTheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pr['exerciseName'] ?? 'Bench Press',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GymTheme.textPrimary),
                                    ),
                                    const Text('Heaviest load achieved', style: TextStyle(fontSize: 11, color: GymTheme.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${pr['maxWeight']} kg × ${pr['maxReps']}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: GymTheme.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => Container(height: 100, color: GymTheme.surface),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GymTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: GymTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 10, color: GymTheme.textMuted)),
        ],
      ),
    );
  }
}
