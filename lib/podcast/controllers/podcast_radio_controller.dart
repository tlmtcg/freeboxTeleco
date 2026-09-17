import '../models/podcast.dart';
import '../models/podcast_radio.dart';
import '../repository/podcast_repository.dart';

class PodcastRadioController {
  final PodcastRepository repository;
  final PodcastRadio radio;

  PodcastRadioController({required this.repository, required this.radio});

  Future<List<Podcast>> loadPodcasts() async {
    final radioId = radio.id;

    if (radioId == null) {
      throw Exception('La radio ne possède pas d\'ID SQLite.');
    }

    var podcasts = await repository.getPodcastsForRadio(radioId);

    // Si aucun podcast n'est présent localement,
    // on synchronise automatiquement.
    if (podcasts.isEmpty) {
      await repository.synchronizeRadio(radio, maxPodcasts: 20);

      podcasts = await repository.getPodcastsForRadio(radioId);
    }

    return podcasts;
  }

  Future<void> synchronize() async {
    if (radio.id == null) {
      throw Exception('La radio ne possède pas d\'ID SQLite.');
    }

    await repository.synchronizeRadio(radio, maxPodcasts: 20);
  }
}
