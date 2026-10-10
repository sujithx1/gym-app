import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class PendingMutation {
  final String id;
  final String action;
  final Map<String, dynamic> payload;
  final int timestamp;

  PendingMutation({
    required this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'payload': payload,
        'timestamp': timestamp,
      };

  factory PendingMutation.fromJson(Map<String, dynamic> json) => PendingMutation(
        id: json['id'] as String,
        action: json['action'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        timestamp: json['timestamp'] as int,
      );
}

class OfflineSyncManager {
  static const String _queueKey = 'offline_pending_mutations_queue';
  static const String _todayWorkoutCacheKey = 'offline_cache_today_workout';
  static const String _progressCacheKey = 'offline_cache_progress_overview';
  static const String _exercisesCacheKey = 'offline_cache_exercises';

  // --- Pending Queue Operations ---

  Future<List<PendingMutation>> getPendingMutations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_queueKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => PendingMutation.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getPendingCount() async {
    final list = await getPendingMutations();
    return list.length;
  }

  Future<void> queueMutation(String action, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getPendingMutations();

    final newMutation = PendingMutation(
      id: 'mut_${DateTime.now().millisecondsSinceEpoch}_${current.length}',
      action: action,
      payload: payload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    current.add(newMutation);
    await prefs.setString(_queueKey, jsonEncode(current.map((m) => m.toJson()).toList()));
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  // --- Cache Operations for Read Requests ---

  Future<void> cacheTodayWorkout(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayWorkoutCacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedTodayWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_todayWorkoutCacheKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProgressOverview(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressCacheKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getCachedProgressOverview() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_progressCacheKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheExercises(List<dynamic> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exercisesCacheKey, jsonEncode(exercises));
  }

  Future<List<dynamic>?> getCachedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_exercisesCacheKey);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> addLocalCachedExercise(Map<String, dynamic> exercise) async {
    final list = await getCachedExercises() ?? [];
    list.removeWhere((e) =>
        e['id'] == exercise['id'] ||
        e['name'].toString().toLowerCase() == exercise['name'].toString().toLowerCase());
    list.insert(0, exercise);
    await cacheExercises(list);
  }

  // --- Sync DB logic ---

  /// Attempts to process all queued mutations against the API backend.
  /// Items that succeed are removed from local storage.
  /// Returns a summary map with totalSynced, remaining, and success flag.
  Future<Map<String, dynamic>> syncPendingData(ApiClient api) async {
    final pending = await getPendingMutations();
    if (pending.isEmpty) {
      return {'success': true, 'syncedCount': 0, 'remainingCount': 0, 'message': 'No pending data to sync.'};
    }

    int syncedCount = 0;
    List<PendingMutation> remaining = [];

    for (final mutation in pending) {
      bool success = false;
      try {
        switch (mutation.action) {
          case 'start_session':
            final workoutDayId = mutation.payload['workoutDayId'] as String?;
            final name = mutation.payload['name'] as String? ?? 'Workout';
            final result = await api.directStartSession(workoutDayId, name);
            success = result != null;
            break;

          case 'log_set':
            success = await api.directLogSet(
              sessionId: mutation.payload['sessionId'],
              exerciseId: mutation.payload['exerciseId'],
              setNumber: mutation.payload['setNumber'],
              weight: (mutation.payload['weight'] as num).toDouble(),
              reps: mutation.payload['reps'],
              completed: mutation.payload['completed'],
            );
            break;

          case 'complete_session':
            final result = await api.directCompleteSession(mutation.payload['sessionId']);
            success = result != null;
            break;

          case 'create_exercise':
            final result = await api.directCreateExercise(
              id: mutation.payload['id'],
              name: mutation.payload['name'],
              muscleGroup: mutation.payload['muscleGroup'],
              equipment: mutation.payload['equipment'],
              instructions: mutation.payload['instructions'],
            );
            success = result != null;
            break;
        }
      } catch (_) {
        success = false;
      }

      if (success) {
        syncedCount++;
      } else {
        remaining.add(mutation);
      }
    }

    // Save remaining un-synced items back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await prefs.remove(_queueKey);
    } else {
      await prefs.setString(_queueKey, jsonEncode(remaining.map((m) => m.toJson()).toList()));
    }

    return {
      'success': remaining.isEmpty,
      'syncedCount': syncedCount,
      'remainingCount': remaining.length,
      'message': remaining.isEmpty
          ? 'Successfully synced $syncedCount mutations and cleared local storage!'
          : 'Synced $syncedCount items. ${remaining.length} items could not be synced yet.',
    };
  }
}
