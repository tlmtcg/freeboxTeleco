import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerService {
  late final Player player;

  VideoPlayerService() {
    player = Player(
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
  }

  Future<void> configure() async {
    if (player.platform is NativePlayer) {
      final nativePlayer = player.platform as dynamic;

      await nativePlayer.setProperty('rtsp-transport', 'udp');

      debugPrint('MEDIA_KIT : rtsp-transport = udp');

      await nativePlayer.setProperty('alang', 'fra,fre,fr');

      debugPrint('MEDIA_KIT : langue audio préférée = français');
    }
  }

  Future<void> open(String streamUrl) async {
    debugPrint('MEDIA_KIT : ouverture $streamUrl');

    await player.open(Media(streamUrl));
  }

  Future<void> play(String streamUrl) async {
    await configure();
    await open(streamUrl);
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
