import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/reel_generator_models.dart';

class LocalExportResult {
  const LocalExportResult({
    required this.outputPath,
    required this.renderMode,
    required this.videoSource,
  });

  final String outputPath;
  final String renderMode;
  final String videoSource;
}

class LocalVideoExporter {
  Future<LocalExportResult> exportProject(GeneratedProject project) async {
    final root = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${root.path}/reel_exports/${DateTime.now().millisecondsSinceEpoch}',
    );
    await exportDir.create(recursive: true);

    final outputPath = '${exportDir.path}/${project.exportFileName}';
    final stockVideoCreated = await _tryExportFromStockClips(
      project,
      exportDir,
      outputPath,
    );

    if (!stockVideoCreated) {
      await _exportFromRenderedFrames(project, exportDir, outputPath);
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw Exception('Video export finished but no MP4 file was created.');
    }
    final fileSize = await outputFile.length();
    if (fileSize == 0) {
      throw Exception('Video export created an empty MP4 file.');
    }

    return LocalExportResult(
      outputPath: outputPath,
      renderMode: stockVideoCreated ? 'stock-video' : 'fallback-frames',
      videoSource: outputPath,
    );
  }

  Future<void> _exportFromRenderedFrames(
    GeneratedProject project,
    Directory exportDir,
    String outputPath,
  ) async {
    final sceneCount = _sceneCount(project);
    for (var i = 0; i < sceneCount; i++) {
      final bytes = await _renderSceneFrame(project, i);
      final file = File(
        '${exportDir.path}/frame_${i.toString().padLeft(3, '0')}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
    }

    final framePattern = '${exportDir.path}/frame_%03d.png';
    final command =
        '-y -framerate 1/3 -i "$framePattern" -vf "fps=30,format=yuv420p" -c:v mpeg4 "$outputPath"';
    await _runFfmpeg(command);
  }

  Future<bool> _tryExportFromStockClips(
    GeneratedProject project,
    Directory exportDir,
    String outputPath,
  ) async {
    final usableClips = project.mediaClips
        .where((clip) => clip.fileUrl.isNotEmpty)
        .take(3)
        .toList();
    if (usableClips.isEmpty) {
      return false;
    }

    final downloadedClips = <File>[];
    for (var i = 0; i < usableClips.length; i++) {
      final file = await _downloadClip(
        usableClips[i].fileUrl,
        File('${exportDir.path}/source_${i.toString().padLeft(3, '0')}.mp4'),
      );
      if (file != null) {
        downloadedClips.add(file);
      }
    }

    if (downloadedClips.isEmpty) {
      return false;
    }

    final segmentCount = _segmentCount(project);
    final segmentDuration = project.durationSeconds / segmentCount;
    final segmentPaths = <String>[];

    try {
      for (var i = 0; i < segmentCount; i++) {
        final inputFile = downloadedClips[i % downloadedClips.length];
        final segmentPath =
            '${exportDir.path}/segment_${i.toString().padLeft(3, '0')}.mp4';
        final command =
            '-y -stream_loop -1 -i "${inputFile.path}" '
            '-t ${segmentDuration.toStringAsFixed(2)} '
            '-vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,format=yuv420p" '
            '-an -c:v mpeg4 "$segmentPath"';
        await _runFfmpeg(command);
        segmentPaths.add(segmentPath);
      }

      final concatFile = File('${exportDir.path}/segments.txt');
      await concatFile.writeAsString(
        segmentPaths
            .map((path) => "file '${path.replaceAll("'", r"'\''")}'")
            .join('\n'),
        flush: true,
      );
      final concatCommand =
          '-y -f concat -safe 0 -i "${concatFile.path}" -c:v mpeg4 -an "$outputPath"';
      await _runFfmpeg(concatCommand);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File?> _downloadClip(String url, File targetFile) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      if (bytes.isEmpty) {
        return null;
      }

      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _runFfmpeg(String command) async {
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getOutput();
      throw Exception(logs ?? 'Video export failed.');
    }
  }

  int _segmentCount(GeneratedProject project) {
    final basedOnDuration = (project.durationSeconds / 4).round();
    return basedOnDuration.clamp(3, 6);
  }

  int _sceneCount(GeneratedProject project) {
    final counts = [
      project.shotPlan.length,
      project.voiceoverLines.length,
      project.scriptLines.length,
      1,
    ];
    counts.sort();
    return counts.last;
  }

  Future<Uint8List> _renderSceneFrame(
    GeneratedProject project,
    int index,
  ) async {
    const width = 1080.0;
    const height = 1920.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF17352F), Color(0xFF132128), Color(0xFF0D0F12)],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), background);

    final accent = Paint()
      ..color = const Color(0xFF10A37F).withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(54, 84, width - 108, 116),
        const Radius.circular(28),
      ),
      accent,
    );

    _paintText(
      canvas,
      'REEL GENERATOR',
      const Offset(86, 126),
      42,
      FontWeight.w700,
      const Color(0xFFFFFFFF),
      maxWidth: width - 172,
    );

    _paintText(
      canvas,
      'Scene ${index + 1}',
      const Offset(86, 270),
      34,
      FontWeight.w600,
      const Color(0xFF9CE9D4),
      maxWidth: width - 172,
    );

    final shot = project.shotPlan[index % project.shotPlan.length];
    final voice = project.voiceoverLines[index % project.voiceoverLines.length];

    _paintText(
      canvas,
      shot,
      const Offset(86, 342),
      72,
      FontWeight.w700,
      const Color(0xFFFFFFFF),
      maxWidth: width - 172,
    );

    _paintText(
      canvas,
      voice,
      const Offset(86, 650),
      50,
      FontWeight.w500,
      const Color(0xFFE7ECEF),
      maxWidth: width - 172,
    );

    _paintText(
      canvas,
      project.captionText,
      const Offset(86, 1160),
      42,
      FontWeight.w400,
      const Color(0xFFBFC5CC),
      maxWidth: width - 172,
    );

    _paintText(
      canvas,
      project.hashtags.join(' '),
      const Offset(86, 1440),
      34,
      FontWeight.w500,
      const Color(0xFF10A37F),
      maxWidth: width - 172,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(86, height - 230, width - 172, 110),
        const Radius.circular(30),
      ),
      Paint()..color = const Color(0xFF1B1E22),
    );

    _paintText(
      canvas,
      project.platform,
      Offset(126, height - 195),
      34,
      FontWeight.w600,
      const Color(0xFFFFFFFF),
      maxWidth: width - 252,
    );

    _paintText(
      canvas,
      '${project.durationSeconds}s • ${project.watermarkFree ? 'watermark-free' : 'draft export'}',
      Offset(126, height - 148),
      28,
      FontWeight.w400,
      const Color(0xFFB7BAC4),
      maxWidth: width - 252,
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to render export frame.');
    }
    return byteData.buffer.asUint8List();
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    FontWeight weight,
    Color color, {
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 10,
    )..layout(maxWidth: maxWidth);

    textPainter.paint(canvas, offset);
  }
}
