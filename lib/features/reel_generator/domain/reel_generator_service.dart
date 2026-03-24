import 'dart:async';

import 'reel_api_config.dart';
import 'reel_generator_models.dart';
import '../infrastructure/gemini_free_api_client.dart';
import '../infrastructure/pexels_free_api_client.dart';
import '../infrastructure/reel_backend_api_client.dart';

class ReelGeneratorService {
  ReelGeneratorService({
    GeminiFreeApiClient? geminiClient,
    PexelsFreeApiClient? pexelsClient,
    ReelBackendApiClient? reelBackendClient,
  }) : _geminiClient = geminiClient ?? const GeminiFreeApiClient(),
       _pexelsClient = pexelsClient ?? const PexelsFreeApiClient(),
       _reelBackendClient = reelBackendClient ?? ReelBackendApiClient();

  final GeminiFreeApiClient _geminiClient;
  final PexelsFreeApiClient _pexelsClient;
  final ReelBackendApiClient _reelBackendClient;

  ReelApiConfig get remoteConfig => _reelBackendClient.config;

  void updateRemoteConfig(ReelApiConfig config) {
    _reelBackendClient.updateConfig(config);
  }

  bool get hasRemoteReelApiConfigured => _reelBackendClient.isConfigured;

  bool get hasAnyApiConfigured =>
      hasRemoteReelApiConfigured ||
      _geminiClient.isConfigured ||
      _pexelsClient.isConfigured;

  String get apiStatusLabel {
    if (hasRemoteReelApiConfigured) {
      return 'Real video mode: Custom Reel API';
    }
    if (_geminiClient.isConfigured && _pexelsClient.isConfigured) {
      return 'Script-only mode: connect Reel API for real video';
    }
    if (_geminiClient.isConfigured) {
      return 'Script-only mode: connect Reel API for real video';
    }
    if (_pexelsClient.isConfigured) {
      return 'Script-only mode: connect Reel API for real video';
    }
    return 'Script-only mode: connect Reel API for real video';
  }

  Future<GeneratedProject> generateProject({
    required String prompt,
    required String platform,
    required String tone,
    required String voice,
    required int durationSeconds,
    required bool captionsEnabled,
    required bool hookEnabled,
    required bool ctaEnabled,
    required bool watermarkFree,
  }) async {
    var project = buildProject(
      prompt: prompt,
      platform: platform,
      tone: tone,
      voice: voice,
      durationSeconds: durationSeconds,
      captionsEnabled: captionsEnabled,
      hookEnabled: hookEnabled,
      ctaEnabled: ctaEnabled,
      watermarkFree: watermarkFree,
    );

    final geminiPlan = await _geminiClient.generatePlan(
      prompt: prompt,
      platform: platform,
      tone: tone,
      durationSeconds: durationSeconds,
      captionsEnabled: captionsEnabled,
      hookEnabled: hookEnabled,
      ctaEnabled: ctaEnabled,
    );

    if (geminiPlan != null) {
      project = project.copyWith(
        captionText: geminiPlan.captionText,
        scriptLines: geminiPlan.scriptLines,
        shotPlan: geminiPlan.shotPlan.isEmpty
            ? project.shotPlan
            : geminiPlan.shotPlan,
        hashtags: geminiPlan.hashtags.isEmpty
            ? project.hashtags
            : geminiPlan.hashtags,
        voiceoverLines: _voiceoverLinesFromScript(geminiPlan.scriptLines),
        generationSource: _pexelsClient.isConfigured
            ? 'Gemini free tier + Pexels free API'
            : 'Gemini free tier',
      );
    }

    final clips = await _pexelsClient.searchPortraitClips(
      project.mediaSearchQuery,
    );
    if (clips.isNotEmpty) {
      project = project.copyWith(
        mediaClips: clips,
        generationSource: geminiPlan != null
            ? 'Gemini free tier + Pexels free API'
            : 'Pexels free API + local script',
      );
    }

    return project;
  }

