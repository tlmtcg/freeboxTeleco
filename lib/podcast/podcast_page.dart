// import 'package:flutter/material.dart';

// import 'api/podcast_api.dart';
// import 'models/podcast_episode.dart';
// import 'models/podcast_radio.dart';
// import 'player/podcast_player.dart';
// import 'podcast_add_radio_page.dart';
// import 'podcast_player_page.dart';
// import 'podcast_radio_page.dart';
// import 'repository/podcast_repository.dart';

// class PodcastPage extends StatefulWidget {
//   final PodcastRepository repository;
//   final PodcastApi podcastApi;

//   const PodcastPage({
//     super.key,
//     required this.repository,
//     required this.podcastApi,
//   });

//   @override
//   State<PodcastPage> createState() => _PodcastPageState();
// }

// class _PodcastPageState extends State<PodcastPage> {
//   late final PodcastPlayer _player;

//   List<PodcastRadio> _radios = [];

//   PodcastEpisode? _episodeToResume;

//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();

//     // ------------------------------------------------------------
//     // PLAYER UNIQUE POUR TOUTE LA SECTION PODCAST
//     // ------------------------------------------------------------

//     _player = PodcastPlayer(
//       repository: widget.repository,
//     );

//     _load();
//   }

//   @override
//   void dispose() {
//     // ------------------------------------------------------------
//     // Le player est détruit uniquement ici.
//     // ------------------------------------------------------------

//     _player.dispose();

//     super.dispose();
//   }

//   // ============================================================
//   // CHARGEMENT
//   // ============================================================

//   Future<void> _load() async {
//     try {
//       setState(() {
//         _loading = true;
//         _error = null;
//       });

//       final radios = await widget.repository.getRadios();

//       final episodeToResume =
//           await widget.repository.getEpisodeToResume();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _radios = radios;
//         _episodeToResume = episodeToResume;
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _loading = false;
//         _error = e.toString();
//       });
//     }
//   }

//   Future<void> _loadRadios() async {
//     try {
//       final radios = await widget.repository.getRadios();

//       final episodeToResume =
//           await widget.repository.getEpisodeToResume();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _radios = radios;
//         _episodeToResume = episodeToResume;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Erreur lors du chargement : $e',
//           ),
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // AJOUT D'UNE RADIO
//   // ============================================================

//   Future<void> _addRadio() async {
//     final added = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (context) => PodcastAddRadioPage(
//           repository: widget.repository,
//           podcastApi: widget.podcastApi,
//         ),
//       ),
//     );

//     if (added != true) {
//       return;
//     }

//     await _loadRadios();

//     if (!mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Radio ajoutée'),
//       ),
//     );
//   }

//   // ============================================================
//   // SUPPRESSION D'UNE RADIO
//   // ============================================================

//   Future<void> _deleteRadio(
//     PodcastRadio radio,
//   ) async {
//     if (radio.id == null) {
//       return;
//     }

//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text(
//             'Supprimer la radio ?',
//           ),
//           content: Text(
//             'Voulez-vous vraiment supprimer '
//             '« ${radio.name} » ?\n\n'
//             'Les podcasts associés seront également supprimés.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//               child: const Text('Annuler'),
//             ),
//             FilledButton(
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//               child: const Text('Supprimer'),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed != true) {
//       return;
//     }

//     try {
//       await widget.repository.deleteRadio(
//         radio.id!,
//       );

//       await _loadRadios();

//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             '« ${radio.name} » supprimée',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Erreur lors de la suppression : $e',
//           ),
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // REPRENDRE LA LECTURE
//   // ============================================================

//   Future<void> _resumeEpisode() async {
//     final episode = _episodeToResume;

//     if (episode == null) {
//       return;
//     }

//     try {
//       await _player.play(episode);

//       if (!mounted) {
//         return;
//       }

//       await Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => PodcastPlayerPage(
//             player: _player,
//           ),
//         ),
//       );

//       // La position peut avoir changé pendant la lecture.
//       final updatedEpisode =
//           await widget.repository.getEpisodeToResume();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _episodeToResume = updatedEpisode;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Impossible de reprendre la lecture : $e',
//           ),
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // OUVERTURE D'UNE RADIO
//   // ============================================================

//   void _openRadio(
//     PodcastRadio radio,
//   ) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => PodcastRadioPage(
//           repository: widget.repository,
//           radio: radio,
//           player: _player,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // AFFICHAGE
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Podcasts'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             tooltip: 'Ajouter une radio',
//             onPressed: _loading ? null : _addRadio,
//           ),
//         ],
//       ),
//       body: _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     if (_loading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 48,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Erreur',
//                 style: Theme.of(context)
//                     .textTheme
//                     .titleLarge,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: _load,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Réessayer'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_radios.isEmpty &&
//         _episodeToResume == null) {
//       return Center(
//         child: FilledButton.icon(
//           onPressed: _addRadio,
//           icon: const Icon(Icons.add),
//           label: const Text('Ajouter une radio'),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadRadios,
//       child: ListView(
//         padding: const EdgeInsets.only(
//           top: 12,
//           bottom: 24,
//         ),
//         children: [
//           // ------------------------------------------------------
//           // REPRISE
//           // ------------------------------------------------------

