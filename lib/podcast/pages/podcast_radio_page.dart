import 'package:flutter/material.dart';

import '../models/podcast.dart';
import '../models/podcast_radio.dart';
import '../player/podcast_player.dart';
import 'podcast_episodes_page.dart';
import '../repository/podcast_repository.dart';

import '../controllers/podcast_radio_controller.dart';
import '../services/podcast_filter_service.dart';

import '../widgets/podcast_category_filter.dart';
import '../widgets/podcast_tile.dart';
import '../widgets/podcast_radio_search.dart';

class PodcastRadioPage extends StatefulWidget {
  final PodcastRepository repository;
  final PodcastRadio radio;
  final PodcastPlayer player;

  const PodcastRadioPage({
    super.key,
    required this.repository,
    required this.radio,
    required this.player,
  });

  @override
  State<PodcastRadioPage> createState() => _PodcastRadioPageState();
}

class _PodcastRadioPageState extends State<PodcastRadioPage> {
  late final PodcastRadioController _controller;

  final PodcastFilterService _filterService = PodcastFilterService();

  List<Podcast> _podcasts = [];

  bool _loading = true;
  String? _error;

  String _search = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    _controller = PodcastRadioController(
      repository: widget.repository,
      radio: widget.radio,
    );

    _loadPodcasts();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadPodcasts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final podcasts = await _controller.loadPodcasts();

      if (!mounted) {
        return;
      }

      setState(() {
        _podcasts = podcasts;
        _loading = false;

        _validateSelectedCategory();
      });
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
  // SYNCHRONISATION
  // ============================================================

  Future<void> _synchronize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _controller.synchronize();

      await _loadPodcasts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Podcasts synchronisés')));
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
  // CATEGORIES
  // ============================================================

  List<String> get _categories {
    return _filterService.getCategories(_podcasts);
  }

  void _validateSelectedCategory() {
    if (_selectedCategory == null) {
      return;
    }

    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
  }

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<Podcast> get _filteredPodcasts {
    return _filterService.filter(
      podcasts: _podcasts,
      search: _search,
      category: _selectedCategory,
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openPodcast(Podcast podcast) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastEpisodesPage(
          repository: widget.repository,
          podcast: podcast,
          player: widget.player,
        ),
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
          widget.radio.name,
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
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_podcasts.isEmpty) {
      return _buildEmpty();
    }

    return _buildPodcastList();
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
              onPressed: _loadPodcasts,
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.30),
          const Icon(Icons.podcasts, size: 64),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aucun podcast',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Synchronisez la radio.')),
        ],
      ),
    );
  }

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildPodcastList() {
    final podcasts = _filteredPodcasts;

    return RefreshIndicator(
      onRefresh: _loadPodcasts,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          PodcastRadioSearch(
            value: _search,
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
          ),

          PodcastCategoryFilter(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),

          if (podcasts.isEmpty)
            _buildNoResult()
          else
            ...podcasts.map(
              (podcast) => PodcastTile(
                podcast: podcast,
                onTap: () {
                  _openPodcast(podcast);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucun podcast trouvé',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
