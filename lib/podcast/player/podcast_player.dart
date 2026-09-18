// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:just_audio/just_audio.dart';

// import '../models/podcast_episode.dart';
// import '../repository/podcast_repository.dart';

// class PodcastPlayer extends ChangeNotifier {
//   final PodcastRepository repository;

//   final AudioPlayer _audioPlayer = AudioPlayer();

//   PodcastEpisode? _episode;

//   Duration _position = Duration.zero;
//   Duration? _duration;

//   bool _savingPosition = false;

//   StreamSubscription<Duration>? _positionSubscription;
//   StreamSubscription<Duration?>? _durationSubscription;
//   StreamSubscription<PlayerState>? _playerStateSubscription;

//   /*
//    * Sauvegarde périodique de la position.
//    *
//    * On évite d'écrire dans SQLite à chaque événement du
//    * positionStream.
//    */
//   Timer? _saveTimer;

//   PodcastPlayer({required this.repository}) {
//     _positionSubscription = _audioPlayer.positionStream.listen((position) {
//       _position = position;
//       notifyListeners();
//     });

//     _durationSubscription = _audioPlayer.durationStream.listen((duration) {
//       _duration = duration;
//       notifyListeners();
//     });

//     // CORRECTION : Écouter le flux d'événements global et intercepter l'argument onError
//     _audioPlayer.playbackEventStream.listen(
//       (event) {
//         // Optionnel : permet de voir l'état passer de buffering à la lecture dans votre console
//         debugPrint('🎵 JustAudio État : ${event.processingState}');
//       },
//       onError: (Object error, StackTrace stackTrace) {
//         // C'est ici que l'erreur de streaming réseau sera écrite si le son coupe tout seul !
//         debugPrint('❌ ERREUR REÇUE DU FLUX AUDIO : $error');
//         debugPrint('$stackTrace');
//       },
//     );

//     _playerStateSubscription = _audioPlayer.playerStateStream.listen(
//       _onPlayerStateChanged,
//     );

//     /*
//      * Sauvegarde de la position toutes les 5 secondes.
//      */
//     _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       if (_audioPlayer.playing) {
//         _savePosition();
//       }
//     });
//   }

//   // ============================================================
//   // GETTERS
//   // ============================================================

//   PodcastEpisode? get episode => _episode;

//   AudioPlayer get audioPlayer => _audioPlayer;

//   Duration get position => _position;

//   Duration? get duration => _duration;

//   bool get isPlaying => _audioPlayer.playing;

//   bool get hasEpisode => _episode != null;

//   // ============================================================
//   // LECTURE
//   // ============================================================

//   Future<void> play(PodcastEpisode episode) async {
//     if (episode.audioUrl.isEmpty) {
//       throw Exception('Cet épisode ne possède pas de flux audio.');
//     }

//     // ----------------------------------------------------------
//     // Même épisode
//     // ----------------------------------------------------------

//     if (_episode?.id == episode.id) {
//       await _audioPlayer.play();

//       /*
//        * L'épisode devient à nouveau l'épisode actif.
//        */
//       if (episode.id != null) {
//         await repository.markEpisodeAsPlayed(episode.id!, position: _position);
//       }

//       notifyListeners();
//       return;
//     }

//     // ----------------------------------------------------------
//     // Sauvegarde de l'ancien épisode
//     // ----------------------------------------------------------

//     await _savePosition();

//     // ----------------------------------------------------------
//     // Arrêt de l'ancien flux
//     // ----------------------------------------------------------

//     await _audioPlayer.stop();

//     // ----------------------------------------------------------
//     // Nouveau épisode
//     // ----------------------------------------------------------

//     _episode = episode;

//     _position = Duration.zero;
//     _duration = episode.duration;

//     notifyListeners();

//     // ----------------------------------------------------------
//     // Chargement du flux
//     // ----------------------------------------------------------

//     // await _audioPlayer.setAudioSource(
//     //   AudioSource.uri(Uri.parse(episode.audioUrl)),
//     //   // preload: false empêche le lecteur de charger agressivement
//     //   // trop de données en tâche de fond, ce qui sature le pipeline
//     //   preload: false,
//     // );

//     // ----------------------------------------------------------
//     // Chargement du flux (Sécurisé avec reconnexions automatiques)
//     // ----------------------------------------------------------
//     int retryCount = 0;
//     const maxRetries = 3;
//     bool loadSuccess = false;

//     while (retryCount < maxRetries && !loadSuccess) {
//       try {
//         await _audioPlayer.setAudioSource(
//           AudioSource.uri(
//             Uri.parse(episode.audioUrl),
//             tag: episode
//                 .title, // Aide ExoPlayer à stabiliser ses tampons mémoires
//           ),
//           preload: false, // Conservé pour éviter la saturation du pipeline Android TV
//         );

