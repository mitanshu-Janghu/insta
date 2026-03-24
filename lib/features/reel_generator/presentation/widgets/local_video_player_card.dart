import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPlayerCard extends StatefulWidget {
  const LocalVideoPlayerCard({
    super.key,
    required this.videoSource,
    this.onTap,
    this.borderRadius = 20,
    this.aspectRatio = 9 / 16,
  });

  final String videoSource;
  final VoidCallback? onTap;
  final double borderRadius;
  final double aspectRatio;

  @override
  State<LocalVideoPlayerCard> createState() => _LocalVideoPlayerCardState();
}

class _LocalVideoPlayerCardState extends State<LocalVideoPlayerCard> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  bool get _isRemoteVideo {
    final uri = Uri.tryParse(widget.videoSource);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        widget.videoSource.toLowerCase().endsWith('.mp4');
  }

  bool get _hasPlayableVideo {
    if (widget.videoSource.isEmpty ||
        !widget.videoSource.toLowerCase().endsWith('.mp4')) {
      return false;
    }
    if (_isRemoteVideo) {
      return true;
    }
    return File(widget.videoSource).existsSync();
  }

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant LocalVideoPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoSource != widget.videoSource) {
      _disposeController();
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _loadVideo() {
    if (!_hasPlayableVideo) {
      if (mounted) {
        setState(() {
          _initializeFuture = null;
        });
      }
      return;
    }

    final controller = _isRemoteVideo
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoSource))
        : VideoPlayerController.file(File(widget.videoSource));
    final initializeFuture = controller.initialize().then((_) async {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    });

    setState(() {
      _controller = controller;
      _initializeFuture = initializeFuture;
    });
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPlayableVideo ||
        _controller == null ||
        _initializeFuture == null) {
      return _UnavailableVideoCard(onTap: widget.onTap);
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFF101114),
                child: FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (snapshot.hasError ||
                        !_controller!.value.isInitialized) {
                      return const _VideoErrorState();
                    }

                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    );
                  },
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11000000),
                      Color(0x22000000),
                      Color(0x99000000),
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
                    color: const Color(0xCC10A37F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  'Exported video preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableVideoCard extends StatelessWidget {
  const _UnavailableVideoCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A35),
                  Color(0xFF17252B),
                  Color(0xFF111215),
                ],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_file_outlined,
                  color: Colors.white70,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Exported video not available yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Generate the reel to see the real video here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFCFD2D8), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'This MP4 was created, but it could not be played here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, height: 1.4),
        ),
      ),
    );
  }
}
