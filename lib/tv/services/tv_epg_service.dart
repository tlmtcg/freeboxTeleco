import '../../freebox_os.dart';
import '../models/tv_channel.dart';

class TvEpgService {
  final FreeboxOS freebox;

  /// Nombre de chaînes traitées simultanément.
  static const int batchSize = 12;

  TvEpgService({required this.freebox});

  // ============================================================
  // LOAD EPG
  // ============================================================

  Future<void> loadEpg(List<TvChannel> channels) async {
    if (channels.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (int i = 0; i < channels.length; i += batchSize) {
      final end = (i + batchSize < channels.length)
          ? i + batchSize
          : channels.length;

      final batch = channels.sublist(i, end);

      await Future.wait(batch.map((channel) => loadChannelEpg(channel, now)));
    }
  }

  // ============================================================
  // LOAD CHANNEL EPG
  // ============================================================

  Future<void> loadChannelEpg(TvChannel channel, int now) async {
    final uuid = channel.uuid;

    if (uuid.isEmpty) {
      return;
    }

    try {
      final response = await freebox.get(
        '/api/v8/tv/epg/by_channel/$uuid/$now',
      );

      if (response is! Map || response['success'] != true) {
        return;
      }

      final result = response['result'];

      if (result is! Map) {
        return;
      }

      Map<String, dynamic>? currentProgram;

      // --------------------------------------------------------
      // Recherche du programme actuellement diffusé
      // --------------------------------------------------------

      for (final entry in result.entries) {
        final value = entry.value;

        if (value is! Map) {
          continue;
        }

        final program = Map<String, dynamic>.from(value);

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

      // --------------------------------------------------------
      // Mise à jour du modèle
      // --------------------------------------------------------

      if (currentProgram != null) {
        channel.epg = currentProgram;

        if (channel.displayName.toLowerCase().contains('arte')) {
          print('========================================');
          print('EPG ARTE');
          print('========================================');
          print(currentProgram);
          print('========================================');
        }
      } else {
        channel.epg = null;
      }
    } catch (_) {
      // --------------------------------------------------------
      // L'EPG est optionnel.
      //
      // Une erreur EPG ne doit pas empêcher
      // l'affichage des chaînes.
      // --------------------------------------------------------
    }
  }

  // ============================================================
  // LOAD EPG FOR ONE CHANNEL - NOW
  // ============================================================

  Future<Map<String, dynamic>?> fetchCurrentProgram(TvChannel channel) async {
    final uuid = channel.uuid;

    if (uuid.isEmpty) {
      return null;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final response = await freebox.get(
        '/api/v8/tv/epg/by_channel/$uuid/$now',
      );

      if (response is! Map || response['success'] != true) {
        return null;
      }

      final result = response['result'];

      if (result is! Map) {
        return null;
      }

      for (final entry in result.entries) {
        final value = entry.value;

        if (value is! Map) {
          continue;
        }

        final program = Map<String, dynamic>.from(value);

        final date = program['date'];
        final duration = program['duration'];

        if (date is! num || duration is! num) {
          continue;
        }

        final start = date.toInt();
        final end = start + duration.toInt();

        if (now >= start && now < end) {
          return program;
        }
      }
    } catch (_) {
      // EPG optionnel.
    }

    return null;
  }
}
