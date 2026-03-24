enum MessageRole { user, assistant }

class StockClip {
  const StockClip({
    required this.source,
    required this.title,
    required this.pageUrl,
    required this.fileUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
  });

  final String source;
  final String title;
  final String pageUrl;
  final String fileUrl;
  final String thumbnailUrl;
  final int durationSeconds;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.title,
    required this.body,
    this.previewProject,
  });

  final MessageRole role;
  final String title;
  final String body;
  final GeneratedProject? previewProject;
}

class GeneratedProject {
  const GeneratedProject({
    required this.prompt,
    required this.platform,
    required this.tone,
    required this.voice,
    required this.durationSeconds,
    required this.captionsEnabled,
    required this.hookEnabled,
    required this.ctaEnabled,
    required this.watermarkFree,
    required this.scriptLines,
    required this.shotPlan,
    required this.captionText,
    required this.hashtags,
    required this.voiceoverLines,
    required this.mediaSearchQuery,
    required this.mediaClips,
    required this.generationSource,
    required this.voiceStatus,
    required this.editStatus,
    required this.exportStatus,
    required this.exportFileName,
    required this.exportVideoSource,
    required this.previewThumbnailUrl,
    required this.remoteJobId,
    required this.remoteJobStatus,
  });

  final String prompt;
  final String platform;
  final String tone;
  final String voice;
  final int durationSeconds;
  final bool captionsEnabled;
  final bool hookEnabled;
  final bool ctaEnabled;
  final bool watermarkFree;
  final List<String> scriptLines;
  final List<String> shotPlan;
  final String captionText;
  final List<String> hashtags;
  final List<String> voiceoverLines;
  final String mediaSearchQuery;
  final List<StockClip> mediaClips;
  final String generationSource;
  final String voiceStatus;
  final String editStatus;
  final String exportStatus;
  final String exportFileName;
  final String exportVideoSource;
  final String previewThumbnailUrl;
  final String remoteJobId;
  final String remoteJobStatus;

  GeneratedProject copyWith({
    String? prompt,
    String? platform,
    String? tone,
    String? voice,
    int? durationSeconds,
    bool? captionsEnabled,
    bool? hookEnabled,
    bool? ctaEnabled,
    bool? watermarkFree,
    List<String>? scriptLines,
    List<String>? shotPlan,
    String? captionText,
    List<String>? hashtags,
    List<String>? voiceoverLines,
    String? mediaSearchQuery,
    List<StockClip>? mediaClips,
    String? generationSource,
    String? voiceStatus,
    String? editStatus,
    String? exportStatus,
    String? exportFileName,
    String? exportVideoSource,
    String? previewThumbnailUrl,
    String? remoteJobId,
    String? remoteJobStatus,
  }) {
    return GeneratedProject(
      prompt: prompt ?? this.prompt,
      platform: platform ?? this.platform,
      tone: tone ?? this.tone,
      voice: voice ?? this.voice,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      hookEnabled: hookEnabled ?? this.hookEnabled,
      ctaEnabled: ctaEnabled ?? this.ctaEnabled,
      watermarkFree: watermarkFree ?? this.watermarkFree,
      scriptLines: scriptLines ?? this.scriptLines,
      shotPlan: shotPlan ?? this.shotPlan,
      captionText: captionText ?? this.captionText,
      hashtags: hashtags ?? this.hashtags,
      voiceoverLines: voiceoverLines ?? this.voiceoverLines,
      mediaSearchQuery: mediaSearchQuery ?? this.mediaSearchQuery,
      mediaClips: mediaClips ?? this.mediaClips,
      generationSource: generationSource ?? this.generationSource,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      editStatus: editStatus ?? this.editStatus,
      exportStatus: exportStatus ?? this.exportStatus,
      exportFileName: exportFileName ?? this.exportFileName,
      exportVideoSource: exportVideoSource ?? this.exportVideoSource,
      previewThumbnailUrl: previewThumbnailUrl ?? this.previewThumbnailUrl,
      remoteJobId: remoteJobId ?? this.remoteJobId,
      remoteJobStatus: remoteJobStatus ?? this.remoteJobStatus,
    );
  }
}

const List<String> platformOptions = ['Instagram Reel', 'YouTube Short'];

const List<String> toneOptions = [
  'Promotional',
  'Educational',
  'Casual',
  'Luxury',
];

const List<String> voiceOptions = ['Confident', 'Warm', 'Energetic', 'Calm'];
