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
                    const SizedBox(height: 16),

                    // Server API Base URL Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GymTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GymTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: GymTheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.dns_rounded,
                                  color: GymTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Server API Base URL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: GymTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ref.watch(serverUrlProvider),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: GymTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: () => _showBaseUrlModal(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: GymTheme.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16, color: GymTheme.textPrimary),
                              label: const Text(
                                'CHANGE SERVER IP / URL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  color: GymTheme.textPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  void _showBaseUrlModal(BuildContext context) {
    final currentUrl = ref.read(serverUrlProvider);
    final controller = TextEditingController(text: currentUrl);
    bool isTesting = false;
    bool? testSuccess;
    String? testMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> testConnection() async {
              setModalState(() {
                isTesting = true;
                testSuccess = null;
                testMessage = null;
              });

              final ok = await ref
                  .read(serverUrlProvider.notifier)
                  .testConnection(controller.text);

              setModalState(() {
                isTesting = false;
                testSuccess = ok;
                testMessage = ok
                    ? 'Connected successfully to backend server!'
                    : 'Could not connect. Ensure server is running on network IP.';
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: GymTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GymTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Configure Server Base URL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: GymTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set local network IP (e.g. 10.5.51.191:3001) or localhost URL:',
                        style: TextStyle(
                          fontSize: 13,
                          color: GymTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                          color: GymTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Server Base URL',
                          hintText: 'e.g. http://10.5.51.191:3001',
                          prefixIcon: const Icon(Icons.link, color: GymTheme.primary),
                          filled: true,
                          fillColor: GymTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: GymTheme.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick IP Presets
                      const Text(
                        'Quick Presets:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GymTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'http://127.0.0.1:3001',
                          'http://10.0.2.2:3001',
                          'http://10.5.51.191:3001',
                        ].map((ip) {
                          final isSelected = controller.text == ip;
                          return ChoiceChip(
                            label: Text(
                              ip,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : GymTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: GymTheme.primary,
                            backgroundColor: GymTheme.background,
                            onSelected: (_) {
                              setModalState(() {
                                controller.text = ip;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      if (testMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: testSuccess == true
                                ? GymTheme.primary.withValues(alpha: 0.15)
                                : GymTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            testMessage!,
                            style: TextStyle(
                              color: testSuccess == true
                                  ? GymTheme.primary
                                  : GymTheme.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isTesting ? null : testConnection,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: isTesting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.wifi_tethering, size: 18),
                              label: const Text('TEST API', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final newUrl = controller.text.trim();
                                if (newUrl.isNotEmpty) {
                                  await ref
                                      .read(serverUrlProvider.notifier)
                                      .setUrl(newUrl);
                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Server Base URL updated to ${ref.read(serverUrlProvider)}'),
                                        backgroundColor: GymTheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GymTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('SAVE URL', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
