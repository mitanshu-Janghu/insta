import 'package:flutter/material.dart';

class ComposerPanel extends StatelessWidget {
  const ComposerPanel({
    super.key,
    required this.promptController,
    required this.selectedPlatform,
    required this.selectedTone,
    required this.isGenerating,
    required this.onPromptChanged,
    required this.onPlatformChanged,
    required this.onToneChanged,
    required this.onGenerate,
  });

  final TextEditingController promptController;
  final String selectedPlatform;
  final String selectedTone;
  final bool isGenerating;
  final ValueChanged<String> onPromptChanged;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onToneChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF131416),
        border: Border(top: BorderSide(color: Color(0xFF23252B))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$selectedPlatform • $selectedTone',
                style: const TextStyle(
                  color: Color(0xFF8B8E98),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F23),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF2A2C33)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('prompt_input'),
                      controller: promptController,
                      enabled: !isGenerating,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onChanged: onPromptChanged,
                      onSubmitted: (_) => onGenerate(),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        hintText: 'Ask for a reel and get script + video',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('send_button'),
                    onPressed: isGenerating ? null : onGenerate,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF10A37F),
                      foregroundColor: Colors.white,
                    ),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
