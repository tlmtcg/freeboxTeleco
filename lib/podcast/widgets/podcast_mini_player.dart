import 'package:flutter/material.dart';

import '../models/podcast_episode.dart';
import '../player/podcast_player.dart';
import '../utils/podcast_formatters.dart';

class PodcastMiniPlayer extends StatelessWidget {
  final PodcastPlayer player;
  final VoidCallback onTap;

  const PodcastMiniPlayer({
    super.key,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: player,
      builder: (context, child) {
        final episode = player.episode;

        if (episode == null) {
          return const SizedBox.shrink();
        }

        return _MiniPlayerContent(
          player: player,
          episode: episode,
          onTap: onTap,
        );
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final PodcastPlayer player;
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const _MiniPlayerContent({
    required this.player,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = player.duration ?? Duration.zero;

    final position = player.position;

    final maxSeconds = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;

    final currentSeconds = position.inMilliseconds
        .clamp(
          0,
          duration.inMilliseconds > 0
              ? duration.inMilliseconds
              : position.inMilliseconds,
        )
        .toDouble();

    return Material(
      elevation: 12,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _MiniPlayerImage(imageUrl: episode.imageUrl),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        episode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: player.togglePlayPause,
                    ),
                  ],
                ),

                Slider(
                  value: currentSeconds,
                  max: maxSeconds,
                  onChanged: (value) {
                    player.seek(Duration(milliseconds: value.round()));
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(PodcastFormatters.duration(position)),
                    Text(PodcastFormatters.duration(duration)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerImage extends StatelessWidget {
  final String? imageUrl;

  const _MiniPlayerImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox(width: 48, height: 48, child: Icon(Icons.podcasts));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.podcasts),
          );
        },
      ),
    );
  }
}
