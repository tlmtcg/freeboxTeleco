import '../api/podcast_api.dart';
import '../database/podcast_database.dart';
import '../models/podcast.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_radio.dart';

import 'package:sqflite/sqflite.dart';

class PodcastRepository {
  final PodcastApi api;
  final PodcastDatabase database;

  PodcastRepository({required this.api, PodcastDatabase? database})
    : database = database ?? PodcastDatabase.instance;

  // ============================================================
  // PodcastRadioS
  // ============================================================

  Future<int> addRadio(PodcastRadio radio) async {
    final db = await database.database;

    return db.insert('radios', {
      'name': radio.name,
      'search_term': radio.searchTerm,
      'enabled': radio.enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<PodcastRadio>> getRadios() async {
    final db = await database.database;

    final rows = await db.query('radios', orderBy: 'name COLLATE NOCASE ASC');

    return rows.map(_radioFromRow).toList();
  }

  Future<PodcastRadio?> getRadio(int id) async {
    final db = await database.database;

    final rows = await db.query(
      'radios',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _radioFromRow(rows.first);
  }

  Future<void> setRadioEnabled(int radioId, bool enabled) async {
    final db = await database.database;

    await db.update(
      'radios',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [radioId],
    );
  }

  // ============================================================
  // PODCASTS
  // ============================================================

  Future<List<Podcast>> getPodcastsForRadio(int radioId) async {
    final db = await database.database;

    final rows = await db.query(
      'podcasts',
      where: 'radio_id = ?',
      whereArgs: [radioId],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map(_podcastFromRow).toList();
  }

  Future<Podcast?> getPodcast(int id) async {
    final db = await database.database;

    final rows = await db.query(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _podcastFromRow(rows.first);
  }

  Future<Podcast?> getPodcastByIndexId(int podcastIndexId) async {
    final db = await database.database;

    final rows = await db.query(
      'podcasts',
      where: 'podcast_index_id = ?',
      whereArgs: [podcastIndexId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _podcastFromRow(rows.first);
  }

  // ============================================================
  // SYNCHRONISATION RADIO → PODCASTS
  // ============================================================

  Future<int> synchronizeRadio(
    PodcastRadio radio, {
    int maxPodcasts = 20,
  }) async {
    if (radio.id == null) {
      throw ArgumentError(
        'La radio doit être enregistrée en base avant synchronisation.',
      );
    }

    final podcasts = await api.searchPodcasts(
      radio.searchTerm,
      max: maxPodcasts,
    );

    int count = 0;

    for (final podcast in podcasts) {
      if (podcast.podcastIndexId == null) {
        continue;
      }

      await _upsertPodcast(podcast, radioId: radio.id!);

      count++;
    }

    return count;
  }

  Future<int> _upsertPodcast(Podcast podcast, {required int radioId}) async {
    final db = await database.database;

    final existing = await getPodcastByIndexId(podcast.podcastIndexId!);

    final values = {
      'podcast_index_id': podcast.podcastIndexId,
      'radio_id': radioId,
      'title': podcast.title,
      'description': podcast.description,
      'image_url': podcast.imageUrl,
      'feed_url': podcast.feedUrl,
      'website_url': podcast.websiteUrl,
      'last_updated': podcast.lastUpdated?.millisecondsSinceEpoch,
    };

    if (existing == null) {
      return db.insert('podcasts', values);
    }

    await db.update(
      'podcasts',
      values,
      where: 'id = ?',
      whereArgs: [existing.id],
    );

    return existing.id!;
  }

  // ============================================================
  // EPISODES
  // ============================================================

  Future<List<PodcastEpisode>> getEpisodes(int podcastId, {int? limit}) async {
    final db = await database.database;

    final rows = await db.query(
      'episodes',
      where: 'podcast_id = ?',
      whereArgs: [podcastId],
      orderBy: 'published_at DESC',
      limit: limit,
    );

    return rows.map(_episodeFromRow).toList();
  }

  Future<void> synchronizeEpisodes(Podcast podcast, {int? maxEpisodes}) async {
    if (podcast.id == null) {
      throw ArgumentError('Le podcast doit être enregistré en base.');
    }

    if (podcast.podcastIndexId == null) {
      throw ArgumentError('Le podcast ne possède pas de Podcast Index ID.');
    }

    final episodes = await api.getEpisodes(
      podcast.podcastIndexId!,
      max: maxEpisodes,
    );

    for (final episode in episodes) {
      if (episode.guid.isEmpty || episode.audioUrl.isEmpty) {
        continue;
      }

      await _upsertEpisode(episode, podcastId: podcast.id!);
    }
  }

  Future<void> _upsertEpisode(
    PodcastEpisode episode, {
    required int podcastId,
  }) async {
    final db = await database.database;

    final values = {
      'podcast_id': podcastId,
      'guid': episode.guid,
      'title': episode.title,
      'description': episode.description,
      'audio_url': episode.audioUrl,
      'image_url': episode.imageUrl,
      'published_at': episode.publishedAt?.millisecondsSinceEpoch,
      'duration_seconds': episode.duration?.inSeconds,
    };

    final existing = await db.query(
      'episodes',
      columns: ['id'],
      where: 'podcast_id = ? AND guid = ?',
      whereArgs: [podcastId, episode.guid],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('episodes', values);
      return;
    }

    /*
     * On met à jour les informations venant de Podcast Index,
     * mais on conserve :
     *
     *   listened
     *   position_seconds
     *
     * car ce sont des données locales à l'utilisateur.
     */
    await db.update(
      'episodes',
      values,
      where: 'id = ?',
      whereArgs: [existing.first['id']],
    );
  }

  // ============================================================
  // PROGRESSION / ÉCOUTE
  // ============================================================

  Future<void> setEpisodeListened(int episodeId, bool listened) async {
    final db = await database.database;

    await db.update(
      'episodes',
      {'listened': listened ? 1 : 0},
      where: 'id = ?',
      whereArgs: [episodeId],
    );
  }

  Future<void> saveEpisodePosition(int episodeId, Duration position) async {
    final db = await database.database;

    await db.update(
      'episodes',
      {'position_seconds': position.inSeconds},
      where: 'id = ?',
      whereArgs: [episodeId],
    );
  }

  // ============================================================
  // RECHERCHE / FILTRAGE LOCAL
  // ============================================================

  Future<List<Podcast>> searchLocalPodcasts(
    String query, {
    int? radioId,
  }) async {
    final db = await database.database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (query.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR description LIKE ?)');

      final pattern = '%${query.trim()}%';

      args.add(pattern);
      args.add(pattern);
    }

    if (radioId != null) {
      conditions.add('radio_id = ?');
      args.add(radioId);
    }

    final rows = await db.query(
      'podcasts',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map(_podcastFromRow).toList();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteRadio(int radioId) async {
    final db = await database.database;

    await db.delete('radios', where: 'id = ?', whereArgs: [radioId]);
  }

  Future<void> deletePodcast(int podcastId) async {
    final db = await database.database;

    await db.delete('podcasts', where: 'id = ?', whereArgs: [podcastId]);
  }

  // ============================================================
  // CONVERSION SQLite → MODELES
  // ============================================================

  PodcastRadio _radioFromRow(Map<String, Object?> row) {
    return PodcastRadio(
      id: row['id'] as int?,
      name: row['name'] as String,
      searchTerm: row['search_term'] as String,
      enabled: (row['enabled'] as int) != 0,
    );
  }

  Podcast _podcastFromRow(Map<String, Object?> row) {
    final lastUpdated = row['last_updated'] as int?;

    return Podcast(
      id: row['id'] as int?,
      podcastIndexId: row['podcast_index_id'] as int?,
      radioId: row['radio_id'] as int?,
      title: row['title'] as String,
      description: row['description'] as String?,
      imageUrl: row['image_url'] as String?,
      feedUrl: row['feed_url'] as String?,
      websiteUrl: row['website_url'] as String?,
      lastUpdated: lastUpdated != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUpdated)
          : null,
    );
  }

  PodcastEpisode _episodeFromRow(Map<String, Object?> row) {
    final publishedAt = row['published_at'] as int?;
    final duration = row['duration_seconds'] as int?;
    final position = row['position_seconds'] as int?;

    return PodcastEpisode(
      id: row['id'] as int?,
      podcastId: row['podcast_id'] as int,
      guid: row['guid'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      audioUrl: row['audio_url'] as String,
      imageUrl: row['image_url'] as String?,
      publishedAt: publishedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(publishedAt)
          : null,
      duration: duration != null ? Duration(seconds: duration) : null,
      listened: (row['listened'] as int) != 0,
      position: Duration(seconds: position ?? 0),
    );
  }
}
