import 'package:flutter/material.dart';

import '../models/podcast_episode.dart';
import '../utils/podcast_formatters.dart';

class PodcastResumeCard extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const PodcastResumeCard({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final duration = episode.duration ?? Duration.zero;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ResumeImage(imageUrl: episode.imageUrl),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reprendre la lecture',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      episode.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      duration > Duration.zero
                          ? '${PodcastFormatters.duration(episode.position)}'
                                ' / '
                                '${PodcastFormatters.duration(duration)}'
                          : PodcastFormatters.duration(episode.position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.play_circle_fill,
                size: 40,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeImage extends StatelessWidget {
  final String? imageUrl;

  const _ResumeImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.podcasts, size: 40);
                },
              )
            : const Icon(Icons.podcasts, size: 40),
      ),
    );
  }
}
