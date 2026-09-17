import 'package:flutter/material.dart';

import '../models/podcast_episode.dart';
import '../utils/podcast_formatters.dart';

class PodcastEpisodeTile extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const PodcastEpisodeTile({
    super.key,
    required this.episode,
    required this.onTap,
  });

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
              _EpisodeImage(imageUrl: episode.imageUrl),

              const SizedBox(width: 12),

              Expanded(child: _EpisodeInformation(episode: episode)),

              const SizedBox(width: 4),

              Icon(
                episode.listened
                    ? Icons.check_circle
                    : Icons.play_circle_outline,
                color: episode.listened
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// IMAGE
// ============================================================

class _EpisodeImage extends StatelessWidget {
  final String? imageUrl;

  const _EpisodeImage({required this.imageUrl});

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

// ============================================================
// INFORMATIONS
// ============================================================

class _EpisodeInformation extends StatelessWidget {
  final PodcastEpisode episode;

  const _EpisodeInformation({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          episode.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: episode.listened ? FontWeight.normal : FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        if (episode.publishedAt != null)
          Text(
            PodcastFormatters.date(episode.publishedAt!),
            style: Theme.of(context).textTheme.bodySmall,
          ),

        if (episode.duration != null)
          Text(
            PodcastFormatters.durationShort(episode.duration!),
            style: Theme.of(context).textTheme.bodySmall,
          ),

        if (episode.position > Duration.zero)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Reprise à '
              '${PodcastFormatters.duration(episode.position)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}
