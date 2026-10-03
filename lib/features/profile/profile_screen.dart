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
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      backgroundColor: GymTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              const Text(
                'ACCOUNT & PREFERENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: GymTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authState.username ?? 'Sujith',
                style: const TextStyle(
                  fontSize: 30,
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
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: GymTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: GymTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('$workouts', 'Workouts'),
                        Container(height: 36, width: 1, color: GymTheme.border),
                        _buildStatColumn('$streak Days', 'Streak'),
                        Container(height: 36, width: 1, color: GymTheme.border),
                        _buildStatColumn('${(volume / 1000).toStringAsFixed(0)}K kg', 'Volume'),
                      ],
                    ),
                  );
                },
                loading: () => Container(height: 80, decoration: BoxDecoration(color: GymTheme.surface, borderRadius: BorderRadius.circular(28))),
                error: (_, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),

              // --- DATABASE SYNC SECTION ---
              const Text(
                'DATABASE & STORAGE',
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: syncState.pendingCount > 0
                        ? GymTheme.warning.withValues(alpha: 0.5)
                        : GymTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: syncState.pendingCount > 0
                                ? GymTheme.warning.withValues(alpha: 0.15)
                                : GymTheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            syncState.pendingCount > 0
                                ? Icons.cloud_upload_outlined
                                : Icons.cloud_done_rounded,
                            color: syncState.pendingCount > 0
                                ? GymTheme.warning
                                : GymTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Local Data Sync',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: GymTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                syncState.pendingCount > 0
                                    ? '${syncState.pendingCount} offline changes waiting to sync'
                                    : 'All offline data is synced with backend server',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: syncState.pendingCount > 0
                                      ? GymTheme.warning
                                      : GymTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: syncState.isSyncing
                            ? null
                            : () async {
                                final res = await ref.read(syncProvider.notifier).performSync();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? 'Sync operation completed.',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      backgroundColor: res['success'] == true
                                          ? GymTheme.primary
                                          : GymTheme.warning,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GymTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: syncState.isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.sync, size: 20),
                        label: Text(
                          syncState.isSyncing ? 'SYNCING...' : 'SYNC DB NOW',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: GymTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              // Settings Options Container
              Container(
                decoration: BoxDecoration(
                  color: GymTheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: GymTheme.border),
                ),
                child: Column(
                  children: [
                    // Units Setting
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: const Text('Units', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GymTheme.textPrimary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              const SizedBox(height: 28),

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
