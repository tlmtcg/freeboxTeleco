import '../models/tv_channel.dart';

class TvChannelMapper {
  List<TvChannel> merge(
    List<dynamic> bouquetChannels,
    Map<String, Map<String, dynamic>> metadata, {
    bool? freeOnly,
  }) {
    final channels = <TvChannel>[];

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

      final channelMetadata =
          metadata[uuid] ??
          <String, dynamic>{};

      final mergedChannel = <String, dynamic>{
        ...channelMetadata,
        ...bouquetChannel,
        'uuid': uuid,
      };

      // --------------------------------------------------------
      // Suppression des déclinaisons régionales France 3
      // --------------------------------------------------------

      if (_isFrance3Regional(mergedChannel)) {
        continue;
      }

      final channel =
          TvChannel.fromMap(mergedChannel);

      // --------------------------------------------------------
      // Filtre gratuit / payant
      // --------------------------------------------------------

      if (freeOnly == true && !channel.isFree) {
        continue;
      }

      if (freeOnly == false && !channel.isPaid) {
        continue;
      }

      channels.add(channel);
    }

    // ----------------------------------------------------------
    // Tri par numéro de chaîne
    // ----------------------------------------------------------

    channels.sort(
      (a, b) => a.number.compareTo(b.number),
    );

    return channels;
  }

  // ============================================================
  // FRANCE 3 REGIONAL
  // ============================================================

  bool _isFrance3Regional(
    Map<String, dynamic> channel,
  ) {
    final name =
        channel['name']?.toString().trim() ?? '';

    final shortName =
        channel['short_name']?.toString().trim() ?? '';

    return
        (name.startsWith('France 3 ') &&
                name != 'France 3') ||
        (shortName.startsWith('France 3 ') &&
                shortName != 'France 3');
  }
}

