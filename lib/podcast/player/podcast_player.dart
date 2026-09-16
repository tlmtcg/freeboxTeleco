import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/podcast_episode.dart';
import '../repository/podcast_repository.dart';

class PodcastPlayer extends ChangeNotifier {
  final PodcastRepository repository;

  final AudioPlayer _audioPlayer = AudioPlayer();

  PodcastEpisode? _episode;

  Duration _position = Duration.zero;
  Duration? _duration;

  bool _savingPosition = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  PodcastPlayer({required this.repository}) {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      _onPlayerStateChanged,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  PodcastEpisode? get episode => _episode;

  AudioPlayer get audioPlayer => _audioPlayer;

  Duration get position => _position;

  Duration? get duration => _duration;

  bool get isPlaying => _audioPlayer.playing;

  bool get hasEpisode => _episode != null;

  // ============================================================
  // LECTURE
  // ============================================================

  Future<void> play(PodcastEpisode episode) async {
    if (episode.audioUrl.isEmpty) {
      throw Exception('Cet épisode ne possède pas de flux audio.');
    }

    // ----------------------------------------------------------
    // Même épisode
    // ----------------------------------------------------------

    if (_episode?.id == episode.id) {
      await _audioPlayer.play();
      notifyListeners();
      return;
    }

    // ----------------------------------------------------------
    // Nouveau épisode
    // ----------------------------------------------------------

    await _audioPlayer.stop();

    _episode = episode;
    _position = Duration.zero;
    _duration = episode.duration;

    notifyListeners();

    // ----------------------------------------------------------
    // Chargement du flux
    // ----------------------------------------------------------

    await _audioPlayer.setUrl(episode.audioUrl);

    // ----------------------------------------------------------
    // Durée réelle fournie par le flux
    // ----------------------------------------------------------

    _duration = _audioPlayer.duration ?? episode.duration;

    // ----------------------------------------------------------
    // Reprise
    // ----------------------------------------------------------

    if (episode.position > Duration.zero) {
      final duration = _audioPlayer.duration;

      if (duration == null || episode.position < duration) {
        await _audioPlayer.seek(episode.position);
      }
    }

    // ----------------------------------------------------------
    // Lecture
    // ----------------------------------------------------------

    await _audioPlayer.play();

    notifyListeners();
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pause() async {
    await _audioPlayer.pause();

    await _savePosition();

    notifyListeners();
  }

  // ============================================================
  // PLAY / PAUSE
  // ============================================================

  Future<void> togglePlayPause() async {
    if (_episode == null) {
      return;
    }

    if (_audioPlayer.playing) {
      await pause();
    } else {
      await _audioPlayer.play();
      notifyListeners();
    }
  }

  // ============================================================
  // SEEK
  // ============================================================

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);

    _position = position;

    await _savePosition();

    notifyListeners();
  }

  Future<void> skipForward([
    Duration amount = const Duration(seconds: 30),
  ]) async {
    final target = _position + amount;

    final duration = _duration;

    final newPosition = duration != null && target > duration
        ? duration
        : target;

    await seek(newPosition);
  }

  Future<void> skipBackward([
    Duration amount = const Duration(seconds: 15),
  ]) async {
    final target = _position - amount;

    final newPosition = target.isNegative ? Duration.zero : target;

    await seek(newPosition);
  }

  // ============================================================
  // ETAT DU LECTEUR
  // ============================================================

  void _onPlayerStateChanged(PlayerState state) {
    notifyListeners();

    if (state.processingState == ProcessingState.completed) {
      _onCompleted();
    }
  }

  Future<void> _onCompleted() async {
    final currentEpisode = _episode;

    if (currentEpisode == null || currentEpisode.id == null) {
      return;
    }

    await repository.setEpisodeListened(currentEpisode.id!, true);

    await repository.saveEpisodePosition(currentEpisode.id!, Duration.zero);

    _position = Duration.zero;

    notifyListeners();
  }

  // ============================================================
  // SAUVEGARDE POSITION
  // ============================================================

  Future<void> _savePosition() async {
    if (_savingPosition) {
      return;
    }

    final currentEpisode = _episode;

    if (currentEpisode == null || currentEpisode.id == null) {
      return;
    }

    _savingPosition = true;

    try {
      await repository.saveEpisodePosition(currentEpisode.id!, _position);
    } catch (e) {
      debugPrint('Erreur sauvegarde position podcast : $e');
    } finally {
      _savingPosition = false;
    }
  }

  // ============================================================
  // ARRET
  // ============================================================

  Future<void> stop() async {
    await _audioPlayer.stop();

    await _savePosition();

    _position = Duration.zero;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _audioPlayer.dispose();

    super.dispose();
  }
}

