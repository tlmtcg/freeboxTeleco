// import 'dart:async';

// import 'package:flutter/material.dart';

// import '../freebox_os.dart';
// import '../hid/freebox_keys.dart';
// import '../hid/hid_client.dart';

// import 'models/tv_channel.dart';
// import 'services/tv_channels_service.dart';
// import 'services/tv_epg_service.dart';
// import 'widgets/channel_card.dart';
// import 'widgets/channel_filter_bar.dart';
// import 'pages/video_player_page.dart';
// import 'widgets/channel_details.dart';

// class ChannelsPage extends StatefulWidget {
//   final FreeboxOS freebox;
//   final HidClient player;

//   const ChannelsPage({super.key, required this.freebox, required this.player});

//   @override
//   State<ChannelsPage> createState() => _ChannelsPageState();
// }

// class _ChannelsPageState extends State<ChannelsPage> {
//   late final TvChannelsService _channelsService;
//   late final TvEpgService _epgService;

//   List<TvChannel> _channels = [];

//   ChannelFilter _filter = ChannelFilter.free;

//   bool _loading = true;
//   bool _loadingEpg = false;

//   String? _error;

//   Timer? _epgTimer;

//   @override
//   void initState() {
//     super.initState();

//     _channelsService = TvChannelsService(freebox: widget.freebox);

//     _epgService = TvEpgService(freebox: widget.freebox);

//     _loadChannels();

//     _epgTimer = Timer.periodic(
//       const Duration(minutes: 5),
//       (_) => _refreshEpg(),
//     );
//   }

//   @override
//   void dispose() {
//     _epgTimer?.cancel();
//     super.dispose();
//   }

//   // ---------------------------------------------------------------------------
//   // CHARGEMENT DES CHAÎNES
//   // ---------------------------------------------------------------------------

//   Future<void> _loadChannels() async {
//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       _loading = true;
//       _error = null;
//     });

//     try {
//       final channels = await _channelsService.loadChannels();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _channels = channels;
//         _loading = false;
//       });

//       await _loadEpg();
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

//   // ---------------------------------------------------------------------------
//   // EPG
//   // ---------------------------------------------------------------------------

//   Future<void> _loadEpg() async {
//     if (_channels.isEmpty) {
//       return;
//     }

//     if (mounted) {
//       setState(() {
//         _loadingEpg = true;
//       });
//     }

//     try {
//       await _epgService.loadEpg(_channels);
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loadingEpg = false;
//         });
//       }
//     }
//   }

//   Future<void> _refreshEpg() async {
//     if (_loading || _loadingEpg) {
//       return;
//     }

//     await _loadEpg();
//   }

//   // ---------------------------------------------------------------------------
//   // FILTRE
//   // ---------------------------------------------------------------------------

//   List<TvChannel> get _filteredChannels {
//     switch (_filter) {
//       case ChannelFilter.all:
//         return _channels;

//       case ChannelFilter.free:
//         return _channels.where((channel) => channel.isFree).toList();

//       case ChannelFilter.paid:
//         return _channels.where((channel) => channel.isPaid).toList();
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // SÉLECTION CHAÎNE
//   // ---------------------------------------------------------------------------

//   Future<void> _selectChannel(TvChannel channel) async {
//     if (!channel.isAvailable) {
//       _showMessage('La chaîne ${channel.number} n’est pas disponible.');
//       return;
//     }

//     final number = channel.number.toString();

//     if (number.isEmpty) {
//       return;
//     }

//     try {
//       for (final character in number.split('')) {
//         final digit = int.tryParse(character);

//         if (digit == null) {
//           continue;
//         }

//         final key = _keyForDigit(digit);

//         if (key == null) {
//           continue;
//         }

//         await sendFreeboxKey(key, widget.player);

//         await Future.delayed(const Duration(milliseconds: 80));
//       }

//       await sendFreeboxKey(FreeboxKey.ok, widget.player);

//       _showMessage('Chaîne ${channel.number} · ${channel.displayName}');
//     } catch (e) {
//       _showMessage('Erreur lors de la sélection de la chaîne');
//     }
//   }

//   FreeboxKey? _keyForDigit(int digit) {
//     switch (digit) {
//       case 0:
//         return FreeboxKey.key0;
//       case 1:
//         return FreeboxKey.key1;
//       case 2:
//         return FreeboxKey.key2;
//       case 3:
//         return FreeboxKey.key3;
//       case 4:
//         return FreeboxKey.key4;
//       case 5:
//         return FreeboxKey.key5;
//       case 6:
//         return FreeboxKey.key6;
//       case 7:
//         return FreeboxKey.key7;
//       case 8:
//         return FreeboxKey.key8;
//       case 9:
//         return FreeboxKey.key9;
//       default:
//         return null;
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // LECTURE
//   // ---------------------------------------------------------------------------

