class Podcast {
  final int? id;

  /// Identifiant du podcast dans Podcast Index.
  final int? podcastIndexId;

  /// Identifiant de la radio dans notre base locale.
  final int? radioId;

  final String title;
  final String? description;
  final String? imageUrl;
  final String? feedUrl;
  final String? websiteUrl;
  final List<String> categories;

  /// Date de dernière synchronisation locale.
  final DateTime? lastUpdated;

  const Podcast({
    this.id,
    this.podcastIndexId,
    this.radioId,
    required this.title,
    this.description,
    this.imageUrl,
    this.feedUrl,
    this.websiteUrl,
    this.lastUpdated,
    this.categories = const [],
  });

  Podcast copyWith({
    int? id,
    int? podcastIndexId,
    int? radioId,
    String? title,
    String? description,
    String? imageUrl,
    String? feedUrl,
    String? websiteUrl,
    DateTime? lastUpdated,
    List<String>? categories,
  }) {
    return Podcast(
      id: id ?? this.id,
      podcastIndexId: podcastIndexId ?? this.podcastIndexId,
      radioId: radioId ?? this.radioId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      categories: categories ?? this.categories,
    );
  }

  @override
  String toString() {
    return 'Podcast('
        'id: $id, '
        'podcastIndexId: $podcastIndexId, '
        'radioId: $radioId, '
        'title: $title'
        ')';
  }
}