  Future<GeneratedProject> generateRemoteVideo({
    required GeneratedProject project,
    void Function(String status)? onStatus,
  }) async {
    if (!hasRemoteReelApiConfigured) {
      throw Exception(
        'Connect your reel API in settings to enable real video generation.',
      );
    }

    onStatus?.call('Submitting your reel prompt to the remote video API...');
    var job = await _reelBackendClient.startReelJob(project);

    if (job.isFailed) {
      throw Exception(
        job.errorMessage.isNotEmpty
            ? job.errorMessage
            : 'The reel API rejected the request.',
      );
    }

    if (job.videoUrl.isEmpty) {
      if (job.jobId.isEmpty) {
        throw Exception(
          'The reel API did not return a jobId or a completed videoUrl.',
        );
      }

      for (var attempt = 1; attempt <= 40; attempt++) {
        await Future.delayed(const Duration(seconds: 3));
        onStatus?.call(
          'Generating real video on the backend... checking job ${job.jobId} ($attempt/40)',
        );
        job = await _reelBackendClient.fetchReelJob(job.jobId);
        if (job.isCompleted) {
          break;
        }
        if (job.isFailed) {
          throw Exception(
            job.errorMessage.isNotEmpty
                ? job.errorMessage
                : 'The remote reel job failed.',
          );
        }
      }
    }

    if (job.videoUrl.isEmpty) {
      throw Exception(
        'The remote reel API did not return a completed videoUrl before timeout.',
      );
    }

    final exportFileName = job.fileName.isNotEmpty
        ? job.fileName
        : project.exportFileName;

    return project.copyWith(
      captionText: job.captionText.isNotEmpty
          ? job.captionText
          : project.captionText,
      scriptLines: job.scriptLines.isNotEmpty
          ? job.scriptLines
          : project.scriptLines,
      hashtags: job.hashtags.isNotEmpty ? job.hashtags : project.hashtags,
      generationSource: 'Custom Reel API',
      exportStatus: 'Real video ready from backend API.',
      exportFileName: exportFileName,
      exportVideoSource: job.videoUrl,
      previewThumbnailUrl: job.thumbnailUrl,
      remoteJobId: job.jobId,
      remoteJobStatus: job.status,
    );
  }

  GeneratedProject buildProject({
    required String prompt,
    required String platform,
    required String tone,
    required String voice,
    required int durationSeconds,
    required bool captionsEnabled,
    required bool hookEnabled,
    required bool ctaEnabled,
    required bool watermarkFree,
  }) {
    final subject = _subjectFromPrompt(prompt);
    final slug = _slugify(subject);
    final platformSlug = platform.replaceAll(' ', '_').toLowerCase();
    final toneLine = switch (tone) {
      'Educational' => 'Explain the value clearly and keep it practical.',
      'Casual' => 'Use a relaxed voice that feels like a creator speaking.',
      'Luxury' => 'Keep the language polished, premium, and aspirational.',
      _ => 'Focus on conversion with quick benefits and urgency.',
    };

    final scriptLines = <String>[
      if (hookEnabled)
        'Open with a 2-second hook about $subject that stops the scroll.',
      'Show the main problem, then introduce $subject as the answer.',
      'Add one proof point or result the viewer can understand instantly.',
      toneLine,
      if (ctaEnabled)
        'Close with a direct CTA to follow, message, order, or visit today.',
    ];

    final shotPlan = <String>[
      'Opening close-up with text hook.',
      'Problem/benefit cut showing $subject.',
      'Social proof or product angle.',
      'Final CTA frame with brand action.',
    ];

    final captionText =
        '$subject made simple for short-form video. ${ctaEnabled ? 'Watch till the end and take action today.' : 'Built for quick, scroll-stopping value.'}';

    final hashtags = _hashtagsForPrompt(subject);
    final voiceoverLines = _voiceoverLinesFromScript(scriptLines);

    return GeneratedProject(
      prompt: prompt,
      platform: platform,
      tone: tone,
      voice: voice,
      durationSeconds: durationSeconds,
      captionsEnabled: captionsEnabled,
      hookEnabled: hookEnabled,
      ctaEnabled: ctaEnabled,
      watermarkFree: watermarkFree,
      scriptLines: scriptLines,
      shotPlan: shotPlan,
      captionText: captionText,
      hashtags: hashtags,
      voiceoverLines: voiceoverLines,
      mediaSearchQuery: subject,
      mediaClips: const [],
      generationSource: 'Local demo mode',
      voiceStatus: '$voice voice selected with ${voiceStyle(voice)} delivery.',
      editStatus:
          'Timeline prepared for ${durationSeconds}s with captions ${captionsEnabled ? 'enabled' : 'disabled'}.',
      exportStatus:
          'Export will be prepared for $platform in 1080x1920 format ${watermarkFree ? 'without' : 'with'} watermark.',
      exportFileName: '${slug}_${platformSlug}_${durationSeconds}s.mp4',
      exportVideoSource: '',
      previewThumbnailUrl: '',
      remoteJobId: '',
      remoteJobStatus: 'idle',
    );
  }