//   Future<void> _playChannel(TvChannel channel) async {
//     final name = channel.displayName;

//     final streams = channel.streams;

//     if (streams.isEmpty) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Aucun flux disponible pour $name.')),
//       );

//       return;
//     }

//     final rtsp = _selectStream(streams);

//     if (rtsp == null || rtsp.isEmpty) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Aucun flux RTSP disponible pour $name.')),
//       );

//       return;
//     }

//     debugPrint('========================================');
//     debugPrint('LECTURE RTSP');
//     debugPrint('CHAINE : $name');
//     debugPrint('RTSP   : $rtsp');
//     debugPrint('========================================');

//     if (!mounted) {
//       return;
//     }

//     await Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => VideoPlayerPage(channel: channel, streamUrl: rtsp),
//       ),
//     );
//   }

//   String? _selectStream(List<Map<String, dynamic>> streams) {
//     // ============================================================
//     // PRIORITÉ : HD
//     // ============================================================

//     for (final stream in streams) {
//       final quality = stream['quality']?.toString();

//       final rtsp = stream['rtsp']?.toString();

//       if (quality == 'hd' && rtsp != null && rtsp.isNotEmpty) {
//         return rtsp;
//       }
//     }

//     // ============================================================
//     // PRIORITÉ : AUTO
//     // ============================================================

//     for (final stream in streams) {
//       final quality = stream['quality']?.toString();

//       final rtsp = stream['rtsp']?.toString();

//       if (quality == 'auto' && rtsp != null && rtsp.isNotEmpty) {
//         return rtsp;
//       }
//     }

//     // ============================================================
//     // PRIORITÉ : SD
//     // ============================================================

//     for (final stream in streams) {
//       final quality = stream['quality']?.toString();

//       final rtsp = stream['rtsp']?.toString();

//       if (quality == 'sd' && rtsp != null && rtsp.isNotEmpty) {
//         return rtsp;
//       }
//     }

//     return null;
//   }

//   // ---------------------------------------------------------------------------
//   // DÉTAILS
//   // ---------------------------------------------------------------------------

//   Future<void> _showChannelDetails(TvChannel channel) async {
//     final program =
//         channel.epg ?? await _epgService.fetchCurrentProgram(channel);

//     if (!mounted) {
//       return;
//     }

//     showModalBottomSheet<void>(
//       context: context,
//       backgroundColor: const Color(0xFF111722),
//       isScrollControlled: true,
//       builder: (context) {
//         return ChannelDetails(
//           channel: channel,
//           program: channel.epg,
//           freeboxBaseUrl:  widget.freebox.host,
//           onPlay: () => _playChannel(channel),
//           onSelect: () => _selectChannel(channel),
//         );
//       },
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // UI
//   // ---------------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     final filteredChannels = _filteredChannels;

//     return Scaffold(
//       backgroundColor: const Color(0xFF080B12),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF080B12),
//         surfaceTintColor: Colors.transparent,
//         title: const Text('Télévision'),
//         actions: [
//           if (_loadingEpg)
//             const Padding(
//               padding: EdgeInsets.only(right: 12),
//               child: Center(
//                 child: SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 ),
//               ),
//             ),
//           IconButton(
//             tooltip: 'Actualiser',
//             onPressed: _loading ? null : _loadChannels,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: _buildBody(filteredChannels),
//     );
//   }

//   Widget _buildBody(List<TvChannel> channels) {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_error != null) {
//       return _buildError();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadChannels,
//       child: CustomScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         slivers: [
//           SliverToBoxAdapter(
//             child: ChannelFilterBar(
//               channels: _channels,
//               filter: _filter,
//               onFilterChanged: (filter) {
//                 setState(() {
//                   _filter = filter;
//                 });
//               },
//             ),
//           ),
//           if (channels.isEmpty)
//             SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
//           else
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
//               sliver: SliverList(
//                 delegate: SliverChildBuilderDelegate((context, index) {
//                   final channel = channels[index];

