import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/tv_channel.dart';

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
  late final Player _player;
  late final VideoController _controller;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _player = Player(
      configuration: const PlayerConfiguration(
        protocolWhitelist: [
          'rtsp',
          'rtp',
          'udp',
          'tcp',
          'file',
          'http',
          'https',
        ],
        logLevel: MPVLogLevel.debug,
      ),
    );

    _controller = VideoController(_player);

    _openStream();
  }

Future<void> _openStream() async {
    try {
      if (_player.platform is NativePlayer) {
        final nativePlayer = _player.platform as dynamic;

        // Transport RTSP utilisé par la Freebox.
        await nativePlayer.setProperty('rtsp-transport', 'udp');

        debugPrint('MEDIA_KIT : rtsp-transport = udp');

        // Préférence pour la piste audio française.
        await nativePlayer.setProperty('alang', 'fra,fre,fr');

        debugPrint('MEDIA_KIT : langue audio préférée = français');
      }

      debugPrint('MEDIA_KIT : ouverture ${widget.streamUrl}');

      await _player.open(Media(widget.streamUrl));

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
  
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.channel.number} · ${widget.channel.displayName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Video(controller: _controller, fit: BoxFit.contain),
          ),

          if (_loading) const Center(child: CircularProgressIndicator()),

          if (_error != null) _buildError(),

          _buildChannelOverlay(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Impossible de lire le flux',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });

                _openStream();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOverlay() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.channel.number}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.channel.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