//           if (_episodeToResume != null)
//             _ResumeCard(
//               episode: _episodeToResume!,
//               onTap: _resumeEpisode,
//             ),

//           // ------------------------------------------------------
//           // TITRE RADIOS
//           // ------------------------------------------------------

//           if (_radios.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(
//                 16,
//                 20,
//                 16,
//                 4,
//               ),
//               child: Text(
//                 'Radios',
//                 style: Theme.of(context)
//                     .textTheme
//                     .titleLarge
//                     ?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//             ),

//           // ------------------------------------------------------
//           // RADIOS
//           // ------------------------------------------------------

//           ..._radios.map(
//             (radio) => _RadioTile(
//               radio: radio,
//               onTap: () => _openRadio(radio),
//               onDelete: () => _deleteRadio(radio),
//             ),
//           ),

//           if (_radios.isEmpty)
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: FilledButton.icon(
//                 onPressed: _addRadio,
//                 icon: const Icon(Icons.add),
//                 label: const Text(
//                   'Ajouter une radio',
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // =================================================================
// // REPRISE
// // =================================================================

// class _ResumeCard extends StatelessWidget {
//   final PodcastEpisode episode;
//   final VoidCallback onTap;

//   const _ResumeCard({
//     required this.episode,
//     required this.onTap,
//   });

//   String _formatDuration(
//     Duration duration,
//   ) {
//     final hours = duration.inHours;
//     final minutes =
//         duration.inMinutes.remainder(60);
//     final seconds =
//         duration.inSeconds.remainder(60);

//     if (hours > 0) {
//       return '$hours:'
//           '${minutes.toString().padLeft(2, '0')}:'
//           '${seconds.toString().padLeft(2, '0')}';
//     }

//     return '$minutes:'
//         '${seconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final duration =
//         episode.duration ?? Duration.zero;

//     return Card(
//       margin: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 6,
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             children: [
//               // --------------------------------------------------
//               // IMAGE
//               // --------------------------------------------------

//               ClipRRect(
//                 borderRadius:
//                     BorderRadius.circular(10),
//                 child: SizedBox(
//                   width: 72,
//                   height: 72,
//                   child: episode.imageUrl != null &&
//                           episode.imageUrl!.isNotEmpty
//                       ? Image.network(
//                           episode.imageUrl!,
//                           fit: BoxFit.cover,
//                           errorBuilder:
//                               (context, error, stackTrace) {
//                             return const Icon(
//                               Icons.podcasts,
//                               size: 40,
//                             );
//                           },
//                         )
//                       : const Icon(
//                           Icons.podcasts,
//                           size: 40,
//                         ),
//                 ),
//               ),

//               const SizedBox(width: 14),

//               // --------------------------------------------------
//               // TEXTE
//               // --------------------------------------------------

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Reprendre la lecture',
//                       style: Theme.of(context)
//                           .textTheme
//                           .labelLarge
//                           ?.copyWith(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .primary,
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                     ),

//                     const SizedBox(height: 4),

//                     Text(
//                       episode.title,
//                       maxLines: 2,
//                       overflow:
//                           TextOverflow.ellipsis,
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleMedium
//                           ?.copyWith(
//                             fontWeight:
//                                 FontWeight.w600,
//                           ),
//                     ),

//                     const SizedBox(height: 6),

//                     Text(
//                       duration > Duration.zero
//                           ? '${_formatDuration(episode.position)}'
//                               ' / '
//                               '${_formatDuration(duration)}'
//                           : _formatDuration(
//                               episode.position,
//                             ),
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodySmall,
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 8),

//               // --------------------------------------------------
//               // PLAY
//               // --------------------------------------------------

//               Icon(
//                 Icons.play_circle_fill,
//                 size: 40,
//                 color: Theme.of(context)
//                     .colorScheme
//                     .primary,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // =================================================================
// // RADIO TILE
// // =================================================================

// class _RadioTile extends StatelessWidget {
//   final PodcastRadio radio;
//   final VoidCallback onTap;
//   final VoidCallback onDelete;

//   const _RadioTile({
//     required this.radio,
//     required this.onTap,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 6,
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 18,
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 54,
//                 height: 54,
//                 decoration: BoxDecoration(
//                   borderRadius:
//                       BorderRadius.circular(14),
//                   color: Theme.of(context)
//                       .colorScheme
//                       .primaryContainer,
//                 ),
//                 child: Icon(
//                   Icons.radio,
//                   size: 30,
//                   color: Theme.of(context)
//                       .colorScheme
//                       .onPrimaryContainer,
//                 ),
//               ),

//               const SizedBox(width: 16),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       radio.name,
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleMedium
//                           ?.copyWith(
//                             fontWeight:
//                                 FontWeight.w600,
//                           ),
//                     ),

//                     const SizedBox(height: 4),

