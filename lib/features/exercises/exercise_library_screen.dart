import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/treadmill_loading.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _selectedMuscleGroup = '';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final _groups = [
    '',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Abs',
  ];

  void _showAddCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController(text: 'Chest');
    final equipCtrl = TextEditingController(text: 'Barbell');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'Create New Exercise',
          style: TextStyle(
            color: GymTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                labelStyle: const TextStyle(color: GymTheme.textSecondary),
                filled: true,
                fillColor: GymTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: groupCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Muscle Group (e.g. Chest)',
                labelStyle: const TextStyle(color: GymTheme.textSecondary),
                filled: true,
                fillColor: GymTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: equipCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Equipment (e.g. Dumbbell)',
                labelStyle: const TextStyle(color: GymTheme.textSecondary),
                filled: true,
                fillColor: GymTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: GymTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final api = ref.read(apiClientProvider);
                await api.createExercise(
                  name: nameCtrl.text.trim(),
                  muscleGroup: groupCtrl.text.trim().isEmpty
                      ? 'General'
                      : groupCtrl.text.trim(),
                  equipment: equipCtrl.text.trim().isEmpty
                      ? 'Barbell'
                      : equipCtrl.text.trim(),
                );
                ref.invalidate(exercisesProvider);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GymTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'CREATE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: GymTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PRACTICES & MOVEMENTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: GymTheme.textMuted,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Exercise Library',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: GymTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showAddCustomExerciseDialog,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GymTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GymTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: GymTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GymTheme.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                  style: const TextStyle(
                    color: GymTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search movements or muscle group...',
                    hintStyle: TextStyle(
                      color: GymTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: GymTheme.textSecondary.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Muscle Filter Chips (Pastel Styled)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final g = _groups[index];
                  final isSelected = g == _selectedMuscleGroup;
                  final colors = [
                    GymTheme.periwinkle,
                    GymTheme.yellow,
                    GymTheme.mint,
                    GymTheme.peach,
                    GymTheme.lavender,
                  ];
                  final chipColor = isSelected
                      ? GymTheme.primary
                      : colors[index % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMuscleGroup = g;
                        });
                        ref.read(exerciseFilterProvider.notifier).state = g;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          g.isEmpty ? 'All Muscles' : g,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : GymTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Exercises List
            Expanded(
              child: TreadmillRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(exercisesProvider);
                },
                child: exercisesAsync.when(
                  data: (list) {
                    var filtered = list;
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((ex) {
                        final name = (ex['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final group =
                            (ex['muscle_group'] ?? ex['muscleGroup'] ?? '')
                                .toString()
                                .toLowerCase();
                        return name.contains(_searchQuery) ||
                            group.contains(_searchQuery);
                      }).toList();
                    }

                    if (filtered.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'No exercises match your filter',
                              style: TextStyle(
                                color: GymTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        final colors = [
                          GymTheme.mint,
                          GymTheme.periwinkle,
                          GymTheme.yellow,
                          GymTheme.peach,
                          GymTheme.lavender,
                        ];
                        final badgeColor = colors[index % colors.length];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: GymTheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: GymTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: GymTheme.textPrimary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              ex['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: GymTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${ex['muscle_group'] ?? ex['muscleGroup']} • ${ex['equipment']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GymTheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            trailing: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: GymTheme.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                size: 16,
                                color: GymTheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: TreadmillLoadingIndicator(
                      message: 'Loading exercise library...',
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text(
                      'Error loading exercises',
                      style: TextStyle(color: GymTheme.danger),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
