import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/podcast_episode.dart';
import '../repository/podcast_repository.dart';

class PodcastPositionSaver {
  final PodcastRepository repository;

  Timer? _timer;
  bool _saving = false;

  PodcastPositionSaver({required this.repository});

  void start({
    required PodcastEpisode Function() getEpisode,
    required Duration Function() getPosition,
    required bool Function() isPlaying,
  }) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isPlaying()) {
        save(getEpisode: getEpisode, getPosition: getPosition);
      }
    });
  }

  Future<void> save({
    required PodcastEpisode Function() getEpisode,
    required Duration Function() getPosition,
  }) async {
    if (_saving) {
      return;
    }

    final episode = getEpisode();

    if (episode.id == null) {
      return;
    }

    _saving = true;

    try {
      await repository.saveEpisodePosition(episode.id!, getPosition());
    } catch (e) {
      debugPrint('Erreur sauvegarde position podcast : $e');
    } finally {
      _saving = false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
