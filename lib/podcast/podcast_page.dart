// import 'package:flutter/material.dart';

// import 'models/podcast_radio.dart';
// import 'repository/podcast_repository.dart';

// import 'podcast_radio_page.dart';
// import 'podcast_add_radio_page.dart';

// class PodcastPage extends StatefulWidget {
//   final PodcastRepository repository;

//   const PodcastPage({super.key, required this.repository});

//   @override
//   State<PodcastPage> createState() => _PodcastPageState();
// }

// class _PodcastPageState extends State<PodcastPage> {
//   List<PodcastRadio> _radios = [];

//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadRadios();
//   }

//   // ============================================================
//   // CHARGEMENT DES RADIOS
//   // ============================================================

//   Future<void> _loadRadios() async {
//     try {
//       setState(() {
//         _loading = true;
//         _error = null;
//       });

//       var radios = await widget.repository.getRadios();

//       // ----------------------------------------------------------
//       // France Inter est notre première radio par défaut.
//       // ----------------------------------------------------------

//       final franceInterExists = radios.any(
//         (radio) => radio.name == 'France Inter',
//       );

//       if (!franceInterExists) {
//         final id = await widget.repository.addRadio(
//           const PodcastRadio(name: 'France Inter', searchTerm: 'France Inter'),
//         );

//         if (id == 0) {
//           throw Exception('Impossible de créer la radio France Inter.');
//         }

//         radios = await widget.repository.getRadios();
//       }

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _radios = radios;
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

//   // ============================================================
//   // AJOUT D'UNE RADIO
//   // ============================================================

// Future<void> _addRadio() async {
//     final added = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (context) =>
//             PodcastAddRadioPage(repository: widget.repository,
//           podcastApi: podcastApi,
//         ),
//       ),
//     );

//     if (added == true) {
//       await _loadRadios();

//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Radio ajoutée')));
//     }
//   }
  
//   // ============================================================
//   // OUVERTURE D'UNE RADIO
//   // ============================================================

//   void _openRadio(PodcastRadio radio) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) =>
//             PodcastRadioPage(repository: widget.repository, radio: radio),
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
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.error_outline, size: 48),
//               const SizedBox(height: 16),
//               Text('Erreur', style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 8),
//               Text(_error!, textAlign: TextAlign.center),
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: _loadRadios,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Réessayer'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_radios.isEmpty) {
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
//       child: ListView.builder(
//         padding: const EdgeInsets.only(top: 12, bottom: 24),
//         itemCount: _radios.length,
//         itemBuilder: (context, index) {
//           final radio = _radios[index];

//           return _RadioTile(radio: radio, onTap: () => _openRadio(radio));
//         },
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

//   const _RadioTile({required this.radio, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
//           child: Row(
//             children: [
//               Container(
//                 width: 54,
//                 height: 54,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(14),
//                   color: Theme.of(context).colorScheme.primaryContainer,
//                 ),
//                 child: Icon(
//                   Icons.radio,
//                   size: 30,
//                   color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       radio.name,
//                       style: Theme.of(context).textTheme.titleMedium
//                           ?.copyWith(fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       radio.searchTerm,
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                   ],
//                 ),
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
import 'models/podcast_radio.dart';
import 'repository/podcast_repository.dart';

import 'podcast_radio_page.dart';
import 'podcast_add_radio_page.dart';

class PodcastPage extends StatefulWidget {
  final PodcastRepository repository;
  

  const PodcastPage({
    super.key,
    required this.repository,
    
  });

  @override
  State<PodcastPage> createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  List<PodcastRadio> _radios = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRadios();
  }

  // ============================================================
  // CHARGEMENT DES RADIOS
  // ============================================================

  Future<void> _loadRadios() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      var radios = await widget.repository.getRadios();

      // ----------------------------------------------------------
      // France Inter est notre première radio par défaut.
      // ----------------------------------------------------------

      final franceInterExists = radios.any(
        (radio) => radio.name == 'France Inter',
      );

      if (!franceInterExists) {
        final id = await widget.repository.addRadio(
          const PodcastRadio(
            name: 'France Inter',
            searchTerm: 'France Inter',
          ),
        );

        if (id == 0) {
          throw Exception(
            'Impossible de créer la radio France Inter.',
          );
        }

        radios = await widget.repository.getRadios();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _radios = radios;
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

  // ============================================================
  // AJOUT D'UNE RADIO
  // ============================================================

  Future<void> _addRadio() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PodcastAddRadioPage(
          repository: widget.repository,
          
        ),
      ),
    );

    if (added == true) {
      await _loadRadios();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Radio ajoutée'),
        ),
      );
    }
  }

  // ============================================================
  // OUVERTURE D'UNE RADIO
  // ============================================================

  void _openRadio(PodcastRadio radio) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PodcastRadioPage(
          repository: widget.repository,
          radio: radio,
        ),
      ),
    );
  }

  // ============================================================
  // AFFICHAGE
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadRadios,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_radios.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: _addRadio,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une radio'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRadios,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 24,
        ),
        itemCount: _radios.length,
        itemBuilder: (context, index) {
          final radio = _radios[index];

          return _RadioTile(
            radio: radio,
            onTap: () => _openRadio(radio),
          );
        },
      ),
    );
  }
}

// =================================================================
// RADIO TILE
// =================================================================

class _RadioTile extends StatelessWidget {
  final PodcastRadio radio;
  final VoidCallback onTap;

  const _RadioTile({
    required this.radio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                ),
                child: Icon(
                  Icons.radio,
                  size: 30,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      radio.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      radio.searchTerm,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
