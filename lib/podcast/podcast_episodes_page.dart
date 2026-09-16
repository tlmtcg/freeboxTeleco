import 'package:flutter/material.dart';

import 'models/podcast.dart';
import 'models/podcast_episode.dart';
import 'repository/podcast_repository.dart';
import 'player/podcast_player.dart';
import 'podcast_player_page.dart';

class PodcastEpisodesPage extends StatefulWidget {
  final PodcastRepository repository;
  final Podcast podcast;

  const PodcastEpisodesPage({
    super.key,
    required this.repository,
    required this.podcast,
  });

  @override
  State<PodcastEpisodesPage> createState() => _PodcastEpisodesPageState();
}

class _PodcastEpisodesPageState extends State<PodcastEpisodesPage> {
  List<PodcastEpisode> _episodes = [];

  bool _loading = true;
  String? _error;
  late final PodcastPlayer _player;

  @override
  void initState() {
    super.initState();

    _player = PodcastPlayer(repository: widget.repository);

    _loadEpisodes();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadEpisodes() async {
    if (widget.podcast.id == null) {
      setState(() {
        _loading = false;
        _error = 'Le podcast ne possède pas d\'ID SQLite.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ----------------------------------------------------------
      // 1. Lecture SQLite
      // ----------------------------------------------------------

      var episodes = await widget.repository.getEpisodes(
        widget.podcast.id!,
        limit: 50,
      );

      // ----------------------------------------------------------
      // 2. Aucun épisode en SQLite
      //    → synchronisation automatique
      // ----------------------------------------------------------

      if (episodes.isEmpty) {
        debugPrint('');
        debugPrint('========================================');
        debugPrint('     SYNCHRONISATION AUTOMATIQUE');
        debugPrint('========================================');
        debugPrint('Podcast : ${widget.podcast.title}');
        debugPrint('Podcast Index ID : ${widget.podcast.podcastIndexId}');

        await widget.repository.synchronizeEpisodes(
          widget.podcast,
          maxEpisodes: 50,
        );

        // --------------------------------------------------------
        // 3. Relecture SQLite après synchronisation
        // --------------------------------------------------------

        episodes = await widget.repository.getEpisodes(
          widget.podcast.id!,
          limit: 50,
        );

        debugPrint('Épisodes récupérés : ${episodes.length}');

        debugPrint('========================================');
      }

      if (!mounted) return;

      setState(() {
        _episodes = episodes;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('       ERREUR ÉPISODES');
      debugPrint('========================================');
      debugPrint('$e');
      debugPrint('');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // SYNCHRONISATION
  // ============================================================

  Future<void> _synchronize() async {
    if (widget.podcast.id == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.repository.synchronizeEpisodes(
        widget.podcast,
        maxEpisodes: 50,
      );

      await _loadEpisodes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Épisodes synchronisés')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // AFFICHAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.podcast.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser',
            onPressed: _loading ? null : _synchronize,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildMiniPlayer(),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _openPlayer() {
    if (_player.episode == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PodcastPlayerPage(player: _player),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return AnimatedBuilder(
      animation: _player,
      builder: (context, child) {
        final episode = _player.episode;

        if (episode == null) {
          return const SizedBox.shrink();
        }

        final duration = _player.duration ?? Duration.zero;

        final position = _player.position;

        final maxSeconds = duration.inMilliseconds > 0
            ? duration.inMilliseconds.toDouble()
            : 1.0;

        final currentSeconds = position.inMilliseconds
            .clamp(
              0,
              duration.inMilliseconds > 0
                  ? duration.inMilliseconds
                  : position.inMilliseconds,
            )
            .toDouble();

        return Material(
          elevation: 12,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: _openPlayer,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (episode.imageUrl != null &&
                            episode.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              episode.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.podcasts),
                                );
                              },
                            ),
                          )
                        else
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.podcasts),
                          ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            episode.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            _player.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            _player.togglePlayPause();
                          },
                        ),
                      ],
                    ),

                    Slider(
                      value: currentSeconds,
                      max: maxSeconds,
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.round()));
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position)),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Erreur', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadEpisodes,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_episodes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _synchronize,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.35),
            const Icon(Icons.podcasts, size: 64),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Aucun épisode',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Synchronisez le podcast.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEpisodes,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          final episode = _episodes[index];

          return _EpisodeTile(
            episode: episode,
            onTap: () {
              _openEpisode(episode);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // EPISODE
  // ============================================================

  Future<void> _openEpisode(PodcastEpisode episode) async {
    try {
      await _player.play(episode);

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lire l\'épisode : $e')),
      );
    }
  }
}

// =================================================================
// EPISODE TILE
// =================================================================

class _EpisodeTile extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const _EpisodeTile({required this.episode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EpisodeImage(imageUrl: episode.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: episode.listened
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (episode.publishedAt != null)
                      Text(
                        _formatDate(episode.publishedAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                    if (episode.duration != null)
                      Text(
                        _formatDuration(episode.duration!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                    if (episode.position > Duration.zero)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Reprise à ${_formatDuration(episode.position)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // --------------------------------------------------
              // ÉTAT
              // --------------------------------------------------
              Column(
                children: [
                  Icon(
                    episode.listened
                        ? Icons.check_circle
                        : Icons.play_circle_outline,
                    color: episode.listened
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _EpisodeImage({required String? imageUrl}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _placeholder();
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black12,
      child: const Icon(Icons.podcasts, size: 36),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h '
          '${minutes.toString().padLeft(2, '0')}min';
    }

    if (minutes > 0) {
      return '${minutes}min '
          '${seconds.toString().padLeft(2, '0')}s';
    }

    return '${seconds}s';
  }
}
