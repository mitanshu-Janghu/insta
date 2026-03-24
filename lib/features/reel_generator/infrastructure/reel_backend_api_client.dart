import 'dart:convert';
import 'dart:io';

import '../domain/reel_api_config.dart';
import '../domain/reel_generator_models.dart';

class RemoteReelJob {
  const RemoteReelJob({
    required this.jobId,
    required this.status,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.captionText,
    required this.errorMessage,
    required this.fileName,
    required this.scriptLines,
    required this.hashtags,
  });

  final String jobId;
  final String status;
  final String videoUrl;
  final String thumbnailUrl;
  final String captionText;
  final String errorMessage;
  final String fileName;
  final List<String> scriptLines;
  final List<String> hashtags;

  bool get isCompleted =>
      status.toLowerCase() == 'completed' && videoUrl.isNotEmpty;

  bool get isFailed {
    final normalized = status.toLowerCase();
    return normalized == 'failed' || normalized == 'error';
  }
}

class ReelBackendApiClient {
  ReelBackendApiClient({ReelApiConfig? initialConfig})
    : _config = initialConfig ?? ReelApiConfig.fromEnvironment();

  ReelApiConfig _config;

  ReelApiConfig get config => _config;

  bool get isConfigured => _config.isConfigured;

  void updateConfig(ReelApiConfig config) {
    _config = config;
  }

  Future<RemoteReelJob> startReelJob(GeneratedProject project) async {
    final response = await _request(
      method: 'POST',
      path: createPath(),
      body: {
        'prompt': project.prompt,
        'platform': project.platform,
        'tone': project.tone,
        'voice': project.voice,
        'durationSeconds': project.durationSeconds,
        'captionsEnabled': project.captionsEnabled,
        'hookEnabled': project.hookEnabled,
        'ctaEnabled': project.ctaEnabled,
        'watermarkFree': project.watermarkFree,
        'captionText': project.captionText,
        'hashtags': project.hashtags,
        'scriptLines': project.scriptLines,
        'shotPlan': project.shotPlan,
      },
    );
    return _parseJob(response);
  }

  Future<RemoteReelJob> fetchReelJob(String jobId) async {
    final response = await _request(method: 'GET', path: statusPath(jobId));
    return _parseJob(response);
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Connect your real reel API in settings to enable video generation.',
      );
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse(
        '${_config.baseUrl.replaceAll(RegExp(r'/$'), '')}$path',
      );
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (_config.apiKey.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${_config.apiKey}',
        );
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Reel API request failed (${response.statusCode}): ${rawBody.isEmpty ? 'No response body.' : rawBody}',
        );
      }

      if (rawBody.isEmpty) {
        return const <String, dynamic>{};
      }

      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Reel API returned an unexpected response shape.');
    } finally {
      client.close(force: true);
    }
  }

  RemoteReelJob _parseJob(Map<String, dynamic> payload) {
    final result = _mapFrom(payload['result']);
    final data = _mapFrom(payload['data']);
    final assets = _mapFrom(payload['assets']);

    final jobId =
        _stringValue(payload['jobId']) ??
        _stringValue(payload['id']) ??
        _stringValue(result['jobId']) ??
        _stringValue(data['jobId']) ??
        _stringValue(result['id']) ??
        _stringValue(data['id']) ??
        '';
    final status =
        _stringValue(payload['status']) ??
        _stringValue(payload['state']) ??
        _stringValue(result['status']) ??
        _stringValue(data['status']) ??
        'pending';
    final videoUrl =
        _stringValue(payload['videoUrl']) ??
        _stringValue(payload['video_url']) ??
        _stringValue(result['videoUrl']) ??
        _stringValue(result['video_url']) ??
        _stringValue(data['videoUrl']) ??
        _stringValue(data['video_url']) ??
        _stringValue(result['url']) ??
        _stringValue(data['url']) ??
        _stringValue(assets['videoUrl']) ??
        _stringValue(assets['video_url']) ??
        '';
    final thumbnailUrl =
        _stringValue(payload['thumbnailUrl']) ??
        _stringValue(payload['thumbnail_url']) ??
        _stringValue(result['thumbnailUrl']) ??
        _stringValue(result['thumbnail_url']) ??
        _stringValue(data['thumbnailUrl']) ??
        _stringValue(data['thumbnail_url']) ??
        _stringValue(assets['thumbnailUrl']) ??
        _stringValue(assets['thumbnail_url']) ??
        '';
    final captionText =
        _stringValue(payload['caption']) ??
        _stringValue(payload['captionText']) ??
        _stringValue(result['caption']) ??
        _stringValue(result['captionText']) ??
        _stringValue(data['caption']) ??
        _stringValue(data['captionText']) ??
        '';
    final errorMessage =
        _stringValue(payload['error']) ??
        _stringValue(payload['message']) ??
        _stringValue(result['error']) ??
        _stringValue(data['error']) ??
        _stringValue(data['message']) ??
        '';
    final fileName =
        _stringValue(payload['fileName']) ??
        _stringValue(payload['filename']) ??
        _stringValue(result['fileName']) ??
        _stringValue(result['filename']) ??
        _stringValue(data['fileName']) ??
        _stringValue(data['filename']) ??
        '';
    final scriptLines = _stringList(payload['scriptLines']).isNotEmpty
        ? _stringList(payload['scriptLines'])
        : _stringList(result['scriptLines']).isNotEmpty
        ? _stringList(result['scriptLines'])
        : _stringList(data['scriptLines']);
    final hashtags = _stringList(payload['hashtags']).isNotEmpty
        ? _stringList(payload['hashtags'])
        : _stringList(result['hashtags']).isNotEmpty
        ? _stringList(result['hashtags'])
        : _stringList(data['hashtags']);

    return RemoteReelJob(
      jobId: jobId,
      status: status,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      captionText: captionText,
      errorMessage: errorMessage,
      fileName: fileName,
      scriptLines: scriptLines,
      hashtags: hashtags,
    );
  }

  String createPath() => _normalizePath(_config.createPath, '/reels');

  String statusPath(String jobId) {
    final template = _normalizePath(
      _config.statusPathTemplate,
      '/reels/{jobId}',
    );
    return template.replaceAll('{jobId}', Uri.encodeComponent(jobId));
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry('$key', mapValue));
    }
    return const <String, dynamic>{};
  }

  String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _normalizePath(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