//                   return ChannelCard(
//                     channel: channel,
//                     onTap: () {
//                       _showChannelDetails(channel);
//                     },
//                     onLogoPress: () {
//                       _showChannelDetails(channel);
//                     },
//                     onSelect: () {
//                       _selectChannel(channel);
//                     },
//                   );
//                 }, childCount: channels.length),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildError() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
//             const SizedBox(height: 16),
//             const Text(
//               'Impossible de charger les chaînes',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _error ?? '',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white.withValues(alpha: 0.55),
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 20),
//             FilledButton.icon(
//               onPressed: _loadChannels,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Réessayer'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmpty() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.tv_off,
//             size: 48,
//             color: Colors.white.withValues(alpha: 0.35),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Aucune chaîne',
//             style: TextStyle(
//               color: Colors.white.withValues(alpha: 0.7),
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMessage(String message) {
//     if (!mounted) {
//       return;
//     }

//     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:freebox_teleco/tv/models/channel_filter.dart';

import '../../freebox_os.dart';
import '../../hid/hid_client.dart';

import '../models/tv_channel.dart';
import '../services/tv_channel_zapper.dart';
import '../services/tv_stream_selector.dart';
import '../controllers/channels_controller.dart';

import '../widgets/channel_card.dart';
import '../widgets/channel_filter_bar.dart';
import '../widgets/channel_details.dart';
import 'channel_search_page.dart';

import 'video_player_page.dart';

class ChannelsPage extends StatefulWidget {
  final FreeboxOS freebox;
  final HidClient player;

  const ChannelsPage({super.key, required this.freebox, required this.player});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  late final ChannelsController _controller;
  late final TvChannelZapper _zapper;
  late final TvStreamSelector _streamSelector;

  @override
  void initState() {
    super.initState();

    _controller = ChannelsController(freebox: widget.freebox);

    _zapper = TvChannelZapper(widget.player);

    _streamSelector = const TvStreamSelector();

    _loadChannels();

    _controller.startEpgTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CHARGEMENT
  // ---------------------------------------------------------------------------

  Future<void> _loadChannels() async {
    if (mounted) {
      setState(() {});
    }

    await _controller.loadChannels();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _refreshEpg() async {
    await _controller.refreshEpg();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // FILTRE
  // ---------------------------------------------------------------------------

  void _changeFilter(ChannelFilter filter) {
    setState(() {
      _controller.filter = filter;
    });
  }

  // ---------------------------------------------------------------------------
  // ZAPPING
  // ---------------------------------------------------------------------------

  Future<void> _selectChannel(TvChannel channel) async {
    if (!channel.isAvailable) {
      _showMessage('La chaîne ${channel.number} n’est pas disponible.');
      return;
    }

    try {
      await _zapper.selectChannel(channel.number);

      _showMessage('Chaîne ${channel.number} · ${channel.displayName}');
    } catch (e) {
      _showMessage('Erreur lors de la sélection de la chaîne');
    }
  }

  // ---------------------------------------------------------------------------
  // LECTURE
  // ---------------------------------------------------------------------------

  Future<void> _playChannel(TvChannel channel) async {
    final rtsp = _streamSelector.select(channel);

    if (rtsp == null || rtsp.isEmpty) {
      _showMessage('Aucun flux RTSP disponible pour ${channel.displayName}.');
      return;
    }

    debugPrint('========================================');
    debugPrint('LECTURE RTSP');
    debugPrint('CHAINE : ${channel.displayName}');
    debugPrint('RTSP   : $rtsp');
    debugPrint('========================================');

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(channel: channel, streamUrl: rtsp),
      ),
    );
  }

  Future<void> _openSearch() async {
    final channel = await Navigator.of(context).push<TvChannel>(
      MaterialPageRoute(
        builder: (_) => ChannelSearchPage(
          channels: _controller.channels,
          baseUrl: widget.freebox.host,
        ),
      ),
    );

    if (!mounted || channel == null) {
      return;
    }

    await _showChannelDetails(channel);
  }

  // ---------------------------------------------------------------------------
  // DÉTAILS
  // ---------------------------------------------------------------------------

  Future<void> _showChannelDetails(TvChannel channel) async {
    final program =
        channel.epg ?? await _controller.fetchCurrentProgram(channel);

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111722),
      isScrollControlled: true,
      builder: (context) {
        return ChannelDetails(
          channel: channel,
          program: program,
          freeboxBaseUrl: widget.freebox.host,
          onPlay: () => _playChannel(channel),
          onSelect: () => _selectChannel(channel),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final channels = _controller.filteredChannels;

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B12),
        surfaceTintColor: Colors.transparent,
        title: const Text('Télévision'),
        actions: [
          if (_controller.loadingEpg)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Rechercher une chaîne',
            onPressed: _controller.channels.isEmpty ? null : _openSearch,
            icon: const Icon(Icons.search),
          ),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: _controller.loading ? null : _loadChannels,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(channels),
    );
  }

  Widget _buildBody(List<TvChannel> channels) {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadChannels,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ChannelFilterBar(
              channels: _controller.channels,
              filter: _controller.filter,
              onFilterChanged: _changeFilter,
            ),
          ),

          if (channels.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final channel = channels[index];

                  return ChannelCard(
                    channel: channel,
                    onTap: () {
                      _showChannelDetails(channel);
                    },
                    onLogoPress: () {
                      _showChannelDetails(channel);
                    },
                    onSelect: () {
                      _selectChannel(channel);
                    },
                  );
                }, childCount: channels.length),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERREUR
  // ---------------------------------------------------------------------------

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les chaînes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
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

  // ---------------------------------------------------------------------------
  // AUCUNE CHAÎNE
  // ---------------------------------------------------------------------------

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_off,
            size: 48,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune chaîne',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
