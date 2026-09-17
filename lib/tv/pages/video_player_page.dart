import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'dart:async';
import 'video_settings_page.dart';
import '../models/tv_channel.dart';
import '../player/video_player_service.dart';
import '../widgets/video_channel_overlay.dart';
import 'video_error_view.dart';

class VideoPlayerPage extends StatefulWidget {
  final TvChannel channel;
  final String streamUrl;

  const VideoPlayerPage({
    super.key,
    required this.channel,
    required this.streamUrl,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerService _videoPlayer;
  late final VideoController _controller;

  bool _loading = true;
  String? _error;
  bool _showControls = true;
  Timer? _controlsTimer;
  bool _showVolume = false;

  bool _fullscreen = false;
  double _volume = 100;

  @override
  void initState() {
    super.initState();

    _videoPlayer = VideoPlayerService();

    _controller = VideoController(_videoPlayer.player);

    _openStream();
  }

  void _togglePlayPause() {
    _videoPlayer.player.playOrPause();
    _showVideoControls();
  }

  void _toggleMute() {
    if (_videoPlayer.player.state.volume > 0) {
      _volume = _videoPlayer.player.state.volume;
      _videoPlayer.player.setVolume(0);
    } else {
      _videoPlayer.player.setVolume(_volume > 0 ? _volume : 100);
    }

    _showVideoControls();
  }

  void _setVolume(double value) {
    _volume = value;
    _videoPlayer.player.setVolume(value);
    _showVideoControls();
  }

  void _showVideoControls() {
    setState(() {
      _showControls = true;
    });

    _controlsTimer?.cancel();

    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showControls = false;
      });
    });
  }

  Future<void> _openStream() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _videoPlayer.play(widget.streamUrl);

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('MEDIA_KIT : ERREUR $e');
      debugPrint('$stack');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _fullscreen = !_fullscreen;
    });

    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _videoPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              title: Text(
                '${widget.channel.number} · '
                '${widget.channel.displayName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

      // ----------------------------------------------------------
      // VIDEO
      // ----------------------------------------------------------
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showVideoControls,
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(controller: _controller, fit: BoxFit.contain),
            ),

            if (_loading) const Center(child: CircularProgressIndicator()),

            if (_error != null)
              VideoErrorView(error: _error!, onRetry: _openStream),

            if (!_fullscreen) VideoChannelOverlay(channel: widget.channel),

            if (_showControls)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // ----------------------------------------------------
                      // VOLUME / MUET
                      // ----------------------------------------------------
                      StreamBuilder<double>(
                        stream: _videoPlayer.player.stream.volume,
                        initialData: _videoPlayer.player.state.volume,
                        builder: (context, snapshot) {
                          final volume = snapshot.data ?? _volume;

                          return IconButton(
                            onPressed: _toggleMute,
                            tooltip: volume == 0 ? 'Activer le son' : 'Muet',
                            icon: Icon(
                              volume == 0
                                  ? Icons.volume_off
                                  : volume < 50
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                            ),
                          );
                        },
                      ),

                      // ----------------------------------------------------
                      // SLIDER VOLUME
                      // ----------------------------------------------------
                      Expanded(
                        child: StreamBuilder<double>(
                          stream: _videoPlayer.player.stream.volume,
                          initialData: _videoPlayer.player.state.volume,
                          builder: (context, snapshot) {
                            final volume = snapshot.data ?? _volume;

                            return Slider(
                              min: 0,
                              max: 100,
                              value: volume.clamp(0, 100),
                              onChanged: _setVolume,
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ----------------------------------------------------
                      // OPTIONS
                      // ----------------------------------------------------
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VideoSettingsPage(),
                            ),
                          );
                        },
                        tooltip: 'Configuration',
                        icon: const Icon(Icons.settings),
                      ),

                      // ----------------------------------------------------
                      // PLEIN ÉCRAN
                      // ----------------------------------------------------
                      IconButton(
                        onPressed: _toggleFullscreen,
                        tooltip: _fullscreen
                            ? 'Quitter le plein écran'
                            : 'Plein écran',
                        icon: Icon(
                          _fullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
