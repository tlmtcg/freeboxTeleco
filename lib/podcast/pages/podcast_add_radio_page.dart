// import 'package:flutter/material.dart';

// import 'api/podcast_api.dart';
// import 'models/podcast.dart';
// import 'models/podcast_radio.dart';
// import 'repository/podcast_repository.dart';

// class PodcastAddRadioPage extends StatefulWidget {
//   final PodcastRepository repository;
//   final PodcastApi podcastApi;

//   const PodcastAddRadioPage({
//     super.key,
//     required this.repository,
//     required this.podcastApi,
//   });

//   @override
//   State<PodcastAddRadioPage> createState() => _PodcastAddRadioPageState();
// }

// class _PodcastAddRadioPageState extends State<PodcastAddRadioPage> {
//   final TextEditingController _searchController = TextEditingController();

//   List<Podcast> _results = [];
//   Podcast? _selectedPodcast;

//   bool _searching = false;
//   bool _saving = false;

//   String? _error;

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // ===========================================================================
//   // RECHERCHE PODCAST INDEX
//   // ===========================================================================

//   Future<void> _search() async {
//     final query = _searchController.text.trim();

//     if (query.isEmpty) {
//       setState(() {
//         _error = 'Veuillez saisir le nom d’une radio ou d’un podcast.';
//         _results = [];
//         _selectedPodcast = null;
//       });
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       _searching = true;
//       _error = null;
//       _results = [];
//       _selectedPodcast = null;
//     });

//     try {
//       final results = await widget.podcastApi.searchPodcasts(
//         query,
//         max: 20,
//       );

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _searching = false;
//         _results = results;

//         if (results.isEmpty) {
//           _error = 'Aucun résultat trouvé pour « $query ».';
//         }
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _searching = false;
//         _error = e.toString();
//       });
//     }
//   }

//   // ===========================================================================
//   // SELECTION
//   // ===========================================================================

//   void _selectPodcast(Podcast podcast) {
//     setState(() {
//       _selectedPodcast = podcast;
//       _error = null;
//     });
//   }

//   // ===========================================================================
//   // AJOUT DE LA RADIO
//   // ===========================================================================

//   Future<void> _addRadio() async {
//     final selected = _selectedPodcast;

