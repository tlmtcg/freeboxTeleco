import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/podcast_episode.dart';
import '../repository/podcast_repository.dart';

class PodcastProgressManager {
  final PodcastRepository repository;

  Timer? _saveTimer;

  bool _saving = false;

  PodcastProgressManager({required this.repository});

  // ============================================================
  // SAUVEGARDE PERIODIQUE
  // ============================================================

  void startAutoSave({
    required PodcastEpisode? Function() getEpisode,
    required Duration Function() getPosition,
    required bool Function() isPlaying,
  }) {
    _saveTimer?.cancel();

    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isPlaying()) {
        savePosition(getEpisode: getEpisode, getPosition: getPosition);
      }
    });
  }

  // ============================================================
  // SAUVEGARDE POSITION
  // ============================================================

  Future<void> savePosition({
    required PodcastEpisode? Function() getEpisode,
    required Duration Function() getPosition,
  }) async {
    if (_saving) {
      return;
    }

    final episode = getEpisode();

    if (episode == null || episode.id == null) {
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

  // ============================================================
  // DERNIER EPISODE ECOUTE
  // ============================================================

  Future<void> markAsPlayed(
    PodcastEpisode episode, {
    required Duration position,
  }) async {
    if (episode.id == null) {
      return;
    }

    await repository.markEpisodeAsPlayed(episode.id!, position: position);
  }

  // ============================================================
  // EPISODE TERMINE
  // ============================================================

  Future<void> markAsFinished(PodcastEpisode episode) async {
    if (episode.id == null) {
      return;
    }

    await repository.markEpisodeFinished(episode.id!);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }
}
