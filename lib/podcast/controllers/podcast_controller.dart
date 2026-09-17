import '../models/podcast_episode.dart';
import '../models/podcast_radio.dart';
import '../repository/podcast_repository.dart';

class PodcastController {
  final PodcastRepository repository;

  PodcastController({required this.repository});

  Future<List<PodcastRadio>> loadRadios() {
    return repository.getRadios();
  }

  Future<PodcastEpisode?> getEpisodeToResume() {
    return repository.getEpisodeToResume();
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

