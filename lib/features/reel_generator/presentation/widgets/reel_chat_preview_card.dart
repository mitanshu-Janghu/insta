import 'package:flutter/material.dart';

import '../../domain/reel_generator_models.dart';

class ReelChatPreviewCard extends StatelessWidget {
  const ReelChatPreviewCard({super.key, required this.project, this.onTap});

  final GeneratedProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clip = project.mediaClips.isEmpty ? null : project.mediaClips.first;
    final thumbnailUrl = project.previewThumbnailUrl.isNotEmpty
        ? project.previewThumbnailUrl
        : clip?.thumbnailUrl ?? '';
    final headline = project.shotPlan.isEmpty
        ? project.prompt
        : project.shotPlan.first;
    final subline = project.voiceoverLines.isEmpty
        ? project.captionText
        : project.voiceoverLines.first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl.isNotEmpty)
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PreviewFallback(),
                )
              else
                const _PreviewFallback(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Color(0x44000000),
                      Color(0xDD000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xAA10A37F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    project.platform,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 62,
                  color: Colors.white,
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF1F2F4),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

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
    );
  }
}
