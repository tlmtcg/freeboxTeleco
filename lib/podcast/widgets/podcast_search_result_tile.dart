import 'package:flutter/material.dart';

import '../models/podcast.dart';

class PodcastSearchResultTile extends StatelessWidget {
  final Podcast podcast;
  final bool selected;
  final VoidCallback onTap;

  const PodcastSearchResultTile({
    super.key,
    required this.podcast,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Artwork(podcast: podcast),

              const SizedBox(width: 12),

              Expanded(child: _PodcastInformation(podcast: podcast)),

              const SizedBox(width: 8),

              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INFORMATIONS
// =============================================================================

class _PodcastInformation extends StatelessWidget {
  final Podcast podcast;

  const _PodcastInformation({required this.podcast});

  @override
  Widget build(BuildContext context) {
    final description = podcast.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          podcast.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 6),

          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        if (podcast.podcastIndexId != null) ...[
          const SizedBox(height: 6),

          Text(
            'Podcast Index : ${podcast.podcastIndexId}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// IMAGE
// =============================================================================

class _Artwork extends StatelessWidget {
  static const double size = 72;

  final Podcast podcast;

  const _Artwork({required this.podcast});

  @override
  Widget build(BuildContext context) {
    final imageUrl = podcast.imageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _Placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const _Placeholder();
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Artwork.size,
      height: _Artwork.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Icon(Icons.radio, size: 36),
    );
  }
}