  GeneratedProject buildVoiceover({
    required GeneratedProject project,
    required String voice,
  }) {
    final style = voiceStyle(voice);
    final voiceoverLines = [
      for (final line in project.scriptLines) _voiceifyLine(line, voice),
    ];

    return project.copyWith(
      voice: voice,
      voiceoverLines: voiceoverLines,
      voiceStatus: '$voice voice selected with $style delivery.',
    );
  }

  GeneratedProject applyEdits({
    required GeneratedProject project,
    required int durationSeconds,
    required bool captionsEnabled,
    required bool hookEnabled,
    required bool ctaEnabled,
  }) {
    final updatedScript = <String>[
      if (hookEnabled)
        project.scriptLines.firstWhere(
          (line) => line.toLowerCase().contains('hook'),
          orElse: () =>
              'Open with a 2-second hook about ${_subjectFromPrompt(project.prompt)} that stops the scroll.',
        ),
      ...project.scriptLines.where(
        (line) => !line.toLowerCase().contains('hook'),
      ),
    ];

    final normalizedScript = ctaEnabled
        ? updatedScript
        : updatedScript
              .where((line) => !line.toLowerCase().contains('cta'))
              .toList();

    return project.copyWith(
      durationSeconds: durationSeconds,
      captionsEnabled: captionsEnabled,
      hookEnabled: hookEnabled,
      ctaEnabled: ctaEnabled,
      scriptLines: normalizedScript,
      editStatus:
          'Edits applied: ${captionsEnabled ? 'captions on' : 'captions off'}, ${hookEnabled ? 'strong hook' : 'soft opening'}, ${ctaEnabled ? 'CTA included' : 'CTA removed'}, ${durationSeconds}s timeline.',
    );
  }

  GeneratedProject buildExport({
    required GeneratedProject project,
    required bool watermarkFree,
  }) {
    final slug = _slugify(_subjectFromPrompt(project.prompt));
    return project.copyWith(
      watermarkFree: watermarkFree,
      exportStatus:
          'Export summary ready: 1080x1920 ${project.platform}, ${watermarkFree ? 'watermark-free' : 'with watermark'}, captions ${project.captionsEnabled ? 'embedded' : 'disabled'}.',
      exportFileName:
          '${slug}_${project.platform.replaceAll(' ', '_').toLowerCase()}_${project.durationSeconds}s${watermarkFree ? '_pro' : '_draft'}.mp4',
      remoteJobStatus: 'queued',
    );
  }

  String voiceStyle(String voice) {
    return switch (voice) {
      'Warm' => 'friendly and human',
      'Energetic' => 'fast and upbeat',
      'Calm' => 'steady and polished',
      _ => 'clear and direct',
    };
  }

  String _subjectFromPrompt(String prompt) {
    final cleaned = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 48) {
      return cleaned;
    }
    return '${cleaned.substring(0, 45)}...';
  }

  List<String> _hashtagsForPrompt(String subject) {
    final cleaned = subject
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => '#${part.toLowerCase()}')
        .toList();

    return ['#reels', '#shorts', ...cleaned];
  }

  List<String> _voiceoverLinesFromScript(List<String> lines) {
    return [for (final line in lines) line.replaceAll('CTA', 'call to action')];
  }

  String _voiceifyLine(String line, String voice) {
    final prefix = switch (voice) {
      'Warm' => 'Friendly take: ',
      'Energetic' => 'Fast take: ',
      'Calm' => 'Calm take: ',
      _ => 'Direct take: ',
    };
    return '$prefix$line';
  }

  String _slugify(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'reel_export' : normalized;
  }
}
