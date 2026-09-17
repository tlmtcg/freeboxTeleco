import 'dart:async';

import '../../freebox_os.dart';
import '../models/channel_filter.dart';
import '../models/tv_channel.dart';
import '../services/tv_channels_service.dart';
import '../services/tv_epg_service.dart';

class ChannelsController {
  final TvChannelsService channelsService;
  final TvEpgService epgService;

  ChannelsController({
    required FreeboxOS freebox,
  }) : channelsService = TvChannelsService(
         freebox: freebox,
       ),
       epgService = TvEpgService(
         freebox: freebox,
       );

  // ---------------------------------------------------------------------------
  // ÉTAT
  // ---------------------------------------------------------------------------

  List<TvChannel> channels = [];

  ChannelFilter filter = ChannelFilter.free;

  bool loading = false;
  bool loadingEpg = false;

  String? error;

  Timer? _epgTimer;

  // ---------------------------------------------------------------------------
  // CHAÎNES FILTRÉES
  // ---------------------------------------------------------------------------

  List<TvChannel> get filteredChannels {
    switch (filter) {
      case ChannelFilter.all:
        return channels;

      case ChannelFilter.free:
        return channels
            .where((channel) => channel.isFree)
            .toList();

      case ChannelFilter.paid:
        return channels
            .where((channel) => channel.isPaid)
            .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // CHARGEMENT DES CHAÎNES
  // ---------------------------------------------------------------------------

  Future<void> loadChannels() async {
    loading = true;
    error = null;

    try {
      final loadedChannels =
          await channelsService.loadChannels();

      channels = loadedChannels;

      // IMPORTANT :
      // Les chaînes sont maintenant disponibles.
      //
      // On arrête le chargement principal AVANT l'EPG
      // afin que la page s'affiche immédiatement.
      loading = false;

      // EPG en arrière-plan.
      unawaited(loadEpg());

      // L'EPG est chargé ensuite.
      //
      // On ne l'attend volontairement pas ici.
      await loadEpg();
    } catch (e) {
      loading = false;
      error = e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // EPG
  // ---------------------------------------------------------------------------

  Future<void> loadEpg() async {
    if (channels.isEmpty) {
      return;
    }

    if (loadingEpg) {
      return;
    }

    loadingEpg = true;

    try {
      await epgService.loadEpg(channels);
    } catch (e) {
      // L'EPG ne doit pas empêcher l'affichage
      // des chaînes.
      //
      // On laisse les chaînes affichées même si
      // le chargement EPG échoue.
      //
      // Le détail du programme pourra éventuellement
      // être récupéré plus tard.
    } finally {
      loadingEpg = false;
    }
  }

  // ---------------------------------------------------------------------------
  // RAFRAÎCHISSEMENT EPG
  // ---------------------------------------------------------------------------

  Future<void> refreshEpg() async {
    if (loading || loadingEpg) {
      return;
    }

    await loadEpg();
  }

  // ---------------------------------------------------------------------------
  // PROGRAMME COURANT
  // ---------------------------------------------------------------------------

  Future<dynamic> fetchCurrentProgram(
    TvChannel channel,
  ) {
    return epgService.fetchCurrentProgram(channel);
  }

  // ---------------------------------------------------------------------------
  // TIMER EPG
  // ---------------------------------------------------------------------------

  void startEpgTimer() {
    _epgTimer?.cancel();

    _epgTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        refreshEpg();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  void dispose() {
    _epgTimer?.cancel();
    _epgTimer = null;
  }
}
