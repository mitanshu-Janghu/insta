import 'dart:convert';
import 'dart:io';

class GeminiPlanResponse {
  const GeminiPlanResponse({
    required this.captionText,
    required this.scriptLines,
    required this.shotPlan,
    required this.hashtags,
  });

  final String captionText;
  final List<String> scriptLines;
  final List<String> shotPlan;
  final List<String> hashtags;
}

class GeminiFreeApiClient {
  const GeminiFreeApiClient();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<GeminiPlanResponse?> generatePlan({
    required String prompt,
    required String platform,
    required String tone,
    required int durationSeconds,
    required bool captionsEnabled,
    required bool hookEnabled,
    required bool ctaEnabled,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        ),
      );
      request.headers.set('x-goog-api-key', _apiKey);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      '''
Return JSON only with keys: captionText, scriptLines, shotPlan, hashtags.
Context:
- prompt: $prompt
- platform: $platform
- tone: $tone
- durationSeconds: $durationSeconds
- captionsEnabled: $captionsEnabled
- hookEnabled: $hookEnabled
- ctaEnabled: $ctaEnabled

Rules:
- scriptLines should have 4 to 6 items
- shotPlan should have 4 short items
- hashtags should have 4 to 6 hashtags starting with #
- captionText should be concise and social-ready
''',
                },
              ],
            },
          ],
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        return null;
      }

      final content = candidates.first['content'];
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        return null;
      }

      final rawText = parts
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n');
      final jsonText = _extractJson(rawText);
      if (jsonText == null) {
        return null;
      }

      final plan = jsonDecode(jsonText) as Map<String, dynamic>;
      final captionText = plan['captionText']?.toString().trim() ?? '';
      final scriptLines = _stringList(plan['scriptLines']);
      final shotPlan = _stringList(plan['shotPlan']);
      final hashtags = _stringList(plan['hashtags']);

      if (captionText.isEmpty || scriptLines.isEmpty) {
        return null;
      }

      return GeminiPlanResponse(
        captionText: captionText,
        scriptLines: scriptLines,
        shotPlan: shotPlan,
        hashtags: hashtags,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.map((item) => item.toString().trim()).where((item) {
      return item.isNotEmpty;
    }).toList();
  }

  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    return text.substring(start, end + 1);
  }
}