//         // Si aucune exception n'est levée, le chargement a réussi !
//         loadSuccess = true;
//       } catch (e) {
//         retryCount++;
//         debugPrint(
//           '⚠️ Échec réseau ou DNS (Ausha) : Tentative de reconnexion $retryCount/$maxRetries...',
//         );

//         if (retryCount >= maxRetries) {
//           // Si après 3 essais le réseau est toujours en panne, on lève l'exception pour l'UI
//           throw Exception(
//             'Impossible de joindre le serveur du podcast. Vérifiez votre connexion Internet.',
//           );
//         }

//         // On attend 1.5 seconde que le DNS ou le Wi-Fi se stabilise avant de réessayer
//         await Future.delayed(const Duration(milliseconds: 1500));
//       }
//     }

//     // ----------------------------------------------------------
//     // Durée réelle fournie par le flux
//     // ----------------------------------------------------------

//     _duration = _audioPlayer.duration ?? episode.duration;

//     // ----------------------------------------------------------
//     // Reprise
//     // ----------------------------------------------------------

//     if (episode.position > Duration.zero) {
//       final duration = _audioPlayer.duration;

//       if (duration == null || episode.position < duration) {
//         await _audioPlayer.seek(episode.position);

//         _position = episode.position;
//       }
//     }

//     // ----------------------------------------------------------
//     // Mémorisation comme dernier épisode écouté
//     // ----------------------------------------------------------

//     if (episode.id != null) {
//       await repository.markEpisodeAsPlayed(episode.id!, position: _position);
//     }

//     // ----------------------------------------------------------
//     // Lecture
//     // ----------------------------------------------------------

//     await _audioPlayer.play();

//     notifyListeners();
//   }

//   // ============================================================
//   // PAUSE
//   // ============================================================

//   Future<void> pause() async {
//     await _audioPlayer.pause();

//     await _savePosition();

//     notifyListeners();
//   }

//   // ============================================================
//   // PLAY / PAUSE
//   // ============================================================

//   Future<void> togglePlayPause() async {
//     if (_episode == null) {
//       return;
//     }

//     if (_audioPlayer.playing) {
//       await pause();
//     } else {
//       /*
//        * On considère que cet épisode est à nouveau utilisé.
//        */
//       if (_episode?.id != null) {
//         await repository.markEpisodeAsPlayed(
//           _episode!.id!,
//           position: _position,
//         );
//       }

//       await _audioPlayer.play();

//       notifyListeners();
//     }
//   }

//   // ============================================================
//   // SEEK
//   // ============================================================

//   Future<void> seek(Duration position) async {
//     await _audioPlayer.seek(position);

//     _position = position;

//     await _savePosition();

//     /*
//      * Le seek constitue également une activité récente
//      * sur cet épisode.
//      */
//     if (_episode?.id != null) {
//       await repository.markEpisodeAsPlayed(_episode!.id!, position: _position);
//     }

//     notifyListeners();
//   }

//   Future<void> skipForward([
//     Duration amount = const Duration(seconds: 30),
//   ]) async {
//     final target = _position + amount;

//     final duration = _duration;

//     final newPosition = duration != null && target > duration
//         ? duration
//         : target;

//     await seek(newPosition);
//   }

//   Future<void> skipBackward([
//     Duration amount = const Duration(seconds: 15),
//   ]) async {
//     final target = _position - amount;

//     final newPosition = target.isNegative ? Duration.zero : target;

//     await seek(newPosition);
//   }

//   // ============================================================
//   // ETAT DU LECTEUR
//   // ============================================================

//   void _onPlayerStateChanged(PlayerState state) {
//     notifyListeners();

//     if (state.processingState == ProcessingState.completed) {
//       _onCompleted();
//     }
//   }

//   Future<void> _onCompleted() async {
//     final currentEpisode = _episode;

//     if (currentEpisode == null || currentEpisode.id == null) {
//       return;
//     }

//     await repository.markEpisodeFinished(currentEpisode.id!);

//     _position = Duration.zero;

//     notifyListeners();
//   }

//   // ============================================================
//   // SAUVEGARDE POSITION
//   // ============================================================

//   Future<void> _savePosition() async {
//     if (_savingPosition) {
//       return;
//     }

//     final currentEpisode = _episode;

//     if (currentEpisode == null || currentEpisode.id == null) {
//       return;
//     }

//     _savingPosition = true;

//     try {
//       await repository.saveEpisodePosition(currentEpisode.id!, _position);
//     } catch (e) {
//       debugPrint('Erreur sauvegarde position podcast : $e');
//     } finally {
//       _savingPosition = false;
//     }
//   }

//   // ============================================================
//   // ARRET
//   // ============================================================

