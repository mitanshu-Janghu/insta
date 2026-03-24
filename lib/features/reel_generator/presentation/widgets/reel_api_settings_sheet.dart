import 'package:flutter/material.dart';

import '../../domain/reel_api_config.dart';

class ReelApiSettingsSheet extends StatefulWidget {
  const ReelApiSettingsSheet({
    super.key,
    required this.initialConfig,
    required this.onSave,
    required this.onClear,
  });

  final ReelApiConfig initialConfig;
  final ValueChanged<ReelApiConfig> onSave;
  final VoidCallback onClear;

  @override
  State<ReelApiSettingsSheet> createState() => _ReelApiSettingsSheetState();
}

class _ReelApiSettingsSheetState extends State<ReelApiSettingsSheet> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _createPathController;
  late final TextEditingController _statusPathController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: widget.initialConfig.baseUrl,
    );
    _apiKeyController = TextEditingController(
      text: widget.initialConfig.apiKey,
    );
    _createPathController = TextEditingController(
      text: widget.initialConfig.createPath,
    );
    _statusPathController = TextEditingController(
      text: widget.initialConfig.statusPathTemplate,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _createPathController.dispose();
    _statusPathController.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave(
      ReelApiConfig(
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        createPath: _normalizePath(_createPathController.text, '/reels'),
        statusPathTemplate: _normalizePath(
          _statusPathController.text,
          '/reels/{jobId}',
        ),
      ),
    );
  }

  String _normalizePath(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3C42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect Reel API',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste your real backend details here so the app can request actual reel videos.',
                style: TextStyle(color: Color(0xFFB7BAC4), height: 1.35),
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _baseUrlController,
                label: 'Base URL',
                hint: 'https://your-api.com',
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _apiKeyController,
                label: 'API key',
                hint: 'Bearer token or API key',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _createPathController,
                label: 'Create path',
                hint: '/reels',
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _statusPathController,
                label: 'Status path template',
                hint: '/reels/{jobId}',
              ),
              const SizedBox(height: 16),
              const Text(
                'The status path must contain {jobId}. Example: /jobs/{jobId}',
                style: TextStyle(color: Color(0xFF8B8E98), height: 1.35),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClear,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _handleSave,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
