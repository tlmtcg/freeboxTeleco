import 'package:flutter/material.dart';

import 'models/podcast.dart';
import 'models/podcast_radio.dart';
import 'repository/podcast_repository.dart';
import 'podcast_episodes_page.dart';

class PodcastPage extends StatefulWidget {
  final PodcastRepository repository;
  final PodcastRadio radio;

  const PodcastPage({super.key, required this.repository, required this.radio});

  @override
  State<PodcastPage> createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Podcast> _podcasts = [];

  bool _loading = true;
  bool _synchronizing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT SQLITE
  // ============================================================

  Future<void> _loadPodcasts() async {
    if (widget.radio.id == null) {
      setState(() {
        _loading = false;
        _error = 'La radio ne possède pas d\'ID SQLite.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final podcasts = await widget.repository.getPodcastsForRadio(
        widget.radio.id!,
      );

      if (!mounted) return;

      setState(() {
        _podcasts = podcasts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // RECHERCHE LOCALE
  // ============================================================

  Future<void> _search(String value) async {
    if (widget.radio.id == null) return;

    try {
      final podcasts = await widget.repository.searchLocalPodcasts(
        value,
        radioId: widget.radio.id!,
      );

      if (!mounted) return;

      setState(() {
        _podcasts = podcasts;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // SYNCHRONISATION
  // ============================================================

  Future<void> _synchronize() async {
    if (_synchronizing) return;

    setState(() {
      _synchronizing = true;
      _error = null;
    });

    try {
      final count = await widget.repository.synchronizeRadio(
        widget.radio,
        maxPodcasts: 20,
      );

      await _loadPodcasts();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count podcasts synchronisés')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de synchronisation : $e')));
    } finally {
      if (mounted) {
        setState(() {
          _synchronizing = false;
        });
      }
    }
  }

  // ============================================================
  // AFFICHAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.radio.name),
        actions: [
          if (_synchronizing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Synchroniser',
              onPressed: _synchronize,
            ),
        ],
      ),
      body: Column(
        children: [
          // ------------------------------------------------------
          // RECHERCHE
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un podcast...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // CONTENU
          // ------------------------------------------------------
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
                onPressed: _loadPodcasts,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_podcasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.podcasts, size: 64),
              const SizedBox(height: 16),
              Text(
                'Aucun podcast',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Synchronisez la radio pour récupérer '
                'les podcasts.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _synchronize,
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPodcasts,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _podcasts.length,
        itemBuilder: (context, index) {
          final podcast = _podcasts[index];

          return _PodcastTile(
            podcast: podcast,
            onTap: () {
              _openPodcast(podcast);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // OUVERTURE DU PODCAST
  // ============================================================

  void _openPodcast(Podcast podcast) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PodcastEpisodesPage(
          repository: widget.repository,
          podcast: podcast,
        ),
      ),
    );
  }
}

// =================================================================
// PODCAST TILE
// =================================================================

class _PodcastTile extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const _PodcastTile({required this.podcast, required this.onTap});

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
              _PodcastImage(imageUrl: podcast.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (podcast.description != null &&
                        podcast.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _cleanDescription(podcast.description!),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanDescription(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// =================================================================
// IMAGE
// =================================================================

class _PodcastImage extends StatelessWidget {
  final String? imageUrl;

  const _PodcastImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 90,
        height: 90,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _placeholder(context);
                },
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.podcasts, size: 40),
    );
  }
}
