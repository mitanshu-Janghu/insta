import 'dart:convert';
import 'dart:io';

import '../domain/reel_generator_models.dart';

class PexelsFreeApiClient {
  const PexelsFreeApiClient();

  static const String _apiKey = String.fromEnvironment('PEXELS_API_KEY');

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<StockClip>> searchPortraitClips(String query) async {
    if (!isConfigured) {
      return const [];
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.pexels.com/videos/search?query=${Uri.encodeQueryComponent(query)}&orientation=portrait&per_page=3',
      );
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', _apiKey);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final videos = decoded['videos'];
      if (videos is! List) {
        return const [];
      }

      return videos
          .take(3)
          .map((video) {
            final files = (video['video_files'] as List?) ?? const [];
            final selectedFile = files.cast<Map>().firstWhere(
              (file) => (file['link']?.toString().isNotEmpty ?? false),
              orElse: () => <String, dynamic>{},
            );

            return StockClip(
              source: 'Pexels',
              title: query,
              pageUrl: video['url']?.toString() ?? '',
              fileUrl: selectedFile['link']?.toString() ?? '',
              thumbnailUrl: video['image']?.toString() ?? '',
              durationSeconds: (video['duration'] as num?)?.round() ?? 0,
            );
          })
          .where((clip) => clip.fileUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
}
