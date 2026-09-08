import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  static const String baseUrl = AppConfig.apiBaseUrl;
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
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
  }

  // --- Workouts API ---
  Future<Map<String, dynamic>> getTodayWorkout() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/workouts/today'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // Return empty today state on network error
    }
    return {'today': null};
  }

  // --- Session APIs ---
  Future<String?> startSession(String? workoutDayId, String name) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/sessions/start'),
        headers: _headers,
        body: jsonEncode({'workoutDayId': workoutDayId, 'name': name}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sessionId'];
      }
    } catch (e) {
      // Connection issue
    }
    return 'sess_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> logSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    required bool completed,
  }) async {
    try {
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
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionId/complete'),
        headers: _headers,
        body: jsonEncode({'notes': 'Workout completed!'}),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['summary'] ?? {};
      }
    } catch (e) {}

    return {
      'sessionId': sessionId,
      'name': 'Workout Session',
      'totalVolumeKg': 0.0,
      'durationMinutes': 0,
      'totalSetsCompleted': 0,
      'previousVolumeKg': 0.0,
      'volumeDeltaKg': 0.0,
      'percentageDelta': 0,
      'message': 'Workout completed successfully!',
    };
  }

  // --- Progress & Stats APIs ---
  Future<Map<String, dynamic>> getProgressOverview() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/progress/overview'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {}

    return {
      'summary': {
        'totalWorkouts': 0,
        'totalVolumeKg': 0.0,
        'streakDays': 0,
        'weeklyAttendance': [false, false, false, false, false, false, false],
      },
      'personalRecords': [],
    };
  }

  // --- Exercise Library ---
  Future<List<dynamic>> getExercises([String? muscleGroup]) async {
    try {
      final Uri uri = muscleGroup != null && muscleGroup.isNotEmpty
          ? Uri.parse('$baseUrl/exercises?muscleGroup=$muscleGroup')
          : Uri.parse('$baseUrl/exercises');

      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['exercises'] ?? [];
      }
    } catch (e) {}

    return [];
  }
}