//     if (selected == null) {
//       setState(() {
//         _error = 'Veuillez sélectionner une radio dans les résultats.';
//       });
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() {
//       _saving = true;
//       _error = null;
//     });

//     try {
//       // -----------------------------------------------------------------------
//       // Vérification d'une éventuelle radio existante
//       // -----------------------------------------------------------------------

//       final radios = await widget.repository.getRadios();

//       final alreadyExists = radios.any(
//         (radio) => radio.name.toLowerCase() == selected.title.toLowerCase(),
//       );

//       if (alreadyExists) {
//         throw Exception('Cette radio existe déjà.');
//       }

//       // -----------------------------------------------------------------------
//       // Ajout
//       //
//       // Le modèle PodcastRadio actuel possède encore searchTerm.
//       // On le renseigne automatiquement avec le terme saisi.
//       // L'utilisateur n'a plus à le saisir séparément.
//       // -----------------------------------------------------------------------

//       final searchTerm = _searchController.text.trim();

//       final radio = PodcastRadio(
//         name: selected.title,
//         searchTerm: searchTerm,
//       );

//       final id = await widget.repository.addRadio(radio);

//       if (id == 0) {
//         throw Exception('Impossible d’ajouter la radio.');
//       }

//       if (!mounted) {
//         return;
//       }

//       Navigator.of(context).pop(true);
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _saving = false;
//         _error = e.toString();
//       });
//     }
//   }

//   // ===========================================================================
//   // AFFICHAGE
//   // ===========================================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ajouter une radio'),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildSearchArea(),

//             const Divider(height: 1),

//             Expanded(
//               child: _buildResults(),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _selectedPodcast != null
//           ? SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                 child: FilledButton.icon(
//                   onPressed: _saving ? null : _addRadio,
//                   icon: _saving
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(Icons.add),
//                   label: Text(
//                     _saving
//                         ? 'Ajout en cours...'
//                         : 'Ajouter la radio',
//                   ),
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   // ===========================================================================
//   // ZONE DE RECHERCHE
//   // ===========================================================================

//   Widget _buildSearchArea() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Ajouter une radio',
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             'Recherchez le nom d’une radio ou d’un podcast.',
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//           ),

//           const SizedBox(height: 16),

//           TextField(
//             controller: _searchController,
//             enabled: !_searching && !_saving,
//             textCapitalization: TextCapitalization.words,
//             textInputAction: TextInputAction.search,
//             onSubmitted: (_) => _search(),
//             decoration: InputDecoration(
//               labelText: 'Nom de la radio ou du podcast',
//               hintText: 'France Inter',
//               prefixIcon: const Icon(Icons.search),
//               suffixIcon: _searchController.text.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () {
//                         _searchController.clear();

//                         setState(() {
//                           _results = [];
//                           _selectedPodcast = null;
//                           _error = null;
//                         });
//                       },
//                     )
//                   : null,
//               filled: true,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//             onChanged: (_) {
//               setState(() {});
//             },
//           ),

//           const SizedBox(height: 12),

//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: FilledButton.icon(
//               onPressed: _searching || _saving ? null : _search,
//               icon: _searching
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : const Icon(Icons.search),
//               label: Text(
//                 _searching ? 'Recherche...' : 'Rechercher',
//               ),
//             ),
//           ),

//           if (_error != null && _results.isEmpty) ...[
//             const SizedBox(height: 16),
//             _buildError(),
//           ],
//         ],
//       ),
//     );
//   }

//   // ===========================================================================
//   // RESULTATS
//   // ===========================================================================

//   Widget _buildResults() {
//     if (_searching) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     if (_results.isEmpty) {
//       if (_error != null) {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Text(
//               _error!,
//               textAlign: TextAlign.center,
//             ),
//           ),
//         );
//       }

//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Text(
//             'Saisissez le nom d’une radio ou d’un podcast '
//             'puis lancez la recherche.',
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//           ),
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//       itemCount: _results.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (context, index) {
//         return _buildPodcastCard(_results[index]);
//       },
//     );
//   }

//   // ===========================================================================
//   // RESULTAT
//   // ===========================================================================

//   Widget _buildPodcastCard(Podcast podcast) {
//     final selected = _selectedPodcast?.podcastIndexId ==
//         podcast.podcastIndexId;

//     return Card(
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () => _selectPodcast(podcast),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildArtwork(podcast),

//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       podcast.title,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),

//                     if (podcast.description != null &&
//                         podcast.description!.isNotEmpty) ...[
//                       const SizedBox(height: 6),

//                       Text(
//                         podcast.description!,
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .onSurfaceVariant,
//                             ),
//                       ),
//                     ],

//                     if (podcast.podcastIndexId != null) ...[
//                       const SizedBox(height: 6),

//                       Text(
//                         'Podcast Index : ${podcast.podcastIndexId}',
//                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .onSurfaceVariant,
//                             ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 8),

//               Icon(
//                 selected
//                     ? Icons.radio_button_checked
//                     : Icons.radio_button_off,
//                 color: selected
//                     ? Theme.of(context).colorScheme.primary
//                     : Theme.of(context)
//                         .colorScheme
//                         .onSurfaceVariant,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ===========================================================================
//   // IMAGE
//   // ===========================================================================

//   Widget _buildArtwork(Podcast podcast) {
//     const size = 72.0;

//     if (podcast.imageUrl == null || podcast.imageUrl!.isEmpty) {
//       return Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10),
//           color: Theme.of(context)
//               .colorScheme
//               .surfaceContainerHighest,
//         ),
//         child: const Icon(
//           Icons.radio,
//           size: 36,
//         ),
//       );
//     }

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(10),
//       child: Image.network(
//         podcast.imageUrl!,
//         width: size,
//         height: size,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) {
//           return Container(
//             width: size,
//             height: size,
//             color: Theme.of(context)
//                 .colorScheme
//                 .surfaceContainerHighest,
//             child: const Icon(
//               Icons.radio,
//               size: 36,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ===========================================================================
//   // ERREUR
//   // ===========================================================================

//   Widget _buildError() {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Theme.of(context).colorScheme.errorContainer,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.error_outline,
//             color: Theme.of(context).colorScheme.onErrorContainer,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               _error!,
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onErrorContainer,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../api/podcast_api.dart';
import '../controllers/podcast_add_radio_controller.dart';
import '../models/podcast.dart';
import '../repository/podcast_repository.dart';
import '../widgets/podcast_add_radio_search.dart';
import '../widgets/podcast_error_message.dart';
import '../widgets/podcast_search_result_tile.dart';

class PodcastAddRadioPage extends StatefulWidget {
  final PodcastRepository repository;
  final PodcastApi podcastApi;

  const PodcastAddRadioPage({
    super.key,
    required this.repository,
    required this.podcastApi,
  });

  @override
  State<PodcastAddRadioPage> createState() =>
      _PodcastAddRadioPageState();
}

class _PodcastAddRadioPageState
    extends State<PodcastAddRadioPage> {
  late final PodcastAddRadioController _controller;

  final TextEditingController _searchController =
      TextEditingController();

  List<Podcast> _results = [];

  Podcast? _selectedPodcast;

  bool _searching = false;
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = PodcastAddRadioController(
      repository: widget.repository,
      podcastApi: widget.podcastApi,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // RECHERCHE
  // ===========================================================================

  Future<void> _search() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error =
            'Veuillez saisir le nom d’une radio ou d’un podcast.';
        _results = [];
        _selectedPodcast = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _searching = true;
      _error = null;
      _results = [];
      _selectedPodcast = null;
    });

    try {
      final results = await _controller.search(query);

      if (!mounted) return;

      setState(() {
        _searching = false;
        _results = results;

        if (results.isEmpty) {
          _error = 'Aucun résultat trouvé pour « $query ».';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _error = _cleanError(e);
      });
    }
  }

  // ===========================================================================
  // SELECTION
  // ===========================================================================

  void _selectPodcast(Podcast podcast) {
    setState(() {
      _selectedPodcast = podcast;
      _error = null;
    });
  }

  // ===========================================================================
  // AJOUT
  // ===========================================================================

  Future<void> _addRadio() async {
    final selected = _selectedPodcast;

    if (selected == null) {
      setState(() {
        _error =
            'Veuillez sélectionner une radio dans les résultats.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _controller.addRadio(
        podcast: selected,
        searchTerm: _searchController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = _cleanError(e);
      });
    }
  }

  // ===========================================================================
  // EFFACER
  // ===========================================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _results = [];
      _selectedPodcast = null;
      _error = null;
    });
  }

  // ===========================================================================
  // ERREUR
  // ===========================================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une radio'),
      ),

      body: SafeArea(
        child: Column(
          children: [
            PodcastAddRadioSearch(
              controller: _searchController,
              enabled: !_searching && !_saving,
              searching: _searching,
              onSearch: _search,
              onClear: _clearSearch,
              onChanged: (_) {
                setState(() {});
              },
            ),

            if (_error != null && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16,
                ),
                child: PodcastErrorMessage(
                  message: _error!,
                ),
              ),

            const Divider(height: 1),

            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ===========================================================================
  // RESULTATS
  // ===========================================================================

  Widget _buildResults() {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final podcast = _results[index];

        return PodcastSearchResultTile(
          podcast: podcast,
          selected: _isSelected(podcast),
          onTap: () => _selectPodcast(podcast),
        );
      },
    );
  }

  bool _isSelected(Podcast podcast) {
    return _selectedPodcast?.podcastIndexId ==
        podcast.podcastIndexId;
  }

  // ===========================================================================
  // RESULTATS VIDES
  // ===========================================================================

  Widget _buildEmptyResults() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Saisissez le nom d’une radio ou d’un podcast '
          'puis lancez la recherche.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOUTON AJOUT
  // ===========================================================================

  Widget? _buildBottomBar() {
    if (_selectedPodcast == null) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child: FilledButton.icon(
          onPressed: _saving ? null : _addRadio,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.add),
          label: Text(
            _saving
                ? 'Ajout en cours...'
                : 'Ajouter la radio',
          ),
        ),
      ),
    );
  }
}
