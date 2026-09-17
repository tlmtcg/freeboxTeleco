import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerView extends StatefulWidget {
  final VideoController controller;

  const VideoPlayerView({super.key, required this.controller});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  bool _fullscreen = false;

  void _toggleFullscreen() {
    setState(() {
      _fullscreen = !_fullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Video(
            controller: widget.controller,
            fit: _fullscreen ? BoxFit.cover : BoxFit.contain,
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            onPressed: _toggleFullscreen,
            tooltip: _fullscreen
                ? 'Afficher l’image entière'
                : 'Remplir l’écran',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.65),
              foregroundColor: Colors.white,
            ),
            icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ),
      ],
    );
  }
}
