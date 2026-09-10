import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _useKg = true;
  bool _restTimerEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final progressAsync = ref.watch(progressOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE & SETTINGS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: GymTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: GymTheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(color: GymTheme.primaryGlow, blurRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 44, color: GymTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authState.username ?? 'Sujith',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: GymTheme.textPrimary),
                  ),
                  const Text('Pro Member', style: TextStyle(color: GymTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Workout Stats Card Summary
            progressAsync.when(
              data: (data) {
                final summary = data['summary'] ?? {};
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('${summary['totalWorkouts'] ?? 48}', 'Workouts'),
                      Container(height: 30, width: 1, color: GymTheme.border),
                      _buildProfileStat('${summary['streakDays'] ?? 12}', 'Streak'),
                      Container(height: 30, width: 1, color: GymTheme.border),
                      _buildProfileStat('${((summary['totalVolumeKg'] ?? 182450) / 1000).toStringAsFixed(0)}k kg', 'Volume'),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 28),

            // Settings Options
            Container(
              decoration: BoxDecoration(
                color: GymTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GymTheme.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.balance, color: GymTheme.primary, size: 20),
                    title: const Text('Weight Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GymTheme.textPrimary)),
                    trailing: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('KG')),
                        ButtonSegment(value: false, label: Text('LB')),
                      ],
                      selected: {_useKg},
                      onSelectionChanged: (val) {
                        setState(() => _useKg = val.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected) ? GymTheme.primary : GymTheme.surfaceElevated,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected) ? Colors.black : GymTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: GymTheme.border, height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.timer, color: GymTheme.primary, size: 20),
                    title: const Text('Auto Rest Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GymTheme.textPrimary)),
                    subtitle: const Text('Start timer after completing a set', style: TextStyle(fontSize: 12, color: GymTheme.textMuted)),
                    value: _restTimerEnabled,
                    activeTrackColor: GymTheme.primary,
                    onChanged: (val) => setState(() => _restTimerEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout, color: GymTheme.danger, size: 18),
                label: const Text('LOG OUT', style: TextStyle(color: GymTheme.danger, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GymTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: GymTheme.textMuted)),
      ],
    );
  }
}
