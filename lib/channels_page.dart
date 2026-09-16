
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'freebox_os.dart';
import 'hid/hid_client.dart';
import 'hid/freebox_keys.dart';

class ChannelsPage extends StatefulWidget {
  final FreeboxOS freebox;
  final HidClient player;

  const ChannelsPage({
    super.key,
    required this.freebox,
    required this.player,
  });

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

enum _ChannelFilter { all, available, paid }

class _ChannelsPageState extends State<ChannelsPage> {
  final List<Map<String, dynamic>> _channels = [];

  bool _loading = true;
  String? _error;

  _ChannelFilter _filter = _ChannelFilter.available;

  Timer? _epgTimer;

  @override
  void initState() {
    super.initState();

    _loadChannels();

    _epgTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadEpg(),
    );
  }

  @override
  void dispose() {
    _epgTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHANNELS
  // ============================================================

  bool _isFrance3Regional(Map<String, dynamic> channel) {
    final name = channel['name']?.toString().trim() ?? '';
    final shortName = channel['short_name']?.toString().trim() ?? '';

    return (name.startsWith('France 3 ') && name != 'France 3') ||
        (shortName.startsWith('France 3 ') && shortName != 'France 3');
  }

  Future<void> _loadChannels() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bouquetsResponse = await widget.freebox.get(
        '/api/v8/tv/bouquets/',
      );

      if (bouquetsResponse is! Map ||
          bouquetsResponse['success'] != true) {
        throw Exception('Impossible de récupérer les bouquets TV');
      }

      final List<dynamic> bouquets =
          bouquetsResponse['result'] as List<dynamic>? ?? [];

      Map<String, dynamic>? freeboxTvBouquet;

      for (final bouquet in bouquets) {
        if (bouquet is Map && bouquet['id'] == 57) {
          freeboxTvBouquet = Map<String, dynamic>.from(bouquet);
          break;
        }
      }

      if (freeboxTvBouquet == null) {
        throw Exception('Bouquet Freebox TV introuvable');
      }

      final int bouquetId =
          (freeboxTvBouquet['id'] as num?)?.toInt() ?? 57;

      final bouquetChannelsResponse = await widget.freebox.get(
        '/api/v8/tv/bouquets/$bouquetId/channels',
      );

      if (bouquetChannelsResponse is! Map ||
          bouquetChannelsResponse['success'] != true) {
        throw Exception(
          'Impossible de récupérer les chaînes du bouquet',
        );
      }

      final dynamic bouquetResult =
          bouquetChannelsResponse['result'];

      final List<dynamic> bouquetChannels =
          bouquetResult is List
              ? bouquetResult
              : bouquetResult is Map
                  ? bouquetResult.values.toList()
                  : [];

      final channelsResponse = await widget.freebox.get(
        '/api/v8/tv/channels/',
      );

      if (channelsResponse is! Map ||
          channelsResponse['success'] != true) {
        throw Exception(
          'Impossible de récupérer les informations des chaînes',
        );
      }

      final dynamic channelResult =
          channelsResponse['result'];

      final Map<String, dynamic> channelMetadata = {};

      if (channelResult is Map) {
        channelResult.forEach((key, value) {
          if (value is Map) {
            final channel = Map<String, dynamic>.from(value);

            final uuid =
                channel['uuid']?.toString() ?? key.toString();

            channelMetadata[uuid] = channel;
          }
        });
      }

      final merged = <Map<String, dynamic>>[];

      for (final item in bouquetChannels) {
        if (item is! Map) {
          continue;
        }

        final bouquetChannel =
            Map<String, dynamic>.from(item);

        final uuid =
            bouquetChannel['uuid']?.toString();

        if (uuid == null || uuid.isEmpty) {
          continue;
        }

        final metadata =
            channelMetadata[uuid] ?? <String, dynamic>{};

        final mergedChannel = <String, dynamic>{
          ...metadata,
          ...bouquetChannel,
          'uuid': uuid,
        };

        if (_isFrance3Regional(mergedChannel)) {
          continue;
        }

        merged.add(mergedChannel);
      }

      merged.sort((a, b) {
        final aNumber =
            (a['number'] as num?)?.toInt() ?? 99999;

        final bNumber =
            (b['number'] as num?)?.toInt() ?? 99999;

        return aNumber.compareTo(bNumber);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _channels
          ..clear()
          ..addAll(merged);

        _loading = false;
      });

      await _loadEpg();
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
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredChannels {
    switch (_filter) {
      case _ChannelFilter.all:
        return _channels;

      case _ChannelFilter.available:
        return _channels.where(_isAvailable).toList();

      case _ChannelFilter.paid:
        return _channels.where(_isPaid).toList();
    }
  }

  bool _isPaid(Map<String, dynamic> channel) {
    return channel['has_abo'] == true;
  }

  bool _isAvailable(Map<String, dynamic> channel) {
    return channel['available'] == true;
  }

  // ============================================================
  // EPG
  // ============================================================

  Future<void> _loadEpg() async {
    if (_channels.isEmpty) {
      return;
    }

    final now =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const batchSize = 12;

    for (int i = 0; i < _channels.length; i += batchSize) {
      final end =
          (i + batchSize < _channels.length)
              ? i + batchSize
              : _channels.length;

      final batch = _channels.sublist(i, end);

      await Future.wait(
        batch.map(
          (channel) => _loadChannelEpg(channel, now),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {});
    }
  }

  Future<void> _loadChannelEpg(
    Map<String, dynamic> channel,
    int now,
  ) async {
    final uuid = channel['uuid']?.toString();

    if (uuid == null || uuid.isEmpty) {
      return;
    }

    try {
      final response = await widget.freebox.get(
        '/api/v8/tv/epg/by_channel/$uuid/$now',
      );

      if (response is! Map ||
          response['success'] != true) {
        return;
      }

      final result = response['result'];

      if (result is! Map) {
        return;
      }

      Map<String, dynamic>? currentProgram;

      for (final entry in result.entries) {
        final value = entry.value;

        if (value is! Map) {
          continue;
        }

        final program =
            Map<String, dynamic>.from(value);

        final date = program['date'];
        final duration = program['duration'];

        if (date is! num || duration is! num) {
          continue;
        }

        final start = date.toInt();
        final end = start + duration.toInt();

        if (now >= start && now < end) {
          currentProgram = program;
          break;
        }
      }

      if (currentProgram != null) {
        channel['epg'] = currentProgram;
      } else {
        channel.remove('epg');
      }
    } catch (_) {
      // L'EPG est optionnel.
    }
  }

  // ============================================================
  // RTSP PLAYBACK
  // ============================================================

  Future<void> _playChannel(
    Map<String, dynamic> channel,
  ) async {
    final name =
        channel['name']?.toString() ?? 'Chaîne';

    final streams = channel['streams'];

    if (streams is! List || streams.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun flux disponible pour $name.',
          ),
        ),
      );

      return;
    }

