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

// --- Offline Sync State ---

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final String? lastMessage;
  final bool? lastSuccess;

  SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastMessage,
    this.lastSuccess,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    String? lastMessage,
    bool? lastSuccess,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final ApiClient _apiClient;
  final Ref _ref;

  SyncNotifier(this._apiClient, this._ref) : super(SyncState()) {
    refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    final count = await _apiClient.syncManager.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  Future<Map<String, dynamic>> performSync() async {
    state = state.copyWith(isSyncing: true, lastMessage: null);

    final result = await _apiClient.syncManager.syncPendingData(_apiClient);

    final remainingCount = await _apiClient.syncManager.getPendingCount();
    final bool success = result['success'] == true;
    final String message = result['message'] ?? 'Sync completed';

    state = state.copyWith(
      isSyncing: false,
      pendingCount: remainingCount,
      lastMessage: message,
      lastSuccess: success,
    );

    // Refresh app data providers
    _ref.invalidate(todayWorkoutProvider);
    _ref.invalidate(progressOverviewProvider);
    _ref.invalidate(exercisesProvider);

    return result;
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref.watch(apiClientProvider), ref);
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

// Server URL Provider
class ServerUrlNotifier extends StateNotifier<String> {
  final ApiClient _apiClient;
  final Ref _ref;

  ServerUrlNotifier(this._apiClient, this._ref) : super(_apiClient.rawBaseUrl);

  Future<void> setUrl(String newUrl) async {
    await _apiClient.updateBaseUrl(newUrl);
    state = _apiClient.rawBaseUrl;
    // Invalidate app data providers to refetch using new server URL
    _ref.invalidate(todayWorkoutProvider);
    _ref.invalidate(progressOverviewProvider);
    _ref.invalidate(exercisesProvider);
  }

  Future<bool> testConnection([String? testUrl]) async {
    return await _apiClient.testConnection(testUrl);
  }
}

final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String>((ref) {
  return ServerUrlNotifier(ref.watch(apiClientProvider), ref);
});
