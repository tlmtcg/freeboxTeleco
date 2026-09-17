import 'package:flutter/material.dart';

import '../controllers/podcast_episodes_controller.dart';
import '../models/podcast.dart';
import '../models/podcast_episode.dart';
import '../player/podcast_player.dart';
import 'podcast_player_page.dart';
import '../repository/podcast_repository.dart';
import '../widgets/podcast_episode_tile.dart';
import '../widgets/podcast_mini_player.dart';

class PodcastEpisodesPage extends StatefulWidget {
  final PodcastRepository repository;
  final Podcast podcast;
  final PodcastPlayer player;

  const PodcastEpisodesPage({
    super.key,
    required this.repository,
    required this.podcast,
    required this.player,
  });

  @override
  State<PodcastEpisodesPage> createState() => _PodcastEpisodesPageState();
}

class _PodcastEpisodesPageState extends State<PodcastEpisodesPage> {
  late final PodcastEpisodesController _controller;

  List<PodcastEpisode> _episodes = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = PodcastEpisodesController(
      repository: widget.repository,
      podcast: widget.podcast,
    );

    _loadEpisodes();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadEpisodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final episodes = await _controller.loadEpisodes();

      if (!mounted) {
        return;
      }

      setState(() {
        _episodes = episodes;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Erreur chargement épisodes : $e');
      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _controller.synchronize();

      await _loadEpisodes();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Épisodes synchronisés')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // LECTURE
  // ============================================================

  Future<void> _openEpisode(PodcastEpisode episode) async {
    try {
      await widget.player.play(episode);

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lire l\'épisode : $e')),
      );
    }
  }

  // ============================================================
  // PLAYER
  // ============================================================

  void _openPlayer() {
    if (widget.player.episode == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastPlayerPage(player: widget.player),
      ),
    );
  }

  // ============================================================
  // BUILD
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

      bottomNavigationBar: PodcastMiniPlayer(
        player: widget.player,
        onTap: _openPlayer,
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_episodes.isEmpty) {
      return _buildEmpty();
    }

    return _buildEpisodeList();
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError() {
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

  // ============================================================
  // VIDE
  // ============================================================

  Widget _buildEmpty() {
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

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildEpisodeList() {
    return RefreshIndicator(
      onRefresh: _loadEpisodes,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          final episode = _episodes[index];

          return PodcastEpisodeTile(
            episode: episode,
            onTap: () {
              _openEpisode(episode);
            },
          );
        },
      ),
    );
  }
}
