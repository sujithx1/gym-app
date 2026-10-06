import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultBaseUrl = 'http://127.0.0.1:3001';
  static const String _baseUrlKey = 'custom_server_base_url';

  /// Returns stored custom base URL or default (e.g. http://127.0.0.1:3001)
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_baseUrlKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return normalizeUrl(customUrl);
    }
    return defaultBaseUrl;
  }

  /// Saves user-configured base URL to SharedPreferences
  static Future<String> setBaseUrl(String rawUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalizeUrl(rawUrl);
    await prefs.setString(_baseUrlKey, normalized);
    return normalized;
  }

  /// Helper to ensure valid scheme (http/https) and strip trailing slashes or /api
  static String normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return defaultBaseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    return url;
  }

  static String getApiUrl(String baseUrl) {
    return '$baseUrl/api';
  }
}
