import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF202123);
    const surface = Color(0xFF2A2B32);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reel Generator',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10A37F),
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const ReelGeneratorHome(),
    );
  }
}

class ReelGeneratorHome extends StatefulWidget {
  const ReelGeneratorHome({super.key});

  @override
  State<ReelGeneratorHome> createState() => _ReelGeneratorHomeState();
}

class _ReelGeneratorHomeState extends State<ReelGeneratorHome> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _draftPrompt = '';
  String _selectedPlatform = 'Instagram Reel';
  String _selectedTone = 'Promotional';
  String _selectedVoice = 'Confident';
  double _durationSeconds = 30;
  bool _captionsEnabled = true;
  bool _hookEnabled = true;
  bool _ctaEnabled = true;
  bool _watermarkFree = false;

  _GeneratedProject? _project;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _MessageRole.assistant,
      title: 'Ready',
      body:
          'Describe a product, service, or creator idea and I will turn it into a short-form reel workflow.',
    ),
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendMessage(_ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 220,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _generateScript() {
    final prompt = _draftPrompt.trim().isNotEmpty
        ? _draftPrompt.trim()
        : _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a prompt first.')));
      return;
    }

    final project = _buildProject(
      prompt: prompt,
      platform: _selectedPlatform,
      tone: _selectedTone,
      voice: _selectedVoice,
      durationSeconds: _durationSeconds.round(),
      captionsEnabled: _captionsEnabled,
      hookEnabled: _hookEnabled,
      ctaEnabled: _ctaEnabled,
      watermarkFree: _watermarkFree,
    );

    setState(() {
      _project = project;
    });

    _appendMessage(
      _ChatMessage(role: _MessageRole.user, title: 'Prompt', body: prompt),
    );
    _appendMessage(
      _ChatMessage(
        role: _MessageRole.assistant,
        title: 'Script ready',
        body:
            'I created a ${project.platform.toLowerCase()} plan with ${project.scriptLines.length} beats and a ${project.durationSeconds}s runtime.',
      ),
    );
  }

  void _generateVoiceover() {
    final project = _project;
    if (project == null) {
      return;
    }

    final updated = project.copyWith(
      voice: _selectedVoice,
      voiceStatus:
          '$_selectedVoice voice selected with ${_voiceStyle(_selectedVoice)} delivery.',
    );

    setState(() {
      _project = updated;
    });

    _appendMessage(
      _ChatMessage(
        role: _MessageRole.assistant,
        title: 'Voiceover ready',
        body: updated.voiceStatus,
      ),
    );
  }

  void _applyEdits() {
    final project = _project;
    if (project == null) {
      return;
    }

    final updated = project.copyWith(
      durationSeconds: _durationSeconds.round(),
      captionsEnabled: _captionsEnabled,
      hookEnabled: _hookEnabled,
      ctaEnabled: _ctaEnabled,
      editStatus:
          'Edits applied: ${_captionsEnabled ? 'captions on' : 'captions off'}, ${_hookEnabled ? 'strong hook' : 'soft opening'}, ${_ctaEnabled ? 'CTA included' : 'CTA removed'}, ${_durationSeconds.round()}s timeline.',
    );

    setState(() {
      _project = updated;
    });

    _appendMessage(
      _ChatMessage(
        role: _MessageRole.assistant,
        title: 'Edits applied',
        body: updated.editStatus,
      ),
    );
  }

  void _prepareExport() {
    final project = _project;
    if (project == null) {
      return;
    }

    final updated = project.copyWith(
      watermarkFree: _watermarkFree,
      exportStatus:
          'Export summary ready: 1080x1920 ${project.platform}, ${_watermarkFree ? 'watermark-free' : 'with watermark'}, captions ${project.captionsEnabled ? 'embedded' : 'disabled'}.',
    );

    setState(() {
      _project = updated;
    });

    _appendMessage(
      _ChatMessage(
        role: _MessageRole.assistant,
        title: 'Export summary ready',
        body: updated.exportStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reel Generator',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'Simple workflow for script, voice, edit, and export',
              style: TextStyle(fontSize: 12, color: Color(0xFFB4B7C5)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const _InfoCard(),
                  const SizedBox(height: 16),
                  for (final message in _messages) ...[
                    _MessageBubble(message: message),
                    const SizedBox(height: 12),
                  ],
                  if (project != null) ...[
                    _SectionCard(
                      title: 'Generated script',
                      subtitle:
                          '${project.platform} • ${project.durationSeconds}s',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryLine(label: 'Idea', value: project.prompt),
                          const SizedBox(height: 12),
                          for (var i = 0; i < project.scriptLines.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _StepLine(
                                index: i + 1,
                                text: project.scriptLines[i],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Voice',
                      subtitle: 'Choose a style and generate the voiceover',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final voice in _voiceOptions)
                                ChoiceChip(
                                  label: Text(voice),
                                  selected: _selectedVoice == voice,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedVoice = voice;
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _PrimaryButton(
                            label: 'Make Voiceover',
                            onPressed: _generateVoiceover,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            project.voiceStatus,
                            style: const TextStyle(color: Color(0xFFB4B7C5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Edit',
                      subtitle: 'Adjust runtime and content controls',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration: ${_durationSeconds.round()} seconds',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Slider(
                            value: _durationSeconds,
                            min: 15,
                            max: 60,
                            divisions: 9,
                            label: '${_durationSeconds.round()}',
                            onChanged: (value) {
                              setState(() {
                                _durationSeconds = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Captions'),
                            value: _captionsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _captionsEnabled = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Strong opening hook'),
                            value: _hookEnabled,
                            onChanged: (value) {
                              setState(() {
                                _hookEnabled = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Call to action'),
                            value: _ctaEnabled,
                            onChanged: (value) {
                              setState(() {
                                _ctaEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _PrimaryButton(
                            label: 'Apply Edits',
                            onPressed: _applyEdits,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            project.editStatus,
                            style: const TextStyle(color: Color(0xFFB4B7C5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Export',
                      subtitle: 'Prepare the final social-ready output',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Watermark-free export'),
                            value: _watermarkFree,
                            onChanged: (value) {
                              setState(() {
                                _watermarkFree = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _PrimaryButton(
                            label: 'Prepare Export',
                            onPressed: _prepareExport,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            project.exportStatus,
                            style: const TextStyle(color: Color(0xFFB4B7C5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _ComposerCard(
              promptController: _promptController,
              selectedPlatform: _selectedPlatform,
              selectedTone: _selectedTone,
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

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.promptController,
    required this.selectedPlatform,
    required this.selectedTone,
    required this.onPromptChanged,
    required this.onPlatformChanged,
    required this.onToneChanged,
    required this.onGenerate,
  });

  final TextEditingController promptController;
  final String selectedPlatform;
  final String selectedTone;
  final ValueChanged<String> onPromptChanged;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onToneChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF202123),
        border: Border(top: BorderSide(color: Color(0xFF333640))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: promptController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.send,
            onChanged: onPromptChanged,
            onSubmitted: (_) => onGenerate(),
            decoration: const InputDecoration(
              hintText:
                  'Create a reel for a cafe launch, product ad, fitness tip, or any other idea...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  value: selectedPlatform,
                  items: _platformOptions,
                  onChanged: onPlatformChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownField(
                  value: selectedTone,
                  items: _toneOptions,
                  onChanged: onToneChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onGenerate,
              child: const Text('Generate Script'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2B32),
          items: [
            for (final item in items)
              DropdownMenuItem<String>(value: item, child: Text(item)),
          ],
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'How it works',
      subtitle: 'Simple flow, similar to a chat workspace',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepLine(index: 1, text: 'Write a prompt for your reel or short.'),
          SizedBox(height: 8),
          _StepLine(
            index: 2,
            text: 'Generate a script and then build voiceover.',
          ),
          SizedBox(height: 8),
          _StepLine(
            index: 3,
            text: 'Apply edits and prepare the final export.',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFFB4B7C5))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF343541) : const Color(0xFF2A2B32),
            borderRadius: BorderRadius.circular(16),
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
                style: const TextStyle(color: Color(0xFFE6E8EF), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF10A37F).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: Color(0xFF10A37F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFE6E8EF), height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFFE6E8EF), height: 1.4),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _GeneratedProject {
  const _GeneratedProject({
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
    required this.voiceStatus,
    required this.editStatus,
    required this.exportStatus,
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
  final String voiceStatus;
  final String editStatus;
  final String exportStatus;

  _GeneratedProject copyWith({
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
    String? voiceStatus,
    String? editStatus,
    String? exportStatus,
  }) {
    return _GeneratedProject(
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
      voiceStatus: voiceStatus ?? this.voiceStatus,
      editStatus: editStatus ?? this.editStatus,
      exportStatus: exportStatus ?? this.exportStatus,
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.title,
    required this.body,
  });

  final _MessageRole role;
  final String title;
  final String body;
}

enum _MessageRole { user, assistant }

const List<String> _platformOptions = ['Instagram Reel', 'YouTube Short'];

const List<String> _toneOptions = [
  'Promotional',
  'Educational',
  'Casual',
  'Luxury',
];

const List<String> _voiceOptions = ['Confident', 'Warm', 'Energetic', 'Calm'];

_GeneratedProject _buildProject({
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

  return _GeneratedProject(
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
    voiceStatus: '$voice voice selected with ${_voiceStyle(voice)} delivery.',
    editStatus:
        'Timeline prepared for ${durationSeconds}s with captions ${captionsEnabled ? 'enabled' : 'disabled'}.',
    exportStatus:
        'Export will be prepared for $platform in 1080x1920 format ${watermarkFree ? 'without' : 'with'} watermark.',
  );
}

String _subjectFromPrompt(String prompt) {
  final cleaned = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.length <= 48) {
    return cleaned;
  }
  return '${cleaned.substring(0, 45)}...';
}

String _voiceStyle(String voice) {
  return switch (voice) {
    'Warm' => 'friendly and human',
    'Energetic' => 'fast and upbeat',
    'Calm' => 'steady and polished',
    _ => 'clear and direct',
  };
}
