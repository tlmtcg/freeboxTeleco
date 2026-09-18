import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class PodcastAudioController {
  final AudioPlayer _audioPlayer;

  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;

  PodcastAudioController({
    AudioPlayer? audioPlayer,
  }) : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _playbackEventSubscription =
        _audioPlayer.playbackEventStream.listen(
      (event) {
        debugPrint(
          '🎵 JustAudio État : ${event.processingState}',
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '❌ ERREUR REÇUE DU FLUX AUDIO : $error',
        );
        debugPrint('$stackTrace');
      },
    );
  }

  // ============================================================
  // ETAT
  // ============================================================

  bool get isPlaying => _audioPlayer.playing;

  Duration get position => _audioPlayer.position;

  Duration? get duration => _audioPlayer.duration;

  Duration get bufferedPosition => _audioPlayer.bufferedPosition;

  ProcessingState get processingState => _audioPlayer.processingState;

  Stream<Duration> get positionStream {
    return _audioPlayer.positionStream;
  }

  Stream<Duration> get bufferedPositionStream {
    return _audioPlayer.bufferedPositionStream;
  }

  Stream<Duration?> get durationStream {
    return _audioPlayer.durationStream;
  }

  Stream<PlayerState> get playerStateStream {
    return _audioPlayer.playerStateStream;
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> load(String url) async {
    debugPrint('========================================');
    debugPrint('🎧 AUDIO LOAD');
    debugPrint('URL : $url');
    debugPrint('========================================');

    await _audioPlayer.setAudioSource(
      AudioSource.uri(Uri.parse(url)),
      preload: true,
    );

    debugPrint(
      '🎧 AUDIO LOAD terminé',
    );

    debugPrint(
      '   processingState : ${_audioPlayer.processingState}',
    );

    debugPrint(
      '   duration        : ${_audioPlayer.duration}',
    );
  }

  Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint(
      '⏳ Attente ProcessingState.ready '
      '(état actuel : ${_audioPlayer.processingState})',
    );

    if (_audioPlayer.processingState == ProcessingState.ready) {
      debugPrint('✅ Audio déjà READY');
      return;
    }

    try {
      await _audioPlayer.processingStateStream
          .where(
            (state) => state == ProcessingState.ready,
          )
          .first
          .timeout(timeout);

      debugPrint('✅ Audio READY');
    } on TimeoutException {
      debugPrint(
        '❌ Timeout en attente de ProcessingState.ready',
      );

      debugPrint(
        '   état actuel : ${_audioPlayer.processingState}',
      );

      debugPrint(
        '   durée       : ${_audioPlayer.duration}',
      );

      rethrow;
    }
  }

  // ============================================================
  // LECTURE
  // ============================================================

  Future<void> play() async {
    debugPrint('▶️ AUDIO PLAY');

    await _audioPlayer.play();
  }

  Future<void> pause() async {
    debugPrint('⏸️ AUDIO PAUSE');

    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    debugPrint('⏹️ AUDIO STOP');

    await _audioPlayer.stop();
  }

  // ============================================================
  // SEEK
  // ============================================================

  Future<void> seek(Duration position) async {
    debugPrint(
      '🎯 AUDIO SEEK demandé : '
      '${position.inSeconds}s',
    );

    try {
      await _audioPlayer.seek(position);

      debugPrint(
        '✅ AUDIO SEEK terminé : '
        '${_audioPlayer.position.inSeconds}s',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ ERREUR AUDIO SEEK : $e',
      );
      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _playbackEventSubscription?.cancel();
    _playbackEventSubscription = null;

    _audioPlayer.dispose();
  }
}
