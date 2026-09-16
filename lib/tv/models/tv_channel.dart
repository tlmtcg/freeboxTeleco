class TvChannel {
  final String uuid;
  final int number;
  final String name;
  final String? shortName;

  final bool available;
  final bool hasAbo;

  final String? logoUrl;

  final List<Map<String, dynamic>> streams;

  Map<String, dynamic>? epg;

  /// Données brutes retournées par l'API Freebox.
  ///
  /// On les conserve pour ne perdre aucune information
  /// pendant le refactoring.
  final Map<String, dynamic> raw;

  TvChannel({
    required this.uuid,
    required this.number,
    required this.name,
    required this.shortName,
    required this.available,
    required this.hasAbo,
    required this.logoUrl,
    required this.streams,
    this.epg,
    required this.raw,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory TvChannel.fromMap(Map<String, dynamic> map) {
    final streamsValue = map['streams'];

    final streams = <Map<String, dynamic>>[];

    if (streamsValue is List) {
      for (final item in streamsValue) {
        if (item is Map) {
          streams.add(Map<String, dynamic>.from(item));
        }
      }
    }

    Map<String, dynamic>? epg;

    final epgValue = map['epg'];

    if (epgValue is Map) {
      epg = Map<String, dynamic>.from(epgValue);
    }

    return TvChannel(
      uuid: map['uuid']?.toString() ?? '',
      number: (map['number'] as num?)?.toInt() ?? 0,
      name:
          map['name']?.toString() ?? map['short_name']?.toString() ?? 'Chaîne',
      shortName: map['short_name']?.toString(),
      available: map['available'] == true,
      hasAbo: map['has_abo'] == true,
      logoUrl: map['logo_url']?.toString(),
      streams: streams,
      epg: epg,
      raw: Map<String, dynamic>.from(map),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      ...raw,

      'uuid': uuid,
      'number': number,
      'name': name,
      'short_name': shortName,
      'available': available,
      'has_abo': hasAbo,
      'logo_url': logoUrl,
      'streams': streams,
    };

    if (epg != null) {
      map['epg'] = epg;
    } else {
      map.remove('epg');
    }

    return map;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isPaid {
    return hasAbo;
  }

  bool get isFree {
    return !hasAbo;
  }

  bool get isAvailable {
    return available;
  }

  bool get hasEpg {
    return epg != null;
  }

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }

    if (shortName != null && shortName!.trim().isNotEmpty) {
      return shortName!.trim();
    }

    return number > 0 ? 'Chaîne $number' : 'Chaîne';
  }
}
