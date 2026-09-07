import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import 'completion_dialog.dart';

class TodayWorkoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> todayData;

  const TodayWorkoutScreen({super.key, required this.todayData});

  @override
  ConsumerState<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends ConsumerState<TodayWorkoutScreen> {
  late String _sessionId;
  late List<Map<String, dynamic>> _exercises;
  bool _isSaving = false;

  // Rest Timer State
  int _restSecondsRemaining = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _initWorkoutState();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _initWorkoutState() {
    _sessionId = widget.todayData['activeSession']?['id'] ??
        'sess_${DateTime.now().millisecondsSinceEpoch}';

    final rawExercises = widget.todayData['exercises'] as List? ?? [];
    _exercises = rawExercises.map((e) {
      final targetSets = e['targetSets'] ?? 1;
      final targetWeight = (e['targetWeight'] as num?)?.toDouble() ?? 0.0;
      final targetReps = e['targetReps'] ?? 0;
      final lastPerf = (e['lastPerformance'] as List?) ?? [];

      final existingSets = (e['sets'] as List?) ?? [];
      final sets = List.generate(existingSets.isNotEmpty ? existingSets.length : targetSets, (i) {
        final last = i < lastPerf.length ? lastPerf[i] : null;
        final exist = i < existingSets.length ? existingSets[i] : null;
        return {
          'setNumber': i + 1,
          'weight': exist != null ? (exist['weight'] as num).toDouble() : (last != null ? (last['weight'] as num).toDouble() : targetWeight),
          'reps': exist != null ? (exist['reps'] as int) : (last != null ? last['reps'] as int : targetReps),
          'completed': exist != null ? (exist['completed'] as bool) : false,
          'lastWeight': last != null ? (last['weight'] as num).toDouble() : null,
          'lastReps': last != null ? last['reps'] as int : null,
        };
      });

      return {
        'id': e['id'],
        'name': e['name'],
        'muscleGroup': e['muscleGroup'] ?? 'General',
        'equipment': e['equipment'] ?? 'Custom',
        'instructions': e['instructions'],
        'sets': sets,
      };
    }).toList();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _restSecondsRemaining = 0;
        });
      } else {
        setState(() {
          _restSecondsRemaining--;
        });
      }
    });
  }

  void _toggleSetCompleted(int exIndex, int setIndex) async {
    final setItem = _exercises[exIndex]['sets'][setIndex];
    final bool newStatus = !(setItem['completed'] as bool);

    setState(() {
      setItem['completed'] = newStatus;
    });

    if (newStatus) {
      _startRestTimer(60);
    }

    final api = ref.read(apiClientProvider);
    await api.logSet(
      sessionId: _sessionId,
      exerciseId: _exercises[exIndex]['id'],
      setNumber: setItem['setNumber'],
      weight: setItem['weight'],
      reps: setItem['reps'],
      completed: newStatus,
    );
  }

  void _addSet(int exIndex) {
    setState(() {
      final sets = _exercises[exIndex]['sets'] as List;
      final lastSet = sets.isNotEmpty ? sets.last : {'weight': 0.0, 'reps': 0};
      sets.add({
        'setNumber': sets.length + 1,
        'weight': lastSet['weight'],
        'reps': lastSet['reps'],
        'completed': false,
      });
    });
  }

  void _updateSetWeight(int exIndex, int setIndex, double delta) {
    setState(() {
      final setItem = _exercises[exIndex]['sets'][setIndex];
      final current = (setItem['weight'] as double);
      setItem['weight'] = (current + delta).clamp(0.0, 500.0);
    });
  }

  void _updateSetReps(int exIndex, int setIndex, int delta) {
    setState(() {
      final setItem = _exercises[exIndex]['sets'][setIndex];
      final current = (setItem['reps'] as int);
      setItem['reps'] = (current + delta).clamp(1, 100);
    });
  }

  int get _completedSetsCount {
    int total = 0;
    for (var ex in _exercises) {
      for (var s in ex['sets']) {
        if (s['completed'] == true) total++;
      }
    }
    return total;
  }

  int get _totalSetsCount {
    int total = 0;
    for (var ex in _exercises) {
      total += (ex['sets'] as List).length;
    }
    return total;
  }

  Future<void> _completeWorkout() async {
    setState(() {
      _isSaving = true;
    });

    final api = ref.read(apiClientProvider);
    final summary = await api.completeSession(_sessionId);

    ref.invalidate(todayWorkoutProvider);
    ref.invalidate(progressOverviewProvider);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CompletionDialog(summary: summary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.todayData['name'] ?? 'CHEST DAY';
    final progressPct = _totalSetsCount > 0 ? (_completedSetsCount / _totalSetsCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: GymTheme.textPrimary)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GymTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_completedSetsCount / $_totalSetsCount Sets',
                  style: const TextStyle(color: GymTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout Progress Bar
          LinearProgressIndicator(
            value: progressPct,
            backgroundColor: GymTheme.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(GymTheme.primary),
            minHeight: 4,
          ),

          // Rest Timer Snack Bar Overlay
          if (_restSecondsRemaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: GymTheme.surfaceElevated,
              child: Row(
                children: [
                  const Icon(Icons.timer, color: GymTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'REST: ${_restSecondsRemaining.toString().padLeft(2, '0')}s',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: GymTheme.textPrimary, fontSize: 15),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _startRestTimer(_restSecondsRemaining + 30),
                    child: const Text('+30s', style: TextStyle(color: GymTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      _restTimer?.cancel();
                      setState(() => _restSecondsRemaining = 0);
                    },
                    child: const Text('SKIP', style: TextStyle(color: GymTheme.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (context, exIndex) {
                final ex = _exercises[exIndex];
                final sets = ex['sets'] as List;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: GymTheme.primaryGlow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fitness_center, color: GymTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      color: GymTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ex['muscleGroup']} • ${ex['equipment']}',
                                    style: const TextStyle(fontSize: 12, color: GymTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: GymTheme.border, height: 1),

                      // Set Table Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: const [
                            SizedBox(width: 40, child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                            Expanded(child: Text('WEIGHT (KG)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                            Expanded(child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                            SizedBox(width: 50, child: Text('DONE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textMuted))),
                          ],
                        ),
                      ),

                      // Set Rows
                      ...List.generate(sets.length, (setIndex) {
                        final s = sets[setIndex];
                        final bool isDone = s['completed'];
                        final double weight = s['weight'];
                        final int reps = s['reps'];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: isDone ? GymTheme.primary.withOpacity(0.08) : Colors.transparent,
                          child: Row(
                            children: [
                              // Set Number
                              SizedBox(
                                width: 44,
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDone ? GymTheme.primary : GymTheme.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${s['setNumber']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDone ? Colors.black : GymTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // Weight Stepper Input
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: GymTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: GymTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetWeight(exIndex, setIndex, -2.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 30),
                                      ),
                                      Text(
                                        weight % 1 == 0 ? '${weight.toInt()}' : '$weight',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: GymTheme.textPrimary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetWeight(exIndex, setIndex, 2.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 30),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Reps Stepper Input
                              Expanded(
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: GymTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: GymTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetReps(exIndex, setIndex, -1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 30),
                                      ),
                                      Text(
                                        '$reps',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: GymTheme.textPrimary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetReps(exIndex, setIndex, 1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 30),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Checkmark Done Button
                              GestureDetector(
                                onTap: () => _toggleSetCompleted(exIndex, setIndex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 38,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: isDone ? GymTheme.primary : GymTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDone ? GymTheme.primary : GymTheme.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 20,
                                    color: isDone ? Colors.black : GymTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Set Button
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextButton.icon(
                          onPressed: () => _addSet(exIndex),
                          icon: const Icon(Icons.add, size: 16, color: GymTheme.primary),
                          label: const Text('+ ADD SET', style: TextStyle(color: GymTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: GymTheme.surface,
              border: Border(top: BorderSide(color: GymTheme.border)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _completeWorkout,
                  icon: const Icon(Icons.done_all, color: Colors.black, size: 20),
                  label: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text(
                          'COMPLETE WORKOUT',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black, letterSpacing: 1.0),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
