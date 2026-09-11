import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../networking/api_client.dart';

class ApiLoadingNotifier extends StateNotifier<int> {
  ApiLoadingNotifier() : super(0);

  void startLoading() {
    state = state + 1;
  }

  void stopLoading() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void reset() {
    state = 0;
  }
}

final apiLoadingProvider = StateNotifierProvider<ApiLoadingNotifier, int>((ref) {
  return ApiLoadingNotifier();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final loadingNotifier = ref.watch(apiLoadingProvider.notifier);
  return ApiClient(
    onRequestStart: () => loadingNotifier.startLoading(),
    onRequestEnd: () => loadingNotifier.stopLoading(),
  );
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? username;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? username,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      username: username ?? this.username,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState(isAuthenticated: false)) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    await _apiClient.init();
    if (_apiClient.isAuthenticated) {
      state = state.copyWith(isAuthenticated: true, username: 'sujith');
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _apiClient.login(username, password);
    if (res['success'] == true) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        username: res['user']?['username'] ?? username,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res['error'] ?? 'Invalid username or password',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});

// Today Workout Provider
final todayWorkoutProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return await api.getTodayWorkout();
});

// Progress Overview Provider
final progressOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return await api.getProgressOverview();
});

// Exercises Provider
final exerciseFilterProvider = StateProvider<String>((ref) => '');

final exercisesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final filter = ref.watch(exerciseFilterProvider);
  return await api.getExercises(filter);
});
