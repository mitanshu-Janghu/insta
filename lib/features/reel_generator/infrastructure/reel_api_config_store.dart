import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reel_api_config.dart';

class ReelApiConfigStore {
  static const _baseUrlKey = 'reel_api_base_url';
  static const _apiKeyKey = 'reel_api_key';
  static const _createPathKey = 'reel_api_create_path';
  static const _statusPathKey = 'reel_api_status_path';

  Future<ReelApiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_baseUrlKey)?.trim() ?? '';
    final apiKey = prefs.getString(_apiKeyKey)?.trim() ?? '';
    final createPath =
        prefs.getString(_createPathKey)?.trim().isNotEmpty == true
        ? prefs.getString(_createPathKey)!.trim()
        : '/reels';
    final statusPathTemplate =
        prefs.getString(_statusPathKey)?.trim().isNotEmpty == true
        ? prefs.getString(_statusPathKey)!.trim()
        : '/reels/{jobId}';

    if (baseUrl.isEmpty && apiKey.isEmpty) {
      return ReelApiConfig.fromEnvironment();
    }

    return ReelApiConfig(
      baseUrl: baseUrl,
      apiKey: apiKey,
      createPath: createPath,
      statusPathTemplate: statusPathTemplate,
    );
  }

  Future<void> save(ReelApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, config.baseUrl.trim());
    await prefs.setString(_apiKeyKey, config.apiKey.trim());
    await prefs.setString(_createPathKey, config.createPath.trim());
    await prefs.setString(_statusPathKey, config.statusPathTemplate.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    await prefs.remove(_apiKeyKey);
    await prefs.remove(_createPathKey);
    await prefs.remove(_statusPathKey);
  }
}