//                     Text(
//                       radio.searchTerm,
//                       style: Theme.of(context)
//                           .textTheme
//                           .bodySmall,
//                     ),
//                   ],
//                 ),
//               ),

//               PopupMenuButton<String>(
//                 tooltip: 'Options',
//                 onSelected: (value) {
//                   if (value == 'delete') {
//                     onDelete();
//                   }
//                 },
//                 itemBuilder: (context) => const [
//                   PopupMenuItem<String>(
//                     value: 'delete',
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.delete_outline,
//                         ),
//                         SizedBox(width: 12),
//                         Text('Supprimer'),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),

//               const Icon(Icons.chevron_right),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'api/podcast_api.dart';
import 'controllers/podcast_controller.dart';
import 'models/podcast_episode.dart';
import 'models/podcast_radio.dart';
import 'player/podcast_player.dart';
import 'podcast_add_radio_page.dart';
import 'pages/podcast_player_page.dart';
import 'pages/podcast_radio_page.dart';
import 'repository/podcast_repository.dart';

import 'widgets/podcast_radio_tile.dart';
import 'widgets/podcast_resume_card.dart';

class PodcastPage extends StatefulWidget {
  final PodcastRepository repository;
  final PodcastApi podcastApi;

  const PodcastPage({
    super.key,
    required this.repository,
    required this.podcastApi,
  });

  @override
  State<PodcastPage> createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  late final PodcastController _controller;

  late final PodcastPlayer _player;

  List<PodcastRadio> _radios = [];

  PodcastEpisode? _episodeToResume;

  bool _loading = true;
  String? _error;

  // ============================================================
  // INITIALISATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = PodcastController(repository: widget.repository);

    _player = PodcastPlayer(repository: widget.repository);

    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _controller.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _radios = data.radios;
        _episodeToResume = data.episodeToResume;
        _loading = false;
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

  Future<void> _loadRadios() async {
    try {
      final data = await _controller.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _radios = data.radios;
        _episodeToResume = data.episodeToResume;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Erreur lors du chargement : $e');
    }
  }

  // ============================================================
  // AJOUT RADIO
  // ============================================================

  Future<void> _addRadio() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PodcastAddRadioPage(
          repository: widget.repository,
          podcastApi: widget.podcastApi,
        ),
      ),
    );

    if (added != true) {
      return;
    }

    await _loadRadios();

    if (!mounted) {
      return;
    }

    _showMessage('Radio ajoutée');
  }

  // ============================================================
  // SUPPRESSION RADIO
  // ============================================================

  Future<void> _deleteRadio(PodcastRadio radio) async {
    final confirmed = await _confirmDeleteRadio(radio);

    if (confirmed != true) {
      return;
    }

    try {
      await _controller.deleteRadio(radio);

      await _loadRadios();

      if (!mounted) {
        return;
      }

      _showMessage('« ${radio.name} » supprimée');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Erreur lors de la suppression : $e');
    }
  }

  Future<bool?> _confirmDeleteRadio(PodcastRadio radio) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la radio ?'),
          content: Text(
            'Voulez-vous vraiment supprimer '
            '« ${radio.name} » ?\n\n'
            'Les podcasts associés seront '
            'également supprimés.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REPRISE
  // ============================================================

  Future<void> _resumeEpisode() async {
    final episode = _episodeToResume;

    if (episode == null) {
      return;
    }

    try {
      await _player.play(episode);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PodcastPlayerPage(player: _player)),
      );

      await _refreshResumeEpisode();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Impossible de reprendre la lecture : $e');
    }
  }

  Future<void> _refreshResumeEpisode() async {
    try {
      final episode = await _controller.getEpisodeToResume();

      if (!mounted) {
        return;
      }

      setState(() {
        _episodeToResume = episode;
      });
    } catch (e) {
      debugPrint('Erreur actualisation reprise : $e');
    }
  }

  // ============================================================
  // NAVIGATION RADIO
  // ============================================================

  void _openRadio(PodcastRadio radio) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastRadioPage(
          repository: widget.repository,
          radio: radio,
          player: _player,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une radio',
            onPressed: _loading ? null : _addRadio,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_radios.isEmpty && _episodeToResume == null) {
      return _buildNoRadio();
    }

    return _buildList();
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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUCUNE RADIO
  // ============================================================

  Widget _buildNoRadio() {
    return Center(
      child: FilledButton.icon(
        onPressed: _addRadio,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une radio'),
      ),
    );
  }

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRadios,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: [
          if (_episodeToResume != null)
            PodcastResumeCard(
              episode: _episodeToResume!,
              onTap: _resumeEpisode,
            ),

          if (_radios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                'Radios',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

          ..._radios.map(
            (radio) => PodcastRadioTile(
              radio: radio,
              onTap: () => _openRadio(radio),
              onDelete: () => _deleteRadio(radio),
            ),
          ),

          if (_radios.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.icon(
                onPressed: _addRadio,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une radio'),
              ),
            ),
        ],
      ),
    );
  }
}