    Map<String, dynamic>? selectedStream;

    /*
     * Priorité :
     *
     * 1. HD
     * 2. auto
     * 3. SD
     */

    for (final item in streams) {
      if (item is! Map) {
        continue;
      }

      final stream =
          Map<String, dynamic>.from(item);

      final quality =
          stream['quality']?.toString();

      final rtsp =
          stream['rtsp']?.toString();

      if (quality == 'hd' &&
          rtsp != null &&
          rtsp.isNotEmpty) {
        selectedStream = stream;
        break;
      }
    }

    selectedStream ??= streams
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (stream) {
            final rtsp =
                stream['rtsp']?.toString();

            return stream['quality']?.toString() ==
                    'auto' &&
                rtsp != null &&
                rtsp.isNotEmpty;
          },
          orElse: () => <String, dynamic>{},
        );

    selectedStream ??= streams
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (stream) {
            final rtsp =
                stream['rtsp']?.toString();

            return stream['quality']?.toString() ==
                    'sd' &&
                rtsp != null &&
                rtsp.isNotEmpty;
          },
          orElse: () => <String, dynamic>{},
        );

    if (selectedStream == null ||
        selectedStream.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun flux RTSP disponible pour $name.',
          ),
        ),
      );

      return;
    }

    final rtsp =
        selectedStream['rtsp']?.toString();

    if (rtsp == null || rtsp.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun flux RTSP disponible pour $name.',
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(
          channel: channel,
          streamUrl: rtsp,
        ),
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showChannelDetails(
    Map<String, dynamic> channel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111722),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _ChannelDetails(
          channel: channel,
        );
      },
    );
  }

  // ============================================================
  // SELECT CHANNEL
  // ============================================================

  Future<void> _selectChannel(
    Map<String, dynamic> channel,
  ) async {
    final number =
        (channel['number'] as num?)?.toInt() ?? 0;

    final name =
        channel['name']?.toString() ??
        channel['short_name']?.toString() ??
        'Chaîne $number';

    if (!_isAvailable(channel)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name n’est pas disponible avec votre abonnement.',
          ),
        ),
      );

      return;
    }

    if (number <= 0) {
      return;
    }

    try {
      final digits = number.toString();

      for (final digit in digits.split('')) {
        final key = switch (digit) {
          '0' => FreeboxKey.key0,
          '1' => FreeboxKey.key1,
          '2' => FreeboxKey.key2,
          '3' => FreeboxKey.key3,
          '4' => FreeboxKey.key4,
          '5' => FreeboxKey.key5,
          '6' => FreeboxKey.key6,
          '7' => FreeboxKey.key7,
          '8' => FreeboxKey.key8,
          '9' => FreeboxKey.key9,
          _ => null,
        };

        if (key != null) {
          await sendFreeboxKey(
            key,
            widget.player,
          );

          await Future.delayed(
            const Duration(milliseconds: 80),
          );
        }
      }

      await sendFreeboxKey(
        FreeboxKey.ok,
        widget.player,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chaîne $number · $name',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de sélectionner la chaîne : $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final channels = _filteredChannels;

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        title: const Text('Chaînes TV'),
        backgroundColor: const Color(0xFF080B12),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading
                ? null
                : _loadChannels,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildChannelContent(channels),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Toutes',
              icon: Icons.tv,
              filter: _ChannelFilter.all,
              count: _channels.length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Disponibles',
              icon: Icons.check_circle_outline,
              filter: _ChannelFilter.available,
              count: _channels
                  .where(_isAvailable)
                  .length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Payantes',
              icon: Icons.lock_outline,
              filter: _ChannelFilter.paid,
              count: _channels
                  .where(_isPaid)
                  .length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required _ChannelFilter filter,
    required int count,
  }) {
    final selected = _filter == filter;

    return FilterChip(
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = filter;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
      ),
      label: Text('$label ($count)'),
    );
  }

  // ============================================================
  // CHANNEL CONTENT
  // ============================================================

  Widget _buildChannelContent(
    List<Map<String, dynamic>> channels,
  ) {
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
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadChannels,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tv_off,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _filter == _ChannelFilter.paid
                  ? 'Aucune chaîne payante'
                  : _filter ==
                          _ChannelFilter.available
                      ? 'Aucune chaîne disponible'
                      : 'Aucune chaîne',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChannels,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          4,
          12,
          24,
        ),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];

          return _ChannelCard(
            channel: channel,
            onTap: () => _showChannelDetails(channel),
            onLogoPress: () => _playChannel(channel),
            onSelect: () => _selectChannel(channel),
          );
        },
      ),
    );
  }
}

