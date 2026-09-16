import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/podcast.dart';
import '../models/podcast_episode.dart';

class PodcastApi {
  static const String _baseUrl = 'https://api.podcastindex.org/api/1.0';

  final String apiKey;
  final String apiSecret;

  /// Identifie notre application auprès de Podcast Index.
  final String userAgent;

  final http.Client _client;

  PodcastApi({
    required this.apiKey,
    required this.apiSecret,
    this.userAgent = 'FreeboxRemote/1.0',
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // AUTHENTIFICATION
  // ---------------------------------------------------------------------------

Map<String, String> _headers() {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();

    final authString = apiKey + apiSecret + timestamp;

    final authorization = sha1.convert(utf8.encode(authString)).toString();

    debugPrint('--- Podcast Index AUTH ---');
    debugPrint('API key length    : ${apiKey.length}');
    debugPrint('API secret length : ${apiSecret.length}');
    debugPrint('Timestamp         : $timestamp');
    debugPrint('Authorization len : ${authorization.length}');
    debugPrint('User-Agent        : $userAgent');

    return {
      'User-Agent': userAgent,
      'X-Auth-Key': apiKey,
      'X-Auth-Date': timestamp,
      'Authorization': authorization,
    };
  }

  // ---------------------------------------------------------------------------
  // HTTP
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);

    final response = await _client.get(uri, headers: _headers());

    debugPrint('--- Podcast Index RESPONSE ---');
    debugPrint('HTTP : ${response.statusCode}');
    debugPrint('BODY : ${response.body}');
    debugPrint('------------------------------');

    if (response.statusCode != 200) {
      throw PodcastApiException(
        'Erreur Podcast Index',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const PodcastApiException('Réponse Podcast Index invalide');
    }

    final status = decoded['status'];

    if (status != null && status != 'true') {
      throw PodcastApiException(
        'Podcast Index a retourné une erreur',
        body: response.body,
      );
    }

    return decoded;
  }

  // ---------------------------------------------------------------------------
  // RECHERCHE DE PODCASTS
  // ---------------------------------------------------------------------------

  /// Recherche des podcasts dans Podcast Index.
  ///
  /// Exemple :
  ///
  ///   searchPodcasts('France Inter')
  ///
  Future<List<Podcast>> searchPodcasts(String query, {int? max}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final parameters = <String, String>{'q': query.trim()};

    if (max != null) {
      parameters['max'] = max.toString();
    }

    final data = await _get('/search/byterm', queryParameters: parameters);

    final feeds = data['feeds'];

    if (feeds is! List) {
      return [];
    }

    return feeds
        .whereType<Map<String, dynamic>>()
        .map(_podcastFromJson)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // RECHERCHE PAR TITRE
  // ---------------------------------------------------------------------------

  /// Recherche un podcast en se basant principalement sur son titre.
  Future<List<Podcast>> searchPodcastsByTitle(String query, {int? max}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final parameters = <String, String>{'q': query.trim()};

    if (max != null) {
      parameters['max'] = max.toString();
    }

    final data = await _get('/search/bytitle', queryParameters: parameters);

    final feeds = data['feeds'];

    if (feeds is! List) {
      return [];
    }

    return feeds
        .whereType<Map<String, dynamic>>()
        .map(_podcastFromJson)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // PODCAST PAR ID
  // ---------------------------------------------------------------------------

  /// Récupère les informations détaillées d'un podcast.
  Future<Podcast> getPodcast(int podcastIndexId) async {
    final data = await _get(
      '/podcasts/byfeedid',
      queryParameters: {'id': podcastIndexId.toString()},
    );

    final feed = data['feed'];

    if (feed is! Map<String, dynamic>) {
      throw const PodcastApiException('Podcast introuvable');
    }

    return _podcastFromJson(feed);
  }

  // ---------------------------------------------------------------------------
  // EPISODES D'UN PODCAST
  // ---------------------------------------------------------------------------

  /// Récupère les épisodes d'un podcast.
  Future<List<PodcastEpisode>> getEpisodes(
    int podcastIndexId, {
    int? max,
  }) async {
    final parameters = <String, String>{'id': podcastIndexId.toString()};

    if (max != null) {
      parameters['max'] = max.toString();
    }

    final data = await _get('/episodes/byfeedid', queryParameters: parameters);

    final items = data['items'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) => _episodeFromJson(json, podcastIndexId))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // PODCAST -> DART
  // ---------------------------------------------------------------------------

  Podcast _podcastFromJson(Map<String, dynamic> json) {
    return Podcast(
      podcastIndexId: _asInt(json['id']),
      title: _asString(json['title']) ?? 'Sans titre',
      description: _asString(json['description']),
      imageUrl: _asString(json['artwork']) ?? _asString(json['image']),
      feedUrl: _asString(json['url']),
      websiteUrl: _asString(json['link']),
    );
  }

  // ---------------------------------------------------------------------------
  // EPISODE -> DART
  // ---------------------------------------------------------------------------

  PodcastEpisode _episodeFromJson(
    Map<String, dynamic> json,
    int podcastIndexId,
  ) {
    final publishedTimestamp = _asInt(json['datePublished']);

    final durationSeconds = _durationToSeconds(json['duration']);

    final audioUrl = _asString(json['enclosureUrl']) ?? '';

    return PodcastEpisode(
      // Le podcastId sera remplacé par le repository
      // lorsqu'il connaîtra l'ID SQLite du podcast.
      podcastId: podcastIndexId,

      guid: _asString(json['guid']) ?? '',

      title: _asString(json['title']) ?? 'Sans titre',

      description: _asString(json['description']),

      audioUrl: audioUrl,

      imageUrl: _asString(json['image']) ?? _asString(json['feedImage']),

      publishedAt: publishedTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(
              publishedTimestamp * 1000,
              isUtc: true,
            ).toLocal()
          : null,

      duration: durationSeconds != null
          ? Duration(seconds: durationSeconds)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // UTILITAIRES
  // ---------------------------------------------------------------------------

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static int? _durationToSeconds(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    // Podcast Index peut fournir une durée sous forme
    // de nombre de secondes ou HH:MM:SS.
    final numeric = int.tryParse(text);

    if (numeric != null) {
      return numeric;
    }

    final parts = text.split(':');

    try {
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);

        return minutes * 60 + seconds;
      }

      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);

        return hours * 3600 + minutes * 60 + seconds;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}

// =============================================================================
// EXCEPTION
// =============================================================================

class PodcastApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const PodcastApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('PodcastApiException: $message');

    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }

    if (body != null && body!.isNotEmpty) {
      buffer.write('\n');
      buffer.write('Réponse serveur : ');
      buffer.write(body);
    }

    return buffer.toString();
  }
}
