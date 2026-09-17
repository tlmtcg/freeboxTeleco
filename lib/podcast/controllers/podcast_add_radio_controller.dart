import '../api/podcast_api.dart';
import '../models/podcast.dart';
import '../models/podcast_radio.dart';
import '../repository/podcast_repository.dart';

class PodcastAddRadioController {
  final PodcastRepository repository;
  final PodcastApi podcastApi;

  PodcastAddRadioController({
    required this.repository,
    required this.podcastApi,
  });

  // ===========================================================================
  // RECHERCHE
  // ===========================================================================

  Future<List<Podcast>> search(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      throw Exception('Veuillez saisir le nom d’une radio ou d’un podcast.');
    }

    return podcastApi.searchPodcasts(normalizedQuery, max: 20);
  }

  // ===========================================================================
  // AJOUT
  // ===========================================================================

  Future<void> addRadio({
    required Podcast podcast,
    required String searchTerm,
  }) async {
    // -------------------------------------------------------------------------
    // Vérification d'une éventuelle radio existante
    // -------------------------------------------------------------------------

    final radios = await repository.getRadios();

    final alreadyExists = radios.any(
      (radio) => radio.name.toLowerCase() == podcast.title.toLowerCase(),
    );

    if (alreadyExists) {
      throw Exception('Cette radio existe déjà.');
    }

    // -------------------------------------------------------------------------
    // Création de la radio
    // -------------------------------------------------------------------------

    final radio = PodcastRadio(
      name: podcast.title,
      searchTerm: searchTerm.trim(),
    );

    final id = await repository.addRadio(radio);

    if (id == 0) {
      throw Exception('Impossible d’ajouter la radio.');
    }
  }
}
