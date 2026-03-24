import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/reel_generator_models.dart';
import 'local_video_player_card.dart';

class ReelPreviewSheet extends StatefulWidget {
  const ReelPreviewSheet({super.key, required this.project});

  final GeneratedProject project;

  @override
  State<ReelPreviewSheet> createState() => _ReelPreviewSheetState();
}

class _ReelPreviewSheetState extends State<ReelPreviewSheet> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  bool get _hasExportedVideo {
    final source = widget.project.exportVideoSource;
    if (!source.toLowerCase().endsWith('.mp4')) {
      return false;
    }
    final uri = Uri.tryParse(source);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return true;
    }
    if (!source.startsWith('/')) {
      return false;
    }
    return File(source).existsSync();
  }

  int get _sceneCount {
    final counts = [
      widget.project.shotPlan.length,
      widget.project.voiceoverLines.length,
      widget.project.mediaClips.length,
      1,
    ];
    counts.sort();
    return counts.last;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (_hasExportedVideo) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _sceneCount <= 1) {
        return;
      }
      final next = (_currentIndex + 1) % _sceneCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1012),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3C42),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reel Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasExportedVideo
                            ? 'Your exported MP4 is ready. Play it here or close this sheet to keep chatting.'
                            : 'Browse the generated reel scenes here before exporting the MP4.',
                        style: TextStyle(
                          color: Color(0xFFB7BAC4),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _hasExportedVideo
                  ? LocalVideoPlayerCard(
                      videoSource: widget.project.exportVideoSource,
                      borderRadius: 28,
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _sceneCount,
                      onPageChanged: (value) {
                        setState(() {
                          _currentIndex = value;
                        });
                      },
                      itemBuilder: (context, index) {
                        final clip = widget.project.mediaClips.isEmpty
                            ? null
                            : widget.project.mediaClips[index %
                                  widget.project.mediaClips.length];
                        final shot = widget.project.shotPlan.isEmpty
                            ? 'Scene ${index + 1}'
                            : widget.project.shotPlan[index %
                                  widget.project.shotPlan.length];
                        final voiceLine = widget.project.voiceoverLines.isEmpty
                            ? widget.project.captionText
                            : widget.project.voiceoverLines[index %
                                  widget.project.voiceoverLines.length];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (clip != null && clip.thumbnailUrl.isNotEmpty)
                                Image.network(
                                  clip.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _FallbackScene(),
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) {
                                      return child;
                                    }
                                    return const _FallbackScene();
                                  },
                                )
                              else
                                const _FallbackScene(),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x22000000),
                                      Color(0x33000000),
                                      Color(0xDD000000),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 18,
                                left: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x9910A37F),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Scene ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shot,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      voiceLine,
                                      style: const TextStyle(
                                        color: Color(0xFFF1F2F4),
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.project.captionText,
                                      style: const TextStyle(
                                        color: Color(0xFFB7BAC4),
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (!_hasExportedVideo) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _sceneCount; i++)
                  Container(
                    width: i == _currentIndex ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? const Color(0xFF10A37F)
                          : const Color(0xFF4A4D55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B1F),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Export target: ${widget.project.exportFileName}',
                style: const TextStyle(color: Color(0xFFB7BAC4), height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackScene extends StatelessWidget {
  const _FallbackScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A35), Color(0xFF17252B), Color(0xFF111215)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 64,
          color: Color(0x5510A37F),
        ),
      ),
    );
  }
}