// ============================================================================
// CHANNEL CARD
// ============================================================================

class _ChannelCard extends StatelessWidget {
  final Map<String, dynamic> channel;
  final VoidCallback onTap;
  final VoidCallback onLogoPress;
  final VoidCallback onSelect;

  const _ChannelCard({
    required this.channel,
    required this.onTap,
    required this.onLogoPress,
    required this.onSelect,
  });

  bool get isPaid {
    return channel['has_abo'] == true;
  }

  bool get isAvailable {
    return channel['available'] == true;
  }

  String get channelName {
    return channel['name']?.toString() ??
        channel['short_name']?.toString() ??
        'Chaîne';
  }

  int get channelNumber {
    return (channel['number'] as num?)?.toInt() ?? 0;
  }

  Map<String, dynamic>? get epg {
    final value = channel['epg'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final program = epg;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF111722),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onSelect,
                onLongPress: onLogoPress,
                child: _ChannelLogo(
                  channel: channel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(8),
                            color: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                          ),
                          child: Text(
                            '$channelNumber',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            channelName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        if (isPaid)
                          _ChannelBadge(
                            icon:
                                Icons.lock_outline,
                            label: isAvailable
                                ? 'PAYANTE'
                                : '🔒 PAYANTE',
                            highlighted:
                                !isAvailable,
                          ),
                        if (isPaid &&
                            !isAvailable)
                          const SizedBox(width: 6),
                        if (!isPaid &&
                            isAvailable)
                          const _ChannelBadge(
                            icon: Icons
                                .check_circle_outline,
                            label: 'DISPONIBLE',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (program != null)
                      _ProgramInfo(
                        program: program,
                      )
                    else
                      Text(
                        'Programme en cours indisponible',
                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.45,
                          ),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isAvailable
                    ? Icons.play_circle_outline
                    : Icons.lock_outline,
                color: isAvailable
                    ? Colors.white70
                    : Colors.orangeAccent,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CHANNEL BADGE
// ============================================================================

class _ChannelBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _ChannelBadge({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: highlighted
            ? Colors.orange.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: highlighted
              ? Colors.orange.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGO
// ============================================================================

class _ChannelLogo extends StatelessWidget {
  final Map<String, dynamic> channel;

  const _ChannelLogo({
    required this.channel,
  });

  String? get logoUrl {
    final logoPath =
        channel['logo_url']?.toString();

    if (logoPath == null || logoPath.isEmpty) {
      return null;
    }

    if (logoPath.startsWith('http://') ||
        logoPath.startsWith('https://')) {
      return logoPath;
    }

    return 'http://mafreebox.freebox.fr$logoPath';
  }

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;

    return Container(
      width: 68,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(
              Icons.tv,
              color: Colors.white54,
              size: 30,
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) {
                return const Icon(
                  Icons.tv,
                  color: Colors.white54,
                  size: 30,
                );
              },
              loadingBuilder:
                  (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// PROGRAM INFO
// ============================================================================

class _ProgramInfo extends StatelessWidget {
  final Map<String, dynamic> program;

  const _ProgramInfo({
    required this.program,
  });

  String _readTitle() {
    return program['title']?.toString() ??
        'Programme indisponible';
  }

  String? _readDescription() {
    final value = program['desc'];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  int? _readDate() {
    final value = program['date'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  int? _readDuration() {
    final value = program['duration'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  String _formatTime(int timestamp) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
    );

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final title = _readTitle();
    final description = _readDescription();

    final start = _readDate();
    final duration = _readDuration();

    int? end;

    if (start != null && duration != null) {
      end = start + duration;
    }

    double progress = 0;

    if (start != null &&
        end != null &&
        end > start) {
      final now =
          DateTime.now().millisecondsSinceEpoch ~/
              1000;

      progress =
          ((now - start) / (end - start))
              .clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.55,
              ),
              fontSize: 12,
            ),
          ),
        ],
        if (start != null && end != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '${_formatTime(start)} → ${_formatTime(end)}',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// CHANNEL DETAILS
// ============================================================================

class _ChannelDetails extends StatelessWidget {
  final Map<String, dynamic> channel;

  const _ChannelDetails({
    required this.channel,
  });

  Map<String, dynamic>? get epg {
    final value = channel['epg'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String _value(dynamic value) {
    if (value == null) {
      return '—';
    }

    if (value is bool) {
      return value ? 'true' : 'false';
    }

    return value.toString();
  }

  String _formatTimestamp(dynamic value) {
    if (value is! num) {
      return _value(value);
    }

    final date =
        DateTime.fromMillisecondsSinceEpoch(
      value.toInt() * 1000,
    );

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    final second =
        date.second.toString().padLeft(2, '0');

    return '$day/$month/$year '
        '$hour:$minute:$second';
  }

  Widget _jsonRow(
    String key,
    dynamic value,
  ) {
    String displayValue;

    if (key == 'date') {
      displayValue =
          _formatTimestamp(value);
    } else if (value is List) {
      displayValue = value.join(', ');
    } else if (value is Map) {
      displayValue = value.toString();
    } else {
      displayValue = _value(value);
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              displayValue,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = epg;

    final logoPath =
        channel['logo_url']?.toString();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChannelLogo(
                  channel: channel,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel['name']
                                ?.toString() ??
                            'Chaîne',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Canal ${channel['number'] ?? '—'}',
                        style:
                            const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _sectionTitle(
              'Informations chaîne',
            ),
            ...channel.entries
                .where(
                  (entry) =>
                      entry.key != 'epg',
                )
                .map(
                  (entry) => _jsonRow(
                    entry.key,
                    entry.value,
                  ),
                ),
            if (program != null) ...[
              _sectionTitle(
                'Programme actuel',
              ),
              ...program.entries.map(
                (entry) => _jsonRow(
                  entry.key,
                  entry.value,
                ),
              ),
            ],
            if (logoPath != null &&
                logoPath.isNotEmpty) ...[
              _sectionTitle('Logo'),
              SelectableText(
                logoPath,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VIDEO PLAYER
// ============================================================================

class _VideoPlayerPage extends StatefulWidget {
  final Map<String, dynamic> channel;
  final String streamUrl;

  const _VideoPlayerPage({
    required this.channel,
    required this.streamUrl,
  });

  @override
  State<_VideoPlayerPage> createState() =>
      _VideoPlayerPageState();
}

class _VideoPlayerPageState
    extends State<_VideoPlayerPage> {
  late final Player _player;
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();

    _player = Player(
      configuration: const PlayerConfiguration(
        protocolWhitelist: [
          'rtsp',
          'rtp',
          'udp',
          'tcp',
          'file',
          'http',
          'https',
        ],
        logLevel: MPVLogLevel.debug,
      ),
    );

    _videoController =
        VideoController(_player);

    _player.stream.log.listen((log) {
      // Debug éventuel.
    });

    _player.stream.error.listen((error) {
      // Debug éventuel.
    });

    _player.stream.playing.listen((playing) {
      // Debug éventuel.
    });

    _player.stream.buffering.listen((buffering) {
      // Debug éventuel.
    });

    _player.stream.buffer.listen((buffer) {
      // Debug éventuel.
    });

    _player.stream.videoParams.listen((params) {
      // Debug éventuel.
    });

    _player.stream.audioParams.listen((params) {
      // Debug éventuel.
    });

    _player.stream.tracks.listen((tracks) {
      // Debug éventuel.
    });

    _player.stream.position.listen((position) {
      // Debug éventuel.
    });

    _openStream();
  }

  Future<void> _openStream() async {
    try {
      if (_player.platform is NativePlayer) {
        await (_player.platform as dynamic).setProperty(
          'rtsp-transport',
          'udp',
        );
      }

      await _player.open(
        Media(widget.streamUrl),
      );

      if (!mounted) {
        return;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lecture : $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelName =
        widget.channel['name']?.toString() ??
            'Télévision';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(channelName),
      ),
      body: Center(
        child: Video(
          controller: _videoController,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
