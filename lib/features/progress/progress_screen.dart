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
  String _selectedTimeFrame = '3M';

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressOverviewProvider);

    return Scaffold(
      backgroundColor: GymTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
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
                // Header
                const Text(
                  'ANALYTICS & STATISTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: GymTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Based on your logs',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: GymTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Main Overview Statistics Grid
                progressAsync.when(
                  data: (data) {
                    final summary = data['summary'] ?? {};
                    final streak = summary['streakDays'] ?? 12;
                    final totalWorkouts = summary['totalWorkouts'] ?? 48;
                    final totalVolume = (summary['totalVolumeKg'] as num?)?.toDouble() ?? 182450.0;

                    return Column(
                      children: [
                        // Large Featured Workout Count Card (Periwinkle #C5C6F6)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: GymTheme.periwinkle,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: GymTheme.periwinkle.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL WORKOUTS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: GymTheme.textPrimary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalWorkouts',
                                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: GymTheme.textPrimary, height: 1.0),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Consistent dedication',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GymTheme.textSecondary.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: GymTheme.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: GymTheme.textPrimary, size: 22),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2-Column Split Stat Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: GymTheme.peach,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT STREAK',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textPrimary.withValues(alpha: 0.6)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$streak DAYS',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: GymTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: GymTheme.yellow,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL VOLUME',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textPrimary.withValues(alpha: 0.6)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${(totalVolume / 1000).toStringAsFixed(0)}K KG',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: GymTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Container(height: 140, decoration: BoxDecoration(color: GymTheme.periwinkle, borderRadius: BorderRadius.circular(28))),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 28),

                // Strength Graph Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STRENGTH GRAPH',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
                    ),
                    DropdownButton<String>(
                      value: _selectedExercise,
                      dropdownColor: GymTheme.surface,
                      style: const TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                      underline: const SizedBox(),
                      items: ['Bench Press', 'Barbell Squat', 'Deadlift', 'Overhead Press']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExercise = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time Range Selector Pills (1M, 3M, 6M, 1Y)
                Row(
                  children: ['1M', '3M', '6M', '1Y'].map((timeFrame) {
                    final bool isSelected = _selectedTimeFrame == timeFrame;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeFrame = timeFrame),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? GymTheme.primary : GymTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? GymTheme.primary : GymTheme.border),
                        ),
                        child: Text(
                          timeFrame,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : GymTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Line Chart Container
                Container(
                  height: 200,
                  padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(color: GymTheme.border, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              if (val % 1 != 0) return const SizedBox.shrink();
                              final months = ['AUG', 'SEP', 'OCT', 'NOV'];
                              int index = val.toInt();
                              if (index >= 0 && index < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(months[index], style: const TextStyle(color: GymTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
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
                            FlSpot(2, 70),
                            FlSpot(3, 80),
                          ],
                          isCurved: true,
                          color: GymTheme.primary,
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: GymTheme.mint.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Weekly Volume Graph
                const Text(
                  'WEEKLY VOLUME',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
                ),
                const SizedBox(height: 12),

                Container(
                  height: 180,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              if (val % 1 != 0) return const SizedBox.shrink();
                              final weeks = ['W1', 'W2', 'W3', 'W4', 'W5'];
                              int index = val.toInt();
                              if (index >= 0 && index < weeks.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(weeks[index], style: const TextStyle(color: GymTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _buildBarGroup(0, 12),
                        _buildBarGroup(1, 16),
                        _buildBarGroup(2, 14),
                        _buildBarGroup(3, 22),
                        _buildBarGroup(4, 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Personal Records Section
                const Text(
                  'PERSONAL RECORDS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
                ),
                const SizedBox(height: 12),

                Column(
                  children: [
                    _buildPrCard('Bench Press', '80 kg × 6', GymTheme.mint),
                    _buildPrCard('Squat', '120 kg × 5', GymTheme.peach),
                    _buildPrCard('Deadlift', '150 kg × 3', GymTheme.yellow),
                  ],
                ),
                const SizedBox(height: 28),

                // Workout History Timeline
                const Text(
                  'WORKOUT HISTORY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.textMuted),
                ),
                const SizedBox(height: 12),

                Column(
                  children: [
                    _buildHistoryItem('TODAY', 'Chest + Triceps', '18 sets · 4,820 kg', GymTheme.mint),
                    _buildHistoryItem('SEP 8', 'Back + Biceps', '16 sets · 4,200 kg', GymTheme.periwinkle),
                    _buildHistoryItem('SEP 6', 'Legs', '20 sets · 5,100 kg', GymTheme.peach),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: GymTheme.blue,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildPrCard(String exercise, String record, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('PR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: GymTheme.textPrimary)),
              ),
              const SizedBox(width: 14),
              Text(
                exercise,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: GymTheme.textPrimary),
              ),
            ],
          ),
          Text(
            record,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: GymTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: GymTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: GymTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GymTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

