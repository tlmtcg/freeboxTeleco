class PodcastRadio {
  final int? id;
  final String name;
  final String searchTerm;
  final bool enabled;

  const PodcastRadio({
    this.id,
    required this.name,
    required this.searchTerm,
    this.enabled = true,
  });

  PodcastRadio copyWith({
    int? id,
    String? name,
    String? searchTerm,
    bool? enabled,
  }) {
    return PodcastRadio(
      id: id ?? this.id,
      name: name ?? this.name,
      searchTerm: searchTerm ?? this.searchTerm,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() {
    return 'PodcastRadio('
        'id: $id, '
        'name: $name, '
        'searchTerm: $searchTerm, '
        'enabled: $enabled'
        ')';
  }
}
