import 'package:flutter/foundation.dart';

import '../models/podcast_episode.dart';
import '../models/podcast_radio.dart';
import '../repository/podcast_repository.dart';

class PodcastController {
  final PodcastRepository repository;

  PodcastController({required this.repository});

  Future<List<PodcastRadio>> loadRadios() {
    return repository.getRadios();
  }

  Future<PodcastEpisode?> getEpisodeToResume() async {
    // debugPrint('========================================');
    // debugPrint('🔄 RECHERCHE ÉPISODE À REPRENDRE');
    // debugPrint('========================================');

    final episode = await repository.getEpisodeToResume();

    // if (episode == null) {
    //   debugPrint('❌ Aucun épisode à reprendre');
    // } else {
    //   debugPrint('✅ Épisode trouvé');
    //   debugPrint('   ID        : ${episode.id}');
    //   debugPrint('   Titre     : ${episode.title}');
    //   debugPrint('   Position  : ${episode.position}');
    //   debugPrint('   Position s: ${episode.position.inSeconds}');
    //   debugPrint('   Durée     : ${episode.duration}');
    //   debugPrint('   Audio URL : ${episode.audioUrl}');
    // }

    // debugPrint('========================================');

    return episode;
  }

  Future<PodcastHomeData> load() async {
    final results = await Future.wait([
      repository.getRadios(),
      repository.getEpisodeToResume(),
    ]);

    return PodcastHomeData(
      radios: results[0] as List<PodcastRadio>,
      episodeToResume: results[1] as PodcastEpisode?,
    );
  }

  Future<void> deleteRadio(PodcastRadio radio) async {
    final id = radio.id;

    if (id == null) {
      throw Exception('La radio ne possède pas d\'ID SQLite.');
    }

    await repository.deleteRadio(id);
  }
}

class PodcastHomeData {
  final List<PodcastRadio> radios;
  final PodcastEpisode? episodeToResume;

  const PodcastHomeData({required this.radios, required this.episodeToResume});
}
