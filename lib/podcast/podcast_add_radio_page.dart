import 'package:flutter/material.dart';

import 'models/podcast_radio.dart';
import 'repository/podcast_repository.dart';

class PodcastAddRadioPage extends StatefulWidget {
  final PodcastRepository repository;

  const PodcastAddRadioPage({super.key, required this.repository});

  @override
  State<PodcastAddRadioPage> createState() => _PodcastAddRadioPageState();
}

class _PodcastAddRadioPageState extends State<PodcastAddRadioPage> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  bool _saving = false;

  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // AJOUT
  // ============================================================

  Future<void> _addRadio() async {
    final name = _nameController.text.trim();
    final searchTerm = _searchController.text.trim();

    // ----------------------------------------------------------
    // Validation
    // ----------------------------------------------------------

    if (name.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir le nom de la radio.';
      });
      return;
    }

    if (searchTerm.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir le terme de recherche Podcast Index.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // --------------------------------------------------------
      // Vérification d'une éventuelle radio existante
      // --------------------------------------------------------

      final radios = await widget.repository.getRadios();

      final alreadyExists = radios.any(
        (radio) => radio.name.toLowerCase() == name.toLowerCase(),
      );

      if (alreadyExists) {
        throw Exception('Cette radio existe déjà.');
      }

      // --------------------------------------------------------
      // Création
      // --------------------------------------------------------

      final id = await widget.repository.addRadio(
        PodcastRadio(name: name, searchTerm: searchTerm),
      );

      if (id == 0) {
        throw Exception('Impossible d\'ajouter la radio.');
      }

      if (!mounted) {
        return;
      }

      // Retour vers la page des radios.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
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
      appBar: AppBar(title: const Text('Ajouter une radio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ----------------------------------------------------
            // ICÔNE
            // ----------------------------------------------------

            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.radio,
                  size: 42,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------
            // NOM
            // ----------------------------------------------------
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nom de la radio',
                hintText: 'Classic Musique',
                prefixIcon: const Icon(Icons.radio),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // RECHERCHE PODCAST INDEX
            // ----------------------------------------------------
            TextField(
              controller: _searchController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Recherche Podcast Index',
                hintText: 'Classic Musique',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Ce terme sera utilisé pour rechercher '
              'les podcasts associés à cette radio.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // ----------------------------------------------------
            // ERREUR
            // ----------------------------------------------------
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ----------------------------------------------------
            // BOUTON AJOUTER
            // ----------------------------------------------------
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addRadio,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_saving ? 'Ajout en cours...' : 'Ajouter la radio'),
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // ANNULER
            // ----------------------------------------------------
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.of(context).pop(false);
                      },
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

