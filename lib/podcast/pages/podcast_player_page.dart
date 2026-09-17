import 'package:flutter/material.dart';

import '../models/podcast_episode.dart';
import '../player/podcast_player.dart';

class PodcastPlayerPage extends StatefulWidget {
  final PodcastPlayer player;

  const PodcastPlayerPage({super.key, required this.player});

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  Duration? _sliderPosition;

  PodcastPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    player.addListener(_playerChanged);
  }

  @override
  void dispose() {
    player.removeListener(_playerChanged);
    super.dispose();
  }

  void _playerChanged() {
    if (!mounted || _sliderPosition != null) {
      return;
    }

    setState(() {});
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderPosition = Duration(milliseconds: value.round());
    });
  }

  Future<void> _onSliderChangeEnd(double value) async {
    final position = Duration(milliseconds: value.round());

    setState(() {
      _sliderPosition = null;
    });

    await player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildArtwork(
    BuildContext context,
    PodcastEpisode episode,
    double size,
  ) {
    final imageUrl = episode.imageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Icon(Icons.podcasts, size: size * 0.3),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.podcasts, size: size * 0.3),
          );
        },
      ),
    );
  }

  Widget _buildSkipButton({
    required int seconds,
    required VoidCallback onPressed,
  }) {
    final isForward = seconds > 0;

    return IconButton(
      iconSize: 48,
      onPressed: onPressed,
      tooltip: isForward
          ? 'Avancer de $seconds secondes'
          : 'Reculer de ${seconds.abs()} secondes',
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(isForward ? Icons.forward_10 : Icons.replay_10, size: 44),
          Text(
            seconds.abs().toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episode = player.episode;

    if (episode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lecture'), centerTitle: true),
        body: const Center(child: Text('Aucun épisode en cours de lecture.')),
      );
    }

    final duration = player.duration ?? episode.duration ?? Duration.zero;

    final position = _sliderPosition ?? player.position;

    final maxMilliseconds = duration.inMilliseconds > 0
        ? duration.inMilliseconds
        : 1;

    final currentMilliseconds = position.inMilliseconds.clamp(
      0,
      maxMilliseconds,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Lecture'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageSize = (constraints.maxHeight * 0.38).clamp(
              180.0,
              360.0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildArtwork(context, episode, imageSize),

                    const SizedBox(height: 30),

                    Text(
                      episode.title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 28),

                    Slider(
                      min: 0,
                      max: maxMilliseconds.toDouble(),
                      value: currentMilliseconds.toDouble(),
                      onChanged: _onSliderChanged,
                      onChangeEnd: _onSliderChangeEnd,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkipButton(
                          seconds: -15,
                          onPressed: () {
                            player.skipBackward(const Duration(seconds: 15));
                          },
                        ),

                        const SizedBox(width: 28),

                        SizedBox(
                          width: 76,
                          height: 76,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: player.togglePlayPause,
                            child: Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 42,
                            ),
                          ),
                        ),

                        const SizedBox(width: 28),

                        _buildSkipButton(
                          seconds: 30,
                          onPressed: () {
                            player.skipForward(const Duration(seconds: 30));
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      player.isPlaying
                          ? 'Lecture en cours'
                          : 'Lecture en pause',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