//   Future<void> stop() async {
//     /*
//      * Sauvegarde AVANT l'arrêt du lecteur afin de conserver
//      * la dernière position connue.
//      */
//     await _savePosition();

//     await _audioPlayer.stop();

//     _position = Duration.zero;

//     notifyListeners();
//   }

//   // ============================================================
//   // DISPOSE
//   // ============================================================

//   @override
//   void dispose() {
//     _saveTimer?.cancel();

//     _positionSubscription?.cancel();
//     _durationSubscription?.cancel();
//     _playerStateSubscription?.cancel();

//     _audioPlayer.dispose();

//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/podcast_episode.dart';
import '../repository/podcast_repository.dart';
import 'podcast_audio_controller.dart';
import 'podcast_progress_manager.dart';

class PodcastPlayer extends ChangeNotifier {
  final PodcastRepository repository;

  late final PodcastAudioController _audioController;
  late final PodcastProgressManager _progressManager;

  PodcastEpisode? _episode;

  Duration _position = Duration.zero;
  Duration? _duration;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  bool _disposed = false;

  PodcastPlayer({
    required this.repository,
    PodcastAudioController? audioController,
    PodcastProgressManager? progressManager,
  }) {
    _audioController = audioController ?? PodcastAudioController();

    _progressManager =
        progressManager ?? PodcastProgressManager(repository: repository);

    _listenToAudio();

    _progressManager.startAutoSave(
      getEpisode: () => _episode,
      getPosition: () => _position,
      isPlaying: () => isPlaying,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  PodcastEpisode? get episode => _episode;

  Duration get position => _position;

  Duration? get duration => _duration;

  bool get isPlaying => _audioController.isPlaying;

  bool get hasEpisode => _episode != null;

  /*
   * Compatibilité avec le code existant.
   *
   * Si certaines pages utilisent encore player.audioPlayer,
   * on pourra supprimer ce getter plus tard.
   */
  AudioPlayer get audioPlayer {
    throw UnsupportedError(
      'PodcastPlayer.audioPlayer a été remplacé '
      'par PodcastAudioController.',
    );
  }

  // ============================================================
  // ECOUTE DES EVENEMENTS AUDIO
  // ============================================================
  
void _listenToAudio() {
  _positionSubscription =
      _audioController.positionStream.listen((position) {
    _position = position;
    _notify();
  });

  _durationSubscription =
      _audioController.durationStream.listen((duration) {
    _duration = duration;
    _notify();
  });

  _playerStateSubscription =
      _audioController.playerStateStream.listen(
    _onPlayerStateChanged,
  );

  _bufferedPositionSubscription =
      _audioController.bufferedPositionStream.listen((buffered) {
    if (!_audioController.isPlaying) {
      return;
    }

    final ahead = buffered - _position;

    debugPrint(
      '📦 BUFFER : ${buffered.inSeconds}s | '
      'POSITION : ${_position.inSeconds}s | '
      'AVANCE : ${ahead.inSeconds}s',
    );
  });
}

  // ============================================================
  // LECTURE
  // ============================================================

  Future<void> play(PodcastEpisode episode) async {
    // debugPrint('========================================');
    // debugPrint('🎵 PODCAST PLAYER.play()');
    // debugPrint('Titre    : ${episode.title}');
    // debugPrint('ID       : ${episode.id}');
    // debugPrint('Position : ${episode.position.inSeconds}s');
    // debugPrint('URL      : ${episode.audioUrl}');
    // debugPrint('========================================');

    if (episode.audioUrl.isEmpty) {
      throw Exception('Cet épisode ne possède pas de flux audio.');
    }

    // ------------------------------------------------------------
    // Même épisode : on reprend simplement la lecture
    // ------------------------------------------------------------

    if (_episode?.id == episode.id) {
      await _audioController.play();
      // debugPrint(
      //   '▶️ PLAY APRÈS RESTAURATION : '
      //   '${_audioController.position.inSeconds}s',
      // );

      // debugPrint(
      //   '▶️ _position PodcastPlayer : '
      //   '${_position.inSeconds}s',
      // );
      await _markEpisodeAsPlayed();
      _notify();
      return;
    }

    // ------------------------------------------------------------
    // Sauvegarder l'ancien épisode
    // ------------------------------------------------------------

    await _savePosition();

    await _audioController.stop();

    // ------------------------------------------------------------
    // Nouvel épisode
    // ------------------------------------------------------------

    _episode = episode;

    _position = Duration.zero;
    _duration = episode.duration;

    _notify();

    // ------------------------------------------------------------
    // Charger réellement le fichier audio
    // ------------------------------------------------------------

    await _audioController.load(episode.audioUrl);

    // ------------------------------------------------------------
    // IMPORTANT :
    // attendre que JustAudio soit READY avant le SEEK
    // ------------------------------------------------------------

    await _audioController.waitUntilReady();

    // ------------------------------------------------------------
    // Durée réelle du flux
    // ------------------------------------------------------------

    _duration = _audioController.duration ?? episode.duration;

    // debugPrint('🎧 Durée finale : $_duration');

    // ------------------------------------------------------------
    // Restaurer la position
    // ------------------------------------------------------------

    await _restorePosition(episode);

    // ------------------------------------------------------------
    // Marquer comme lu
    // ------------------------------------------------------------

    await _markEpisodeAsPlayed();

    // ------------------------------------------------------------
    // Démarrer la lecture
    // ------------------------------------------------------------

    await _audioController.play();

    _notify();
  }

  // ============================================================
  // REPRISE POSITION
  // ============================================================

  Future<void> _restorePosition(PodcastEpisode episode) async {
    // debugPrint('========================================');
    // debugPrint('🎧 RESTAURATION PODCAST');
    // debugPrint('Titre       : ${episode.title}');
    // debugPrint('ID          : ${episode.id}');
    // debugPrint('Position DB : ${episode.position}');
    // debugPrint('Position sec: ${episode.position.inSeconds}');
    // debugPrint('Durée flux  : ${_audioController.duration}');
    // debugPrint('========================================');

    if (episode.position <= Duration.zero) {
      // debugPrint('⚠️ Aucune position à restaurer');
      return;
    }

    final duration = _audioController.duration;

    if (duration != null && episode.position >= duration) {
      // debugPrint(
      //   '⚠️ Position ignorée : '
      //   '${episode.position.inSeconds}s >= '
      //   '${duration.inSeconds}s',
      // );
      return;
    }

    // debugPrint('▶️ SEEK vers ${episode.position.inSeconds}s');

    await _audioController.seek(episode.position);

    _position = episode.position;

    // debugPrint(
    //   '✅ SEEK effectué : '
    //   '${_position.inSeconds}s',
    // );
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pause() async {
    await _audioController.pause();

    await _savePosition();

    _notify();
  }

  // ============================================================
  // PLAY / PAUSE
  // ============================================================

  Future<void> togglePlayPause() async {
    if (_episode == null) {
      return;
    }

    if (_audioController.isPlaying) {
      await pause();
      return;
    }

    await _markEpisodeAsPlayed();

    await _audioController.play();

    _notify();
  }

  // ============================================================
  // SEEK
  // ============================================================

  Future<void> seek(Duration position) async {
    await _audioController.seek(position);

    _position = position;

    await _savePosition();

    await _markEpisodeAsPlayed();

    _notify();
  }

  // ============================================================
  // AVANCE RAPIDE
  // ============================================================

  Future<void> skipForward([
    Duration amount = const Duration(seconds: 30),
  ]) async {
    final target = _position + amount;

    final currentDuration = _duration;

    final newPosition = currentDuration != null && target > currentDuration
        ? currentDuration
        : target;

    await seek(newPosition);
  }

  // ============================================================
  // RETOUR RAPIDE
  // ============================================================

  Future<void> skipBackward([
    Duration amount = const Duration(seconds: 15),
  ]) async {
    final target = _position - amount;

    final newPosition = target.isNegative ? Duration.zero : target;

    await seek(newPosition);
  }

  // ============================================================
  // ETAT LECTEUR
  // ============================================================

  void _onPlayerStateChanged(PlayerState state) {
    _notify();

    if (state.processingState == ProcessingState.completed) {
      _onCompleted();
    }
  }

  // ============================================================
  // FIN EPISODE
  // ============================================================

  Future<void> _onCompleted() async {
    final currentEpisode = _episode;

    if (currentEpisode == null || currentEpisode.id == null) {
      return;
    }

    await _progressManager.markAsFinished(currentEpisode);

    _position = Duration.zero;

    _notify();
  }

  // ============================================================
  // SAUVEGARDE POSITION
  // ============================================================

  Future<void> _savePosition() async {
    await _progressManager.savePosition(
      getEpisode: () => _episode,
      getPosition: () => _position,
    );
  }

  // ============================================================
  // MARQUER COMME ECOUTE
  // ============================================================

  Future<void> _markEpisodeAsPlayed() async {
    final currentEpisode = _episode;

    if (currentEpisode == null) {
      return;
    }

    await _progressManager.markAsPlayed(currentEpisode, position: _position);
  }

  // ============================================================
  // ARRET
  // ============================================================

  Future<void> stop() async {
    /*
     * Sauvegarde AVANT l'arrêt du lecteur.
     */
    await _savePosition();

    await _audioController.stop();

    _position = Duration.zero;

    _notify();
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();

    _progressManager.dispose();
    _audioController.dispose();

    super.dispose();
  }
}
