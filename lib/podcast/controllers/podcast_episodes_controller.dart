import 'package:flutter/foundation.dart';

import '../models/podcast.dart';
import '../models/podcast_episode.dart';
import '../repository/podcast_repository.dart';

class PodcastEpisodesController {
  final PodcastRepository repository;
  final Podcast podcast;

  PodcastEpisodesController({required this.repository, required this.podcast});

  Future<List<PodcastEpisode>> loadEpisodes() async {
    final podcastId = podcast.id;

    if (podcastId == null) {
      throw Exception('Le podcast ne possède pas d\'ID SQLite.');
    }

    var episodes = await repository.getEpisodes(podcastId, limit: 50);

    // Aucun épisode local :
    // synchronisation automatique.
    if (episodes.isEmpty) {
      // debugPrint('');
      // debugPrint('========================================');
      // debugPrint('     SYNCHRONISATION AUTOMATIQUE');
      // debugPrint('========================================');
      // debugPrint('Podcast : ${podcast.title}');
      // debugPrint(
      //   'Podcast Index ID : '
      //   '${podcast.podcastIndexId}',
      // );

      await repository.synchronizeEpisodes(podcast, maxEpisodes: 50);

      episodes = await repository.getEpisodes(podcastId, limit: 50);

      // debugPrint('Épisodes récupérés : ${episodes.length}');

      // debugPrint('========================================');
    }

    return episodes;
  }

  Future<void> synchronize() async {
    if (podcast.id == null) {
      throw Exception('Le podcast ne possède pas d\'ID SQLite.');
    }

    await repository.synchronizeEpisodes(podcast, maxEpisodes: 50);
  }
}
