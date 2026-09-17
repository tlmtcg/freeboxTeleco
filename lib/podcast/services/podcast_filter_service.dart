import '../models/podcast.dart';

class PodcastFilterService {
  List<String> getCategories(List<Podcast> podcasts) {
    final categories = <String>{};

    for (final podcast in podcasts) {
      for (final category in podcast.categories) {
        final value = category.trim();

        if (value.isNotEmpty) {
          categories.add(value);
        }
      }
    }

    final result = categories.toList();

    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return result;
  }

  List<Podcast> filter({
    required List<Podcast> podcasts,
    String search = '',
    String? category,
  }) {
    final query = search.trim().toLowerCase();

    return podcasts.where((podcast) {
      // Recherche texte
      if (query.isNotEmpty) {
        final title = podcast.title.toLowerCase();

        final description = podcast.description?.toLowerCase() ?? '';

        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Catégorie
      if (category != null) {
        final found = podcast.categories.any(
          (item) => item.trim().toLowerCase() == category.trim().toLowerCase(),
        );

        if (!found) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
