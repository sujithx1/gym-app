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
  String _unit = 'kg';
  final String _theme = 'Light';
  bool _restTimer = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final progressAsync = ref.watch(progressOverviewProvider);

    return Scaffold(
      backgroundColor: GymTheme.background,
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: GymTheme.textPrimary, letterSpacing: -0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header User Name
            Text(
              authState.username ?? 'Sujith',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: GymTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),

            // Top Stats Summary Cards
            progressAsync.when(
              data: (data) {
                final summary = data['summary'] ?? {};
                final workouts = summary['totalWorkouts'] ?? 48;
                final streak = summary['streakDays'] ?? 12;
                final volume = (summary['totalVolumeKg'] as num?)?.toDouble() ?? 182450.0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('$workouts', 'Workouts'),
                      Container(height: 32, width: 1, color: GymTheme.border),
                      _buildStatColumn('$streak Days', 'Streak'),
                      Container(height: 32, width: 1, color: GymTheme.border),
                      _buildStatColumn('${(volume / 1000).toStringAsFixed(0)}K kg', 'Volume'),
                    ],
                  ),
                );
              },
              loading: () => Container(height: 80, decoration: BoxDecoration(color: GymTheme.surface, borderRadius: BorderRadius.circular(24))),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            const Divider(color: GymTheme.border, height: 1),
            const SizedBox(height: 24),

            // Settings Options Container
            Container(
              decoration: BoxDecoration(
                color: GymTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: GymTheme.border),
              ),
              child: Column(
                children: [
                  // Units Setting
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: const Text('Units', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GymTheme.textPrimary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: GymTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GymTheme.border),
                      ),
                      child: DropdownButton<String>(
                        value: _unit,
                        underline: const SizedBox(),
                        dropdownColor: GymTheme.surface,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: GymTheme.textPrimary),
                        items: ['kg', 'lbs'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                  ),
                  const Divider(color: GymTheme.border, height: 1),

                  // Theme Setting
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GymTheme.textPrimary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: GymTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GymTheme.border),
                      ),
                      child: Text(
                        _theme,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: GymTheme.textPrimary),
                      ),
                    ),
                  ),
                  const Divider(color: GymTheme.border, height: 1),

                  // Rest Timer Setting
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: const Text('Rest Timer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GymTheme.textPrimary)),
                    subtitle: const Text('Auto start timer between sets', style: TextStyle(fontSize: 12, color: GymTheme.textSecondary)),
                    value: _restTimer,
                    activeTrackColor: GymTheme.primary,
                    onChanged: (val) => setState(() => _restTimer = val),
                  ),
                  const Divider(color: GymTheme.border, height: 1),

                  // Notifications Setting
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GymTheme.textPrimary)),
                    subtitle: const Text('Daily workout reminders', style: TextStyle(fontSize: 12, color: GymTheme.textSecondary)),
                    value: _notifications,
                    activeTrackColor: GymTheme.primary,
                    onChanged: (val) => setState(() => _notifications = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Divider(color: GymTheme.border, height: 1),
            const SizedBox(height: 24),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GymTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'LOGOUT',
                  style: TextStyle(color: GymTheme.danger, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GymTheme.textPrimary),
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


