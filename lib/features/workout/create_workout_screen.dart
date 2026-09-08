import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import 'today_workout_screen.dart';

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  ConsumerState<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _dayNameController = TextEditingController();
  final List<Map<String, dynamic>> _selectedExercises = [];

  @override
  void dispose() {
    _dayNameController.dispose();
    super.dispose();
  }

  void _addCustomExercise(String name, String muscleGroup) async {
    if (name.trim().isEmpty) return;

    final api = ref.read(apiClientProvider);
    final result = await api.createExercise(
      name: name.trim(),
      muscleGroup: muscleGroup.trim().isEmpty ? 'General' : muscleGroup.trim(),
      equipment: 'Custom',
    );

    final exId = result != null && result['id'] != null
        ? result['id']
        : 'ex_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}';

    setState(() {
      _selectedExercises.add({
        'id': exId,
        'name': name.trim(),
        'muscleGroup': muscleGroup.trim().isEmpty ? 'General' : muscleGroup.trim(),
        'equipment': 'Custom',
        'sets': [
          {'setNumber': 1, 'weight': 0.0, 'reps': 0, 'completed': false},
        ],
      });
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _addSetToExercise(int exIndex) {
    setState(() {
      final sets = _selectedExercises[exIndex]['sets'] as List;
      final lastSet = sets.isNotEmpty ? sets.last : {'weight': 0.0, 'reps': 0};
      sets.add({
        'setNumber': sets.length + 1,
        'weight': lastSet['weight'],
        'reps': lastSet['reps'],
        'completed': false,
      });
    });
  }

  void _removeSetFromExercise(int exIndex, int setIndex) {
    setState(() {
      final sets = _selectedExercises[exIndex]['sets'] as List;
      if (sets.length > 1) {
        sets.removeAt(setIndex);
        // renumber remaining sets
        for (int i = 0; i < sets.length; i++) {
          sets[i]['setNumber'] = i + 1;
        }
      }
    });
  }

  void _startCustomWorkout() async {
    final dayName = _dayNameController.text.trim();
    if (dayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout day name (e.g., Chest Day, Leg Day)')),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 exercise')),
      );
      return;
    }

    final api = ref.read(apiClientProvider);
    final sessionId = await api.startSession(null, dayName);

    final workoutData = {
      'name': dayName.toUpperCase(),
      'exerciseCount': _selectedExercises.length,
      'totalSets': _selectedExercises.fold<int>(0, (sum, item) => sum + (item['sets'] as List).length),
      'estimatedMinutes': _selectedExercises.length * 10,
      'exercises': _selectedExercises,
      'activeSession': {
        'id': sessionId,
        'status': 'in_progress',
      },
    };

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodayWorkoutScreen(todayData: workoutData),
        ),
      );
    }
  }

  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final muscleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GymTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'ENTER EXERCISE NAME',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: GymTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exercise Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GymTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. Bench Press, Squat, Bicep Curl',
                  hintStyle: const TextStyle(color: GymTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: GymTheme.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Body Part / Muscle (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GymTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: muscleController,
                style: const TextStyle(color: GymTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Chest, Legs, Arms',
                  hintStyle: const TextStyle(color: GymTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: GymTheme.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GymTheme.primary, width: 1.5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: GymTheme.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _addCustomExercise(nameController.text, muscleController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GymTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ADD EXERCISE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE WORKOUT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Day Name Input
                    const Text(
                      'ENTER WORKDAY NAME',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.primary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dayNameController,
                      style: const TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Enter day name (e.g. Chest Day, Leg Day, Pull Day)',
                        hintStyle: const TextStyle(color: GymTheme.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: GymTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GymTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GymTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GymTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Exercises Header & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WORKOUT EXERCISES',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: GymTheme.primary),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddExerciseDialog,
                          icon: const Icon(Icons.add, size: 18, color: Colors.black),
                          label: const Text('ADD EXERCISE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GymTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selected Exercises List
                    if (_selectedExercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: GymTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GymTheme.border),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.fitness_center, color: GymTheme.textMuted, size: 40),
                            SizedBox(height: 12),
                            Text('No exercises added yet', style: TextStyle(fontWeight: FontWeight.bold, color: GymTheme.textPrimary)),
                            SizedBox(height: 4),
                            Text('Tap "+ ADD EXERCISE" to enter your exercise names manually.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: GymTheme.textMuted)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_selectedExercises.length, (exIndex) {
                        final ex = _selectedExercises[exIndex];
                        final sets = ex['sets'] as List;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: GymTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: GymTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: GymTheme.primaryGlow,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.fitness_center, color: GymTheme.primary, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: GymTheme.textPrimary)),
                                          Text(ex['muscleGroup'], style: const TextStyle(fontSize: 11, color: GymTheme.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: GymTheme.danger, size: 20),
                                    onPressed: () => _removeExercise(exIndex),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: GymTheme.border, height: 1),
                              const SizedBox(height: 8),

                              // Header row for sets
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 50, child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                                    Expanded(child: Text('WEIGHT (KG)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                                    SizedBox(width: 12),
                                    Expanded(child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                                    SizedBox(width: 40),
                                  ],
                                ),
                              ),

                              // Set List
                              ...List.generate(sets.length, (setIndex) {
                                final s = sets[setIndex];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          'Set ${s['setNumber']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: GymTheme.textSecondary, fontSize: 13),
                                        ),
                                      ),
                                      // Weight input
                                      Expanded(
                                        child: SizedBox(
                                          height: 38,
                                          child: TextFormField(
                                            initialValue: s['weight'] == 0.0 ? '' : '${s['weight']}',
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GymTheme.textPrimary),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintText: '0 kg',
                                              hintStyle: const TextStyle(color: GymTheme.textMuted, fontSize: 13),
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: GymTheme.surfaceElevated,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.border)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.border)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.primary)),
                                            ),
                                            onChanged: (val) {
                                              s['weight'] = double.tryParse(val) ?? 0.0;
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Reps input
                                      Expanded(
                                        child: SizedBox(
                                          height: 38,
                                          child: TextFormField(
                                            initialValue: s['reps'] == 0 ? '' : '${s['reps']}',
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GymTheme.textPrimary),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintText: '0 reps',
                                              hintStyle: const TextStyle(color: GymTheme.textMuted, fontSize: 13),
                                              contentPadding: EdgeInsets.zero,
                                              filled: true,
                                              fillColor: GymTheme.surfaceElevated,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.border)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.border)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GymTheme.primary)),
                                            ),
                                            onChanged: (val) {
                                              s['reps'] = int.tryParse(val) ?? 0;
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: GymTheme.textMuted),
                                          onPressed: () => _removeSetFromExercise(exIndex, setIndex),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 6),
                              // Add Set Button
                              TextButton.icon(
                                onPressed: () => _addSetToExercise(exIndex),
                                icon: const Icon(Icons.add, size: 16, color: GymTheme.primary),
                                label: const Text('+ ADD SET MANUALLY', style: TextStyle(color: GymTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Start Workout Button Sticky Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: GymTheme.surface,
                border: Border(top: BorderSide(color: GymTheme.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _startCustomWorkout,
                  icon: const Icon(Icons.play_arrow, color: Colors.black, size: 22),
                  label: const Text(
                    'START WORKOUT',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black, letterSpacing: 1.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

