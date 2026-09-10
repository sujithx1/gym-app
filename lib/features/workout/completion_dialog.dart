import 'package:flutter/material.dart';
import '../../core/theme/gym_theme.dart';

class CompletionDialog extends StatelessWidget {
  final Map<String, dynamic> summary;

  const CompletionDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final name = summary['name'] ?? 'Chest + Triceps';
    final totalVolumeKg = (summary['totalVolumeKg'] as num?)?.toDouble() ?? 4820.0;
    final durationMinutes = summary['durationMinutes'] ?? 52;
    final totalSetsCompleted = summary['totalSetsCompleted'] ?? 18;
    final volumeDeltaKg = (summary['volumeDeltaKg'] as num?)?.toDouble() ?? 320.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: const BoxDecoration(
        color: GymTheme.mint,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large Soft Checkmark Badge
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: GymTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'WORKOUT COMPLETE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name.toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GymTheme.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 28),

          // Core Stats Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: GymTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GymTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('$totalSetsCompleted', 'sets'),
                    Container(height: 32, width: 1, color: GymTheme.border),
                    _buildStatCol('${totalVolumeKg.toInt()} kg', 'volume'),
                    Container(height: 32, width: 1, color: GymTheme.border),
                    _buildStatCol('$durationMinutes min', 'duration'),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: GymTheme.border, height: 1),
                const SizedBox(height: 16),

                // Volume Delta Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.north_east_rounded, color: GymTheme.textPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '↑ ${volumeDeltaKg.toInt()} kg vs previous workout',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: GymTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Close Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.pop(context); // Return to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GymTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: GymTheme.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GymTheme.textSecondary),
        ),
      ],
    );
  }
}

