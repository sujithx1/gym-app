import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'offline_sync_manager.dart';

class ApiClient {
  String _serverBaseUrl = AppConfig.defaultBaseUrl;
  String? _token;
  final void Function()? onRequestStart;
  final void Function()? onRequestEnd;
  final OfflineSyncManager syncManager = OfflineSyncManager();

  ApiClient({this.onRequestStart, this.onRequestEnd});

  String get rawBaseUrl => _serverBaseUrl;
  String get baseUrl => AppConfig.getApiUrl(_serverBaseUrl);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _serverBaseUrl = await AppConfig.getBaseUrl();
  }

  Future<void> updateBaseUrl(String newUrl) async {
    _serverBaseUrl = await AppConfig.setBaseUrl(newUrl);
  }

  Future<bool> testConnection([String? customUrl]) async {
    final target = customUrl != null && customUrl.trim().isNotEmpty
        ? AppConfig.getApiUrl(AppConfig.normalizeUrl(customUrl))
        : baseUrl;
    try {
      final res = await http
          .get(Uri.parse('$target/workouts/today'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200 || res.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  Future<T> _trackRequest<T>(Future<T> Function() fn, {bool showGlobalLoading = true}) async {
    if (showGlobalLoading) {
      onRequestStart?.call();
    }
    try {
      return await fn();
    } finally {
      if (showGlobalLoading) {
        onRequestEnd?.call();
      }
    }
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // --- Auth APIs ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    return _trackRequest(() async {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _headers,
          body: jsonEncode({'username': username, 'password': password}),
        ).timeout(const Duration(seconds: 5));

        final data = jsonDecode(res.body);
        if (res.statusCode == 200 && data['token'] != null) {
          await setToken(data['token']);
          return {'success': true, 'user': data['user']};
        }
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      } catch (e) {
        return {'success': false, 'error': 'Cannot connect to backend server. Make sure server is running on port 3001.'};
      }
    });
  }

  // --- Workouts API ---
  Future<Map<String, dynamic>> getTodayWorkout() async {
    return _trackRequest(showGlobalLoading: false, () async {
      try {
        final res = await http.get(
          Uri.parse('$baseUrl/workouts/today'),
          headers: _headers,
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          await syncManager.cacheTodayWorkout(data);
          return data;
        }
      } catch (_) {
        // Fallback to offline cache
      }

      final cached = await syncManager.getCachedTodayWorkout();
      return cached ?? {'today': null};
    });
  }

  // --- Session Direct API Helpers ---
  Future<String?> directStartSession(String? workoutDayId, String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sessions/start'),
      headers: _headers,
      body: jsonEncode({'workoutDayId': workoutDayId, 'name': name}),
    ).timeout(const Duration(seconds: 4));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['sessionId'] as String?;
    }
    return null;
  }

  Future<bool> directLogSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    required bool completed,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/sessions/$sessionId/set'),
      headers: _headers,
      body: jsonEncode({
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'completed': completed,
      }),
    ).timeout(const Duration(seconds: 4));

    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> directCompleteSession(String sessionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/complete'),
      headers: _headers,
      body: jsonEncode({'notes': 'Workout completed!'}),
    ).timeout(const Duration(seconds: 4));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['summary'] as Map<String, dynamic>? ?? {};
    }
    return null;
  }

  Future<Map<String, dynamic>?> directCreateExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    String? instructions,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'instructions': instructions ?? '',
      }),
    ).timeout(const Duration(seconds: 4));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // --- Session Public APIs with Offline Queue Fallback ---
  Future<String?> startSession(String? workoutDayId, String name) async {
    return _trackRequest(() async {
      try {
        final sessionId = await directStartSession(workoutDayId, name);
        if (sessionId != null) return sessionId;
      } catch (_) {
        // Backend offline
      }

      // Offline mode: Queue mutation & generate local ID
      final localSessionId = 'sess_offline_${DateTime.now().millisecondsSinceEpoch}';
      await syncManager.queueMutation('start_session', {
        'workoutDayId': workoutDayId,
        'name': name,
        'localSessionId': localSessionId,
      });

      return localSessionId;
    });
  }

  Future<bool> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    required bool completed,
  }) async {
    return _trackRequest(() async {
      try {
        final ok = await directLogSet(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setNumber: setNumber,
          weight: weight,
          reps: reps,
          completed: completed,
        );
        if (ok) return true;
      } catch (_) {
        // Backend offline
      }

      // Offline mode: queue locally
      await syncManager.queueMutation('log_set', {
        'sessionId': sessionId,
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'completed': completed,
      });

      return true; // return optimistic true locally
    });
  }

  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    return _trackRequest(() async {
      try {
        final summary = await directCompleteSession(sessionId);
        if (summary != null) return summary;
      } catch (_) {
        // Backend offline
      }

      // Queue locally
      await syncManager.queueMutation('complete_session', {
        'sessionId': sessionId,
      });

      return {
        'sessionId': sessionId,
        'name': 'Workout Session (Offline Queued)',
        'totalVolumeKg': 0.0,
        'durationMinutes': 0,
        'totalSetsCompleted': 0,
        'previousVolumeKg': 0.0,
        'volumeDeltaKg': 0.0,
        'percentageDelta': 0,
        'message': 'Workout completed offline! Stored in local storage for DB sync.',
      };
    });
  }

  // --- Progress & Stats APIs ---
  Future<Map<String, dynamic>> getProgressOverview() async {
    return _trackRequest(showGlobalLoading: false, () async {
      try {
        final res = await http.get(
          Uri.parse('$baseUrl/progress/overview'),
          headers: _headers,
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          await syncManager.cacheProgressOverview(data);
          return data;
        }
      } catch (_) {
        // Fallback
      }

      final cached = await syncManager.getCachedProgressOverview();
      return cached ?? {
        'summary': {
          'totalWorkouts': 0,
          'totalVolumeKg': 0.0,
          'streakDays': 0,
          'weeklyAttendance': [false, false, false, false, false, false, false],
        },
        'personalRecords': [],
      };
    });
  }

  // --- Exercise Library ---
  Future<List<dynamic>> getExercises([String? muscleGroup]) async {
    return _trackRequest(showGlobalLoading: false, () async {
      try {
        final Uri uri = muscleGroup != null && muscleGroup.isNotEmpty
            ? Uri.parse('$baseUrl/exercises?muscleGroup=$muscleGroup')
            : Uri.parse('$baseUrl/exercises');

        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final exercises = data['exercises'] as List<dynamic>? ?? [];
          await syncManager.cacheExercises(exercises);
          return exercises;
        }
      } catch (_) {
        // Fallback
      }

      final cached = await syncManager.getCachedExercises();
      return cached ?? [];
    });
  }

  Future<Map<String, dynamic>?> createExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    String? instructions,
  }) async {
    return _trackRequest(() async {
      try {
        final res = await directCreateExercise(
          name: name,
          muscleGroup: muscleGroup,
          equipment: equipment,
          instructions: instructions,
        );
        if (res != null) {
          await syncManager.addLocalCachedExercise(res);
          return res;
        }
      } catch (_) {
        // Connection error
      }

      // Offline queueing
      await syncManager.queueMutation('create_exercise', {
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'instructions': instructions ?? '',
      });

      final localExercise = {
        'id': 'ex_offline_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'instructions': instructions ?? '',
        'isCustom': true,
        'offlineQueued': true,
      };

      // Immediately cache locally so UI displays it right away
      await syncManager.addLocalCachedExercise(localExercise);

      return localExercise;
    });
  }
}
