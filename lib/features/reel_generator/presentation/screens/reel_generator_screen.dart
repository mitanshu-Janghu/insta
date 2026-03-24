import 'package:flutter/material.dart';

import '../../domain/reel_api_config.dart';
import '../../domain/reel_generator_models.dart';
import '../../domain/reel_generator_service.dart';
import '../../infrastructure/reel_api_config_store.dart';
import '../widgets/chat_message_tile.dart';
import '../widgets/reel_api_settings_sheet.dart';
import '../widgets/composer_panel.dart';
import '../widgets/reel_preview_sheet.dart';
import '../widgets/surface_card.dart';

class ReelGeneratorScreen extends StatefulWidget {
  const ReelGeneratorScreen({super.key});

  @override
  State<ReelGeneratorScreen> createState() => _ReelGeneratorScreenState();
}

class _ReelGeneratorScreenState extends State<ReelGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ReelGeneratorService _service = ReelGeneratorService();
  final ReelApiConfigStore _configStore = ReelApiConfigStore();

  String _draftPrompt = '';
  String _selectedPlatform = platformOptions.first;
  String _selectedTone = toneOptions.first;
  bool _isGenerating = false;
  String _generationStatus = 'Generating script...';

  final List<ChatMessage> _messages = const [
    ChatMessage(
      role: MessageRole.assistant,
      title: 'Reel GPT',
      body:
          'Send one prompt and I will reply with the script plus a reel video in chat.',
    ),
  ].toList();

  @override
  void initState() {
    super.initState();
    _loadApiConfig();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiConfig() async {
    final config = await _configStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _service.updateRemoteConfig(config);
    });
  }

  Future<void> _openApiSettings() async {
    final result = await showModalBottomSheet<_ApiSettingsAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131416),
      builder: (context) {
        return ReelApiSettingsSheet(
          initialConfig: _service.remoteConfig,
          onSave: (config) {
            Navigator.of(context).pop(_ApiSettingsAction.save(config));
          },
          onClear: () {
            Navigator.of(context).pop(_ApiSettingsAction.clear());
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result.clearRequested) {
      await _configStore.clear();
      if (!mounted) {
        return;
      }
      setState(() {
        _service.updateRemoteConfig(ReelApiConfig.fromEnvironment());
      });
      _appendMessage(
        const ChatMessage(
          role: MessageRole.assistant,
          title: 'API disconnected',
          body:
              'Real video API settings were cleared. The app will stop at the script until you reconnect a real reel backend.',
        ),
      );
      return;
    }

    final config = result.config;
    if (config == null) {
      return;
    }
    await _configStore.save(config);
    if (!mounted) {
      return;
    }
    setState(() {
      _service.updateRemoteConfig(config);
    });
    _appendMessage(
      ChatMessage(
        role: MessageRole.assistant,
        title: 'API connected',
        body: config.isConfigured
            ? 'Real reel API connected. New prompts will use ${config.baseUrl}.'
            : 'API settings saved, but the base URL is still empty.',
      ),
    );
  }

  void _appendMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applySuggestion(String value) {
    _promptController.text = value;
    setState(() {
      _draftPrompt = value;
    });
  }

  Future<void> _generateScript() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final prompt = _draftPrompt.trim().isNotEmpty
        ? _draftPrompt.trim()
        : _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a prompt first.')));
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Writing your reel script...';
    });

    _appendMessage(
      ChatMessage(role: MessageRole.user, title: 'Prompt', body: prompt),
    );

    try {
      final project = await _service.generateProject(
        prompt: prompt,
        platform: _selectedPlatform,
        tone: _selectedTone,
        voice: voiceOptions.first,
        durationSeconds: 30,
        captionsEnabled: true,
        hookEnabled: true,
        ctaEnabled: true,
        watermarkFree: false,
      );
      if (!mounted) {
        return;
      }

      _appendMessage(
        ChatMessage(
          role: MessageRole.assistant,
          title: 'Script',
          body: _scriptBody(project),
        ),
      );

      setState(() {
        _generationStatus = _service.hasRemoteReelApiConfigured
            ? 'Making your reel video...'
            : 'Waiting for a real reel API connection...';
      });

      final prepared = _service.buildExport(
        project: project,
        watermarkFree: false,
      );

      if (!_service.hasRemoteReelApiConfigured) {
        if (!mounted) {
          return;
        }
        setState(() {
          _draftPrompt = '';
          _promptController.clear();
          _isGenerating = false;
        });
        _appendMessage(
          const ChatMessage(
            role: MessageRole.assistant,
            title: 'Video not generated',
            body:
                'No real reel API is connected. Open settings, connect your backend, and then I will return a real video instead of a fake one.',
          ),
        );
        return;
      }

      final videoProject = await _service.generateRemoteVideo(
        project: prepared,
        onStatus: (status) {
          if (!mounted) {
            return;
          }
          setState(() {
            _generationStatus = status;
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _draftPrompt = '';
        _promptController.clear();
        _isGenerating = false;
      });

      _appendMessage(
        ChatMessage(
          role: MessageRole.assistant,
          title: 'Video',
          body: 'Your reel video is ready. Tap the video to preview it.',
          previewProject: videoProject,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
      });

      _appendMessage(
        ChatMessage(
          role: MessageRole.assistant,
          title: 'Generation failed',
          body: error.toString(),
        ),
      );
    }
  }

  String _scriptBody(GeneratedProject project) {
    final buffer = StringBuffer();
    buffer.writeln('Caption: ${project.captionText}');
    buffer.writeln();
    for (var i = 0; i < project.scriptLines.length; i++) {
      buffer.writeln('${i + 1}. ${project.scriptLines[i]}');
    }
    return buffer.toString().trim();
  }

  void _openPreview(GeneratedProject? project) {
    if (project == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReelPreviewSheet(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Reel Generator',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'ChatGPT-style mobile workspace',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B8E98)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openApiSettings,
            tooltip: 'Connect API',
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  _HeaderBlock(
                    statusLabel: _service.apiStatusLabel,
                    onConnectApi: _openApiSettings,
                    apiConnected: _service.hasRemoteReelApiConfigured,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _suggestions)
                        ActionChip(
                          label: Text(item),
                          onPressed: () => _applySuggestion(item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final message in _messages)
                    ChatMessageTile(
                      message: message,
                      onPreviewTap: message.previewProject == null
                          ? null
                          : () => _openPreview(message.previewProject),
                    ),
                  if (_isGenerating)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: SurfaceCard(
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generationStatus,
                                style: const TextStyle(
                                  color: Color(0xFFB7BAC4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ComposerPanel(
              promptController: _promptController,
              selectedPlatform: _selectedPlatform,
              selectedTone: _selectedTone,
              isGenerating: _isGenerating,
              onPromptChanged: (value) {
                setState(() {
                  _draftPrompt = value;
                });
              },
              onPlatformChanged: (value) {
                setState(() {
                  _selectedPlatform = value;
                });
              },
              onToneChanged: (value) {
                setState(() {
                  _selectedTone = value;
                });
              },
              onGenerate: _generateScript,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.statusLabel,
    required this.onConnectApi,
    required this.apiConnected,
  });

  final String statusLabel;
  final VoidCallback onConnectApi;
  final bool apiConnected;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type one prompt. The app replies with the script first and then the reel video in the same chat.',
            style: TextStyle(color: Color(0xFFB7BAC4), height: 1.4),
          ),
          const SizedBox(height: 10),
          _StatusPill(label: statusLabel),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onConnectApi,
              icon: Icon(
                apiConnected ? Icons.link_off_rounded : Icons.link_rounded,
                size: 18,
              ),
              label: Text(apiConnected ? 'Update API' : 'Connect API'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF15352E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9CE9D4),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

const List<String> _suggestions = [
  'Cafe launch reel',
  'Product ad script',
  'Fitness tip short',
  'Skincare brand promo',
];

class _ApiSettingsAction {
  const _ApiSettingsAction._({this.config, required this.clearRequested});

  factory _ApiSettingsAction.save(ReelApiConfig config) {
    return _ApiSettingsAction._(config: config, clearRequested: false);
  }

  factory _ApiSettingsAction.clear() {
    return const _ApiSettingsAction._(clearRequested: true);
  }

  final ReelApiConfig? config;
  final bool clearRequested;
}
