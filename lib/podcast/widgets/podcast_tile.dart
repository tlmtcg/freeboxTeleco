import 'package:flutter/material.dart';

import '../models/podcast.dart';

class PodcastTile extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const PodcastTile({super.key, required this.podcast, required this.onTap});

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

              Expanded(child: _PodcastInformation(podcast: podcast)),

              const SizedBox(width: 4),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodcastImage extends StatelessWidget {
  final String? imageUrl;

  const _PodcastImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
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
}

class _PodcastInformation extends StatelessWidget {
  final Podcast podcast;

  const _PodcastInformation({required this.podcast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          podcast.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),

        if (podcast.description != null &&
            podcast.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            podcast.description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],

        if (podcast.categories.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            podcast.categories.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }
}
