import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _selectedMuscleGroup = '';

  final _groups = ['', 'Chest', 'Back', 'Legs', 'Shoulders', 'Biceps', 'Triceps', 'Abs'];

  void _showAddCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController(text: 'Chest');
    final equipCtrl = TextEditingController(text: 'Barbell');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Custom Exercise', style: TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Exercise Name', labelStyle: TextStyle(color: GymTheme.textSecondary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: groupCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Muscle Group (e.g. Chest, Calves)', labelStyle: TextStyle(color: GymTheme.textSecondary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: equipCtrl,
              style: const TextStyle(color: GymTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Equipment (e.g. Dumbbell)', labelStyle: TextStyle(color: GymTheme.textSecondary)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: GymTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final api = ref.read(apiClientProvider);
                await api.createExercise(
                  name: nameCtrl.text.trim(),
                  muscleGroup: groupCtrl.text.trim().isEmpty ? 'General' : groupCtrl.text.trim(),
                  equipment: equipCtrl.text.trim().isEmpty ? 'Barbell' : equipCtrl.text.trim(),
                );
                ref.invalidate(exercisesProvider);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: GymTheme.primary, foregroundColor: Colors.black),
            child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXERCISE LIBRARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: GymTheme.primary),
            onPressed: _showAddCustomExerciseDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Muscle Groups Chips
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final g = _groups[index];
                final isSelected = g == _selectedMuscleGroup;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(g.isEmpty ? 'All Muscles' : g),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscleGroup = g;
                      });
                      ref.read(exerciseFilterProvider.notifier).state = g;
                    },
                    selectedColor: GymTheme.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: GymTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : GymTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? GymTheme.primary : GymTheme.border),
                    ),
                  ),
                );
              },
            ),
          ),

          // Exercises List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(exercisesProvider);
              },
              color: GymTheme.primary,
              backgroundColor: GymTheme.surface,
              child: exercisesAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No exercises found', style: TextStyle(color: GymTheme.textMuted))),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final ex = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: GymTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GymTheme.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: GymTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fitness_center, color: GymTheme.primary, size: 20),
                          ),
                          title: Text(
                            ex['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GymTheme.textPrimary),
                          ),
                          subtitle: Text(
                            '${ex['muscle_group'] ?? ex['muscleGroup']} • ${ex['equipment']}',
                            style: const TextStyle(fontSize: 12, color: GymTheme.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: GymTheme.textMuted, size: 18),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: GymTheme.primary)),
                error: (_, __) => const Center(child: Text('Error loading exercises', style: TextStyle(color: GymTheme.danger))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
