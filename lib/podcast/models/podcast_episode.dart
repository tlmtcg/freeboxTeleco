class PodcastEpisode {
  final int? id;

  /// Identifiant du podcast local.
  final int podcastId;

  /// Identifiant unique fourni par le flux / Podcast Index.
  final String guid;

  final String title;
  final String? description;

  /// URL du fichier audio.
  final String audioUrl;

  final String? imageUrl;
  final DateTime? publishedAt;
  final Duration? duration;

  /// Épisode entièrement ou suffisamment écouté.
  final bool listened;

  /// Position de reprise de lecture.
  final Duration position;

  const PodcastEpisode({
    this.id,
    required this.podcastId,
    required this.guid,
    required this.title,
    this.description,
    required this.audioUrl,
    this.imageUrl,
    this.publishedAt,
    this.duration,
    this.listened = false,
    this.position = Duration.zero,
  });

  PodcastEpisode copyWith({
    int? id,
    int? podcastId,
    String? guid,
    String? title,
    String? description,
    String? audioUrl,
    String? imageUrl,
    DateTime? publishedAt,
    Duration? duration,
    bool? listened,
    Duration? position,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      duration: duration ?? this.duration,
      listened: listened ?? this.listened,
      position: position ?? this.position,
    );
  }

  @override
  String toString() {
    return 'PodcastEpisode('
        'id: $id, '
        'podcastId: $podcastId, '
        'guid: $guid, '
        'title: $title, '
        'listened: $listened, '
        'position: $position'
        ')';
  }
}
