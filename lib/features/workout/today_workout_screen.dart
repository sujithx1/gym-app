import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gym_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/ios_button.dart';
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

  final List<Color> _pastelColors = [
    GymTheme.mint,
    GymTheme.lavender,
    GymTheme.peach,
    GymTheme.blue,
    GymTheme.yellow,
  ];

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
    _exercises = rawExercises.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      final targetSets = e['targetSets'] ?? 3;
      final targetWeight = (e['targetWeight'] as num?)?.toDouble() ?? 60.0;
      final targetReps = e['targetReps'] ?? 10;
      final lastPerf = (e['lastPerformance'] as List?) ?? [];

      final existingSets = (e['sets'] as List?) ?? [];
      final setsCount = existingSets.isNotEmpty ? existingSets.length : (targetSets > 0 ? targetSets : 3);

      final sets = List.generate(setsCount, (i) {
        final last = i < lastPerf.length ? lastPerf[i] : null;
        final exist = i < existingSets.length ? existingSets[i] : null;

        double w = exist != null ? (exist['weight'] as num).toDouble() : (last != null ? (last['weight'] as num).toDouble() : targetWeight);
        int r = exist != null ? (exist['reps'] as int) : (last != null ? last['reps'] as int : targetReps);

        if (w == 0) w = 60.0;
        if (r == 0) r = 10;

        return {
          'setNumber': i + 1,
          'weight': w,
          'reps': r,
          'completed': exist != null ? (exist['completed'] as bool) : false,
          'lastWeight': last != null ? (last['weight'] as num).toDouble() : (w > 0 ? w : 60.0),
          'lastReps': last != null ? last['reps'] as int : (r > 0 ? r : 10),
        };
      });

      return {
        'id': e['id'],
        'name': e['name'],
        'muscleGroup': e['muscleGroup'] ?? 'CHEST',
        'equipment': e['equipment'] ?? 'Barbell',
        'color': _pastelColors[idx % _pastelColors.length],
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
      final lastSet = sets.isNotEmpty ? sets.last : {'weight': 60.0, 'reps': 10};
      sets.add({
        'setNumber': sets.length + 1,
        'weight': lastSet['weight'],
        'reps': lastSet['reps'],
        'completed': false,
        'lastWeight': lastSet['weight'],
        'lastReps': lastSet['reps'],
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
    final title = widget.todayData['name'] ?? 'CHEST + TRICEPS';
    final progressPct = _totalSetsCount > 0 ? (_completedSetsCount / _totalSetsCount) : 0.0;

    return Scaffold(
      backgroundColor: GymTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GymTheme.textPrimary),
            ),
            Text(
              '${_exercises.length} exercises  •  $_totalSetsCount sets  •  ~55 min',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GymTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GymTheme.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedSetsCount / $_totalSetsCount sets',
                  style: const TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 12),
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
            backgroundColor: GymTheme.border,
            valueColor: const AlwaysStoppedAnimation<Color>(GymTheme.primary),
            minHeight: 4,
          ),

          // Rest Timer Bar
          if (_restSecondsRemaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: GymTheme.yellow,
              child: Row(
                children: [
                  const Icon(Icons.timer, color: GymTheme.textPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'REST TIMER: ${_restSecondsRemaining.toString().padLeft(2, '0')}s',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: GymTheme.textPrimary, fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _startRestTimer(_restSecondsRemaining + 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GymTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('+30s', style: TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _restTimer?.cancel();
                      setState(() => _restSecondsRemaining = 0);
                    },
                    child: const Text('SKIP', style: TextStyle(color: GymTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _exercises.length,
              itemBuilder: (context, exIndex) {
                final ex = _exercises[exIndex];
                final sets = ex['sets'] as List;
                final Color cardAccent = ex['color'] ?? GymTheme.mint;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: GymTheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: GymTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Header Banner with pastel accent
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardAccent,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 01, 02 Number Badge
                            Text(
                              (exIndex + 1).toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: GymTheme.textPrimary.withOpacity(0.3),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: GymTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (ex['muscleGroup'] as String).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: GymTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LAST SESSION Reference Box
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: GymTheme.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: GymTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'LAST SESSION',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textMuted),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '60 kg × 10',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GymTheme.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: GymTheme.mint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '↑ +1 rep target',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GymTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Table Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          children: const [
                            SizedBox(width: 40, child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textMuted))),
                            Expanded(child: Text('WEIGHT (KG)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textMuted))),
                            Expanded(child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textMuted))),
                            SizedBox(width: 50, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: GymTheme.textMuted))),
                          ],
                        ),
                      ),

                      // Set Rows with Controls
                      ...List.generate(sets.length, (setIndex) {
                        final s = sets[setIndex];
                        final bool isDone = s['completed'];
                        final double weight = s['weight'];
                        final int reps = s['reps'];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDone ? cardAccent.withOpacity(0.35) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Set Number
                              SizedBox(
                                width: 36,
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDone ? GymTheme.primary : GymTheme.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${s['setNumber']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isDone ? Colors.white : GymTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              // Weight Control (- 60 kg +)
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: GymTheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: GymTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetWeight(exIndex, setIndex, -2.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32),
                                      ),
                                      Text(
                                        weight % 1 == 0 ? '${weight.toInt()} kg' : '$weight kg',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: GymTheme.textPrimary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetWeight(exIndex, setIndex, 2.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Reps Control (- 10 +)
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: GymTheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: GymTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetReps(exIndex, setIndex, -1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32),
                                      ),
                                      Text(
                                        '$reps',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: GymTheme.textPrimary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 14, color: GymTheme.textPrimary),
                                        onPressed: () => _updateSetReps(exIndex, setIndex, 1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Complete Check Button
                              GestureDetector(
                                onTap: () => _toggleSetCompleted(exIndex, setIndex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  height: 40,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: isDone ? GymTheme.primary : GymTheme.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDone ? GymTheme.primary : GymTheme.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 20,
                                    color: isDone ? Colors.white : GymTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Set Pill Button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => _addSet(exIndex),
                            icon: const Icon(Icons.add, size: 16, color: GymTheme.textPrimary),
                            label: const Text('+ ADD SET', style: TextStyle(color: GymTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                            style: TextButton.styleFrom(
                              backgroundColor: GymTheme.background,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: GymTheme.border)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Sticky Complete Workout Action Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: GymTheme.surface,
              border: Border(top: BorderSide(color: GymTheme.border)),
            ),
            child: SafeArea(
              child: IosButton(
                height: 56,
                width: double.infinity,
                onPressed: _isSaving ? null : _completeWorkout,
                child: _isSaving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'WORKOUT COMPLETE',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 1.2),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

