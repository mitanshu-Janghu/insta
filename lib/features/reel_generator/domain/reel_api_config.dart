class ReelApiConfig {
  const ReelApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.createPath,
    required this.statusPathTemplate,
  });

  factory ReelApiConfig.empty() {
    return const ReelApiConfig(
      baseUrl: '',
      apiKey: '',
      createPath: '/reels',
      statusPathTemplate: '/reels/{jobId}',
    );
  }

  factory ReelApiConfig.fromEnvironment() {
    return const ReelApiConfig(
      baseUrl: String.fromEnvironment('REEL_API_BASE_URL'),
      apiKey: String.fromEnvironment('REEL_API_KEY'),
      createPath: String.fromEnvironment(
        'REEL_API_CREATE_PATH',
        defaultValue: '/reels',
      ),
      statusPathTemplate: String.fromEnvironment(
        'REEL_API_STATUS_PATH',
        defaultValue: '/reels/{jobId}',
      ),
    );
  }

  final String baseUrl;
  final String apiKey;
  final String createPath;
  final String statusPathTemplate;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  ReelApiConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? createPath,
    String? statusPathTemplate,
  }) {
    return ReelApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      createPath: createPath ?? this.createPath,
      statusPathTemplate: statusPathTemplate ?? this.statusPathTemplate,
    );
  }
}
