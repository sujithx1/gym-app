import 'package:flutter/material.dart';
import '../../core/theme/gym_theme.dart';

class CompletionDialog extends StatelessWidget {
  final Map<String, dynamic> summary;

  const CompletionDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final name = summary['name'] ?? 'Chest Day';
    final totalVolumeKg = (summary['totalVolumeKg'] as num?)?.toDouble() ?? 4820.0;
    final durationMinutes = summary['durationMinutes'] ?? 52;
    final totalSetsCompleted = summary['totalSetsCompleted'] ?? 15;
    final volumeDeltaKg = (summary['volumeDeltaKg'] as num?)?.toDouble() ?? 320.0;
    final message = summary['message'] ?? 'Great session!';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GymTheme.primaryGlow,
              shape: BoxShape.circle,
              border: Border.all(color: GymTheme.primary, width: 2),
            ),
            child: const Icon(Icons.celebration, size: 48, color: GymTheme.primary),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'WORKOUT COMPLETE 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GymTheme.primary),
          ),
          const SizedBox(height: 24),

          // Stats Summary Grid
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GymTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GymTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('$totalSetsCompleted', 'Sets Done', Icons.layers),
                    Container(height: 36, width: 1, color: GymTheme.border),
                    _buildStatCol('${totalVolumeKg.toInt()} kg', 'Total Volume', Icons.fitness_center),
                    Container(height: 36, width: 1, color: GymTheme.border),
                    _buildStatCol('$durationMinutes min', 'Duration', Icons.access_time),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: GymTheme.border, height: 1),
                const SizedBox(height: 14),

                // Volume Delta Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      volumeDeltaKg >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: volumeDeltaKg >= 0 ? GymTheme.primary : GymTheme.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      volumeDeltaKg >= 0
                          ? '↑ +${volumeDeltaKg.toInt()} kg vs last session'
                          : '${volumeDeltaKg.toInt()} kg vs last session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: volumeDeltaKg >= 0 ? GymTheme.primary : GymTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Motivation Text
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: GymTheme.textMuted, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 28),

          // Close Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.pop(context); // Return to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GymTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: GymTheme.primary),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: GymTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: GymTheme.textMuted)),
      ],
    );
  }
}
