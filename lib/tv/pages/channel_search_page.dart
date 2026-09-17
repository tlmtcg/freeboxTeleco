import 'package:flutter/material.dart';

import '../models/tv_channel.dart';

class ChannelSearchPage extends StatefulWidget {
  final List<TvChannel> channels;
  final String baseUrl;

  const ChannelSearchPage({
    super.key,
    required this.channels,
    required this.baseUrl,
  });

  @override
  State<ChannelSearchPage> createState() => _ChannelSearchPageState();
}

class _ChannelSearchPageState extends State<ChannelSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<TvChannel> _results = [];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    _results = widget.channels;

    _searchController.addListener(_search);
  }

  @override
  void dispose() {
    _searchController.removeListener(_search);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> get _categories {
    final categories = <String>{};

    for (final channel in widget.channels) {
      final value = channel.epg?['category_name'];

      if (value == null) {
        continue;
      }

      final category = value.toString().trim();

      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    final result = categories.toList();

    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return result;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _search() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _results = widget.channels.where((channel) {
        // --------------------------------------------------------
        // Filtre texte
        // --------------------------------------------------------

        if (query.isNotEmpty) {
          final number = channel.number.toString().toLowerCase();
          final name = channel.displayName.toLowerCase();

          final matchesQuery = number.contains(query) || name.contains(query);

          if (!matchesQuery) {
            return false;
          }
        }

        // --------------------------------------------------------
        // Filtre catégorie
        // --------------------------------------------------------

        if (_selectedCategory != null) {
          final value = channel.epg?['category_name'];

          if (value == null) {
            return false;
          }

          final category = value.toString().trim();

          if (category != _selectedCategory) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });

    _search();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final categories = _categories;

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),

      appBar: AppBar(
        backgroundColor: const Color(0xFF080B12),
        surfaceTintColor: Colors.transparent,
        title: const Text('Rechercher une chaîne'),
      ),

      body: Column(
        children: [
          // ------------------------------------------------------
          // RECHERCHE
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom ou numéro de chaîne',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                prefixIcon: const Icon(Icons.search),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Effacer',
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,

                filled: true,
                fillColor: const Color(0xFF111722),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // CATEGORIES
          // ------------------------------------------------------
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                children: [
                  _buildCategoryChip(
                    label: 'Toutes',
                    selected: _selectedCategory == null,
                    onSelected: () {
                      _selectCategory(null);
                    },
                  ),

                  for (final category in categories)
                    _buildCategoryChip(
                      label: category,
                      selected: _selectedCategory == category,
                      onSelected: () {
                        _selectCategory(category);
                      },
                    ),
                ],
              ),
            ),

          // ------------------------------------------------------
          // RESULTATS
          // ------------------------------------------------------
          Expanded(
            child: _results.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final channel = _results[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),

                        leading: SizedBox(
                          width: 90,
                          height: 70,
                          child: _buildProgramImage(channel),
                        ),

                        title: Text(
                          channel.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        subtitle: _buildSubtitle(channel),

                        onTap: () {
                          Navigator.of(context).pop(channel);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramImage(TvChannel channel) {
    final epg = channel.epg;

    final pictureBig = epg?['picture_big']?.toString();
    final picture = epg?['picture']?.toString();

    final picturePath = pictureBig != null && pictureBig.isNotEmpty
        ? pictureBig
        : picture != null && picture.isNotEmpty
        ? picture
        : null;

    if (picturePath == null) {
      debugPrint('IMAGE EPG : aucune image pour ${channel.displayName}');
      debugPrint('EPG : ${channel.epg}');

      return _buildImagePlaceholder();
    }

    final imageUrl = _buildImageUrl(picturePath);

    // ============================================================
    // DEBUG IMAGE
    // ============================================================

    debugPrint('========================================');
    debugPrint('IMAGE EPG');
    debugPrint('CHAINE   : ${channel.displayName}');
    debugPrint('BASE URL : ${widget.baseUrl}');
    debugPrint('PATH     : $picturePath');
    debugPrint('URL      : $imageUrl');
    debugPrint('========================================');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 90,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('========================================');
          debugPrint('ERREUR IMAGE EPG');
          debugPrint('URL   : $imageUrl');
          debugPrint('ERROR : $error');
          debugPrint('========================================');

          return _buildImagePlaceholder();
        },
      ),
    );
  }

  String _buildImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    var base = widget.baseUrl.trim();

    if (!base.startsWith('http://') && !base.startsWith('https://')) {
      base = 'http://$base';
    }

    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    final imagePath = path.startsWith('/') ? path : '/$path';

    return '$base$imagePath';
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1A202C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.movie, color: Colors.white54),
    );
  }

  // ============================================================
  // CATEGORY CHIP
  // ============================================================

  Widget _buildCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          onSelected();
        },
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.75),
        ),
        backgroundColor: const Color(0xFF111722),
        selectedColor: const Color(0xFF315EA8),
        checkmarkColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  Widget _buildSubtitle(TvChannel channel) {
    final epg = channel.epg;

    final category = epg?['category_name']?.toString().trim();
    final title = epg?['title']?.toString().trim();

    final dateValue = epg?['date'];
    final durationValue = epg?['duration'];

    DateTime? start;
    DateTime? end;

    if (dateValue != null && durationValue != null) {
      final startTimestamp = int.tryParse(dateValue.toString());

      final duration = int.tryParse(durationValue.toString());

      if (startTimestamp != null && duration != null) {
        start = DateTime.fromMillisecondsSinceEpoch(startTimestamp * 1000);

        end = start.add(Duration(seconds: duration));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Canal + catégorie
        Text(
          [
            'Canal ${channel.number}',
            if (category != null && category.isNotEmpty) category,
          ].join(' · '),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 2),

        // Programme
        if (title != null && title.isNotEmpty)
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),

        // Horaires
        if (start != null && end != null)
          Text(
            '${_formatTime(start)} → ${_formatTime(end)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),

        // Temps écoulé
        if (start != null)
          Text(
            _formatElapsed(start),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatElapsed(DateTime start) {
    final now = DateTime.now();

    final elapsed = now.difference(start);

    if (elapsed.isNegative) {
      return 'Commence dans ${_formatDuration(elapsed.abs())}';
    }

    if (elapsed.inMinutes < 1) {
      return 'Débuté à l’instant';
    }

    return 'Débuté depuis ${_formatDuration(elapsed)}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      if (minutes == 0) {
        return '$hours h';
      }

      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    }

    return '${minutes} minute${minutes > 1 ? 's' : ''}';
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.white.withValues(alpha: 0.35),
          ),

          const SizedBox(height: 12),

          Text(
            _selectedCategory != null
                ? 'Aucune chaîne dans cette catégorie'
                : 'Aucune chaîne trouvée',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
