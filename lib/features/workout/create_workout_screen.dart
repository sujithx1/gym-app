import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import 'today_workout_screen.dart';

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  ConsumerState<CreateWorkoutScreen> createState() =>
      _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _dayNameController = TextEditingController();
  final List<Map<String, dynamic>> _selectedExercises = [];
  bool _isStarting = false;

  static const _muscleOptions = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Abs',
    'Cardio',
  ];

  static const _daySuggestions = [
    'Push Day',
    'Pull Day',
    'Leg Day',
    'Upper Body',
    'Full Body',
  ];

  static const _badgeColors = [
    GymTheme.mint,
    GymTheme.periwinkle,
    GymTheme.yellow,
    GymTheme.peach,
    GymTheme.lavender,
  ];

  @override
  void dispose() {
    _dayNameController.dispose();
    super.dispose();
  }

  int get _totalSets => _selectedExercises.fold<int>(
    0,
    (sum, item) => sum + (item['sets'] as List).length,
  );

  void _addExerciseFromLibrary(Map<String, dynamic> exercise) {
    final id = exercise['id']?.toString() ?? '';
    final alreadyAdded = _selectedExercises.any((e) => e['id'] == id);
    if (alreadyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise['name']} is already in this workout'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GymTheme.primary,
        ),
      );
      return;
    }

    setState(() {
      _selectedExercises.add({
        'id': id,
        'name': exercise['name'] ?? '',
        'muscleGroup':
            exercise['muscle_group'] ?? exercise['muscleGroup'] ?? 'General',
        'equipment': exercise['equipment'] ?? 'Barbell',
        'sets': [
          {'setNumber': 1, 'weight': 0.0, 'reps': 0, 'completed': false},
          {'setNumber': 2, 'weight': 0.0, 'reps': 0, 'completed': false},
          {'setNumber': 3, 'weight': 0.0, 'reps': 0, 'completed': false},
        ],
      });
    });
  }

  Future<void> _addCustomExercise(String name, String muscleGroup) async {
    if (name.trim().isEmpty) return;

    final api = ref.read(apiClientProvider);
    final result = await api.createExercise(
      name: name.trim(),
      muscleGroup: muscleGroup,
      equipment: 'Custom',
    );

    final exId = result != null && result['id'] != null
        ? result['id']
        : 'ex_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}';

    if (!mounted) return;
    setState(() {
      _selectedExercises.add({
        'id': exId,
        'name': name.trim(),
        'muscleGroup': muscleGroup,
        'equipment': 'Custom',
        'sets': [
          {'setNumber': 1, 'weight': 0.0, 'reps': 0, 'completed': false},
          {'setNumber': 2, 'weight': 0.0, 'reps': 0, 'completed': false},
          {'setNumber': 3, 'weight': 0.0, 'reps': 0, 'completed': false},
        ],
      });
    });
    ref.invalidate(exercisesProvider);
  }

  void _removeExercise(int index) {
    setState(() => _selectedExercises.removeAt(index));
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
        for (int i = 0; i < sets.length; i++) {
          sets[i]['setNumber'] = i + 1;
        }
      }
    });
  }

  Future<void> _startCustomWorkout() async {
    final dayName = _dayNameController.text.trim();
    if (dayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this day a name first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GymTheme.primary,
        ),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GymTheme.primary,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final api = ref.read(apiClientProvider);
    final sessionId = await api.startSession(null, dayName);

    final workoutData = {
      'name': dayName.toUpperCase(),
      'exerciseCount': _selectedExercises.length,
      'totalSets': _totalSets,
      'estimatedMinutes': _selectedExercises.length * 10,
      'exercises': _selectedExercises,
      'activeSession': {'id': sessionId, 'status': 'in_progress'},
    };

    if (!mounted) return;
    setState(() => _isStarting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TodayWorkoutScreen(todayData: workoutData),
      ),
    );
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddExerciseSheet(
          muscleOptions: _muscleOptions,
          selectedIds: _selectedExercises
              .map((e) => e['id']?.toString() ?? '')
              .toSet(),
          onPickFromLibrary: (ex) {
            Navigator.pop(sheetContext);
            _addExerciseFromLibrary(ex);
          },
          onCreateCustom: (name, muscle) async {
            Navigator.pop(sheetContext);
            await _addCustomExercise(name, muscle);
          },
        );
      },
    );
  }

  InputDecoration _setFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: GymTheme.textMuted.withValues(alpha: 0.7),
        fontSize: 13,
      ),
      contentPadding: EdgeInsets.zero,
      filled: true,
      fillColor: GymTheme.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GymTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GymTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GymTheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: GymTheme.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUILD YOUR SESSION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: GymTheme.textMuted,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Create Workout',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: GymTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedExercises.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GymTheme.periwinkle,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedExercises.length} ex · $_totalSets sets',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: GymTheme.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day name
                    const Text(
                      'WORKOUT NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: GymTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _dayNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: GymTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Chest Day, Pull Day',
                        hintStyle: TextStyle(
                          color: GymTheme.textMuted.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_calendar_rounded,
                          color: GymTheme.textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: GymTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: GymTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: GymTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: GymTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _daySuggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final suggestion = _daySuggestions[index];
                          final isActive =
                              _dayNameController.text.trim() == suggestion;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _dayNameController.text = suggestion;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? GymTheme.primary
                                    : _badgeColors[index % _badgeColors.length],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : GymTheme.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Exercises header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'EXERCISES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: GymTheme.textMuted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAddExerciseSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: GymTheme.primary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: GymTheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_selectedExercises.isEmpty)
                      _EmptyExercisesState(onAdd: _showAddExerciseSheet)
                    else
                      ...List.generate(_selectedExercises.length, (exIndex) {
                        return _ExerciseCard(
                          exercise: _selectedExercises[exIndex],
                          badgeColor:
                              _badgeColors[exIndex % _badgeColors.length],
                          setFieldDecoration: _setFieldDecoration,
                          onRemove: () => _removeExercise(exIndex),
                          onAddSet: () => _addSetToExercise(exIndex),
                          onRemoveSet: (setIndex) =>
                              _removeSetFromExercise(exIndex, setIndex),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Sticky footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: GymTheme.surface.withValues(alpha: 0.96),
                border: const Border(top: BorderSide(color: GymTheme.border)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isStarting ? null : _startCustomWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GymTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: GymTheme.primary.withValues(
                        alpha: 0.5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isStarting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 24),
                              const SizedBox(width: 6),
                              Text(
                                _selectedExercises.isEmpty
                                    ? 'START WORKOUT'
                                    : 'START · ${_selectedExercises.length} EXERCISES',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
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

class _EmptyExercisesState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExercisesState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GymTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GymTheme.periwinkle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: GymTheme.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No exercises yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: GymTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick from your library or create a custom movement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GymTheme.textSecondary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: GymTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Browse exercises',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final Color badgeColor;
  final InputDecoration Function(String hint) setFieldDecoration;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;

  const _ExerciseCard({
    required this.exercise,
    required this.badgeColor,
    required this.setFieldDecoration,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    final sets = exercise['sets'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: GymTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise['muscleGroup']} · ${exercise['equipment']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GymTheme.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: GymTheme.danger,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: GymTheme.border, height: 1),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'SET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: GymTheme.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'WEIGHT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: GymTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: GymTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 36),
              ],
            ),
          ),
          ...List.generate(sets.length, (setIndex) {
            final s = sets[setIndex];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${s['setNumber']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: GymTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextFormField(
                        initialValue: s['weight'] == 0.0
                            ? ''
                            : '${s['weight']}',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: GymTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        decoration: setFieldDecoration('kg'),
                        onChanged: (val) {
                          s['weight'] = double.tryParse(val) ?? 0.0;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextFormField(
                        initialValue: s['reps'] == 0 ? '' : '${s['reps']}',
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: GymTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        decoration: setFieldDecoration('reps'),
                        onChanged: (val) {
                          s['reps'] = int.tryParse(val) ?? 0;
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: GymTheme.textMuted.withValues(alpha: 0.8),
                      ),
                      onPressed: () => onRemoveSet(setIndex),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Add set',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: GymTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseSheet extends ConsumerStatefulWidget {
  final List<String> muscleOptions;
  final Set<String> selectedIds;
  final ValueChanged<Map<String, dynamic>> onPickFromLibrary;
  final Future<void> Function(String name, String muscle) onCreateCustom;

  const _AddExerciseSheet({
    required this.muscleOptions,
    required this.selectedIds,
    required this.onPickFromLibrary,
    required this.onCreateCustom,
  });

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  bool _showCustomForm = false;
  final _nameCtrl = TextEditingController();
  String _muscle = 'Chest';
  String _search = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: GymTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GymTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _showCustomForm ? 'Create exercise' : 'Add exercise',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: GymTheme.textPrimary,
                    ),
                  ),
                ),
                if (!_showCustomForm)
                  TextButton(
                    onPressed: () => setState(() => _showCustomForm = true),
                    child: const Text(
                      'Custom',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => setState(() => _showCustomForm = false),
                    child: const Text(
                      'Library',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          if (_showCustomForm)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: GymTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Exercise name',
                      filled: true,
                      fillColor: GymTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: GymTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: GymTheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _muscle,
                    decoration: InputDecoration(
                      labelText: 'Muscle group',
                      filled: true,
                      fillColor: GymTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: GymTheme.border),
                      ),
                    ),
                    dropdownColor: GymTheme.surface,
                    items: widget.muscleOptions
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _muscle = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameCtrl.text.trim().isEmpty) return;
                        await widget.onCreateCustom(
                          _nameCtrl.text.trim(),
                          _muscle,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GymTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Add to workout',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (val) => setState(() => _search = val.toLowerCase()),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GymTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search library...',
                  hintStyle: TextStyle(
                    color: GymTheme.textMuted.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: GymTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: GymTheme.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: exercisesAsync.when(
                data: (list) {
                  var filtered = list;
                  if (_search.isNotEmpty) {
                    filtered = list.where((ex) {
                      final name = (ex['name'] ?? '').toString().toLowerCase();
                      final group =
                          (ex['muscle_group'] ?? ex['muscleGroup'] ?? '')
                              .toString()
                              .toLowerCase();
                      return name.contains(_search) || group.contains(_search);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No matching exercises',
                          style: TextStyle(
                            color: GymTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final id = ex['id']?.toString() ?? '';
                      final alreadyAdded = widget.selectedIds.contains(id);
                      final colors = [
                        GymTheme.mint,
                        GymTheme.periwinkle,
                        GymTheme.yellow,
                        GymTheme.peach,
                        GymTheme.lavender,
                      ];

                      return ListTile(
                        onTap: alreadyAdded
                            ? null
                            : () => widget.onPickFromLibrary(
                                Map<String, dynamic>.from(ex as Map),
                              ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 18,
                            color: GymTheme.textPrimary,
                          ),
                        ),
                        title: Text(
                          ex['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: alreadyAdded
                                ? GymTheme.textMuted
                                : GymTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${ex['muscle_group'] ?? ex['muscleGroup']} · ${ex['equipment']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: GymTheme.textSecondary,
                          ),
                        ),
                        trailing: alreadyAdded
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: GymTheme.success,
                                size: 22,
                              )
                            : const Icon(
                                Icons.add_circle_outline_rounded,
                                color: GymTheme.primary,
                                size: 22,
                              ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Could not load exercises',
                    style: TextStyle(color: GymTheme.danger),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
