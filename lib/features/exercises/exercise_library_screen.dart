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

  static const _equipmentOptions = [
    'Barbell',
    'Dumbbell',
    'Machine',
    'Bodyweight',
    'Cable',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      labelStyle: const TextStyle(
        color: GymTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: GymTheme.textMuted.withValues(alpha: 0.7),
        fontSize: 13,
      ),
      filled: true,
      fillColor: GymTheme.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: GymTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GymTheme.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: GymTheme.danger, width: 1.5),
      ),
    );
  }

  void _showAddCustomExerciseDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String muscleGroup = _muscleOptions.first;
    String equipment = _equipmentOptions.first;
    var isSubmitting = false;
    String? submitError;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              if (!(formKey.currentState?.validate() ?? false)) return;

              setDialogState(() {
                isSubmitting = true;
                submitError = null;
              });

              final api = ref.read(apiClientProvider);
              final result = await api.createExercise(
                name: nameCtrl.text.trim(),
                muscleGroup: muscleGroup,
                equipment: equipment,
              );

              if (!mounted) return;

              if (result == null) {
                setDialogState(() {
                  isSubmitting = false;
                  submitError = 'Could not create exercise. Try again.';
                });
                return;
              }

              final createdName = nameCtrl.text.trim();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              ref.invalidate(exercisesProvider);

              messenger.showSnackBar(
                SnackBar(
                  content: Text('$createdName added to library'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: GymTheme.primary,
                ),
              );
            }

            return AlertDialog(
              backgroundColor: GymTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'Create New Exercise',
                style: TextStyle(
                  color: GymTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !isSubmitting,
                        style: const TextStyle(
                          color: GymTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Exercise Name',
                          hint: 'e.g. Incline Bench Press',
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return 'Name is required';
                          if (name.length < 2) {
                            return 'Enter at least 2 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: muscleGroup,
                        decoration: _fieldDecoration(label: 'Muscle Group'),
                        dropdownColor: GymTheme.surface,
                        style: const TextStyle(
                          color: GymTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _muscleOptions
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                if (val != null) muscleGroup = val;
                              },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: equipment,
                        decoration: _fieldDecoration(label: 'Equipment'),
                        dropdownColor: GymTheme.surface,
                        style: const TextStyle(
                          color: GymTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _equipmentOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                if (val != null) equipment = val;
                              },
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(
                            color: GymTheme.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: GymTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: GymTheme.primary.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CREATE',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(nameCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: GymTheme.getBackgroundColor(context),
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
                    children: [
                      const Text(
                        'PRACTICES & MOVEMENTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: GymTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exercise Library',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: GymTheme.getTextPrimaryColor(context),
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
                  color: GymTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: GymTheme.getBorderColor(context)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                  style: TextStyle(
                    color: GymTheme.getTextPrimaryColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search movements or muscle group...',
                    hintStyle: TextStyle(
                      color: GymTheme.getTextSecondaryColor(context).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: GymTheme.getTextSecondaryColor(context).withValues(alpha: 0.7),
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
                            color: GymTheme.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: GymTheme.getBorderColor(context)),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: GymTheme.getTextPrimaryColor(context),
                              ),
                            ),
                            subtitle: Text(
                              '${ex['muscle_group'] ?? ex['muscleGroup']} • ${ex['equipment']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GymTheme.getTextSecondaryColor(context).withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            trailing: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: GymTheme.getSurfaceElevatedColor(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 16,
                                color: GymTheme.getTextPrimaryColor(context),
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
                  error: (_, stack) => const Center(
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
