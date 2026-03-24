import 'package:flutter_test/flutter_test.dart';
import 'package:insta_reel_gen/features/reel_generator/domain/reel_generator_service.dart';

void main() {
  final service = ReelGeneratorService();

  test('buildProject creates script, caption, hashtags, and export file', () {
    final project = service.buildProject(
      prompt: 'Create a reel for a coffee shop launch',
      platform: 'Instagram Reel',
      tone: 'Promotional',
      voice: 'Confident',
      durationSeconds: 30,
      captionsEnabled: true,
      hookEnabled: true,
      ctaEnabled: true,
      watermarkFree: false,
    );

    expect(project.scriptLines, isNotEmpty);
    expect(project.captionText, contains('coffee shop launch'));
    expect(project.hashtags, contains('#reels'));
    expect(project.exportFileName, endsWith('.mp4'));
  });

  test('buildVoiceover updates voice and voiceover lines', () {
    final project = service.buildProject(
      prompt: 'Create a reel for a coffee shop launch',
      platform: 'Instagram Reel',
      tone: 'Promotional',
      voice: 'Confident',
      durationSeconds: 30,
      captionsEnabled: true,
      hookEnabled: true,
      ctaEnabled: true,
      watermarkFree: false,
    );

    final updated = service.buildVoiceover(project: project, voice: 'Warm');

    expect(updated.voice, 'Warm');
    expect(updated.voiceStatus, contains('Warm voice selected'));
    expect(updated.voiceoverLines.first, contains('Friendly take:'));
  });

  test('applyEdits updates edit state', () {
    final project = service.buildProject(
      prompt: 'Create a reel for a coffee shop launch',
      platform: 'Instagram Reel',
      tone: 'Promotional',
      voice: 'Confident',
      durationSeconds: 30,
      captionsEnabled: true,
      hookEnabled: true,
      ctaEnabled: true,
      watermarkFree: false,
    );

    final updated = service.applyEdits(
      project: project,
      durationSeconds: 45,
      captionsEnabled: false,
      hookEnabled: false,
      ctaEnabled: false,
    );

    expect(updated.durationSeconds, 45);
    expect(updated.captionsEnabled, isFalse);
    expect(updated.editStatus, contains('captions off'));
  });

  test('buildExport updates export summary and filename', () {
    final project = service.buildProject(
      prompt: 'Create a reel for a coffee shop launch',
      platform: 'Instagram Reel',
      tone: 'Promotional',
      voice: 'Confident',
      durationSeconds: 30,
      captionsEnabled: true,
      hookEnabled: true,
      ctaEnabled: true,
      watermarkFree: false,
    );

    final updated = service.buildExport(project: project, watermarkFree: true);

    expect(updated.watermarkFree, isTrue);
    expect(updated.exportStatus, contains('watermark-free'));
    expect(updated.exportFileName, contains('_pro.mp4'));
  });
}
