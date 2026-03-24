import 'package:flutter/material.dart';

import '../../domain/reel_generator_models.dart';
import 'local_video_player_card.dart';
import 'reel_chat_preview_card.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({super.key, required this.message, this.onPreviewTap});

  final ChatMessage message;
  final VoidCallback? onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final previewProject = message.previewProject;
    final exportedVideoPath = previewProject?.exportVideoSource ?? '';
    final showExportedVideo = exportedVideoPath.toLowerCase().endsWith('.mp4');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFF10A37F),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2B2D33)
                    : const Color(0xFF18191D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.body,
                    style: const TextStyle(
                      color: Color(0xFFE4E6EB),
                      height: 1.4,
                    ),
                  ),
                  if (previewProject != null) ...[
                    const SizedBox(height: 12),
                    if (showExportedVideo)
                      LocalVideoPlayerCard(
                        videoSource: exportedVideoPath,
                        onTap: onPreviewTap,
                      )
                    else
                      ReelChatPreviewCard(
                        project: previewProject,
                        onTap: onPreviewTap,
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
