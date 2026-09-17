// import '../../freebox_os.dart';
// import '../models/tv_channel.dart';

// class TvChannelsService {
//   final FreeboxOS freebox;

//   /// ID du bouquet Freebox TV utilisé actuellement.
//   static const int freeboxTvBouquetId = 57;

//   TvChannelsService({required this.freebox});

//   // ============================================================
//   // LOAD CHANNELS
//   // ============================================================

//   Future<List<TvChannel>> loadChannels() async {
//     // ----------------------------------------------------------
//     // 1. Récupération des bouquets
//     // ----------------------------------------------------------

//     final bouquetsResponse = await freebox.get('/api/v8/tv/bouquets/');

//     if (bouquetsResponse is! Map || bouquetsResponse['success'] != true) {
//       throw Exception('Impossible de récupérer les bouquets TV');
//     }

//     final List<dynamic> bouquets =
//         bouquetsResponse['result'] as List<dynamic>? ?? [];

//     Map<String, dynamic>? freeboxTvBouquet;

//     for (final bouquet in bouquets) {
//       if (bouquet is Map && bouquet['id'] == freeboxTvBouquetId) {
//         freeboxTvBouquet = Map<String, dynamic>.from(bouquet);
//         break;
//       }
//     }

//     if (freeboxTvBouquet == null) {
//       throw Exception('Bouquet Freebox TV introuvable');
//     }

//     final int bouquetId =
//         (freeboxTvBouquet['id'] as num?)?.toInt() ?? freeboxTvBouquetId;

//     // ----------------------------------------------------------
//     // 2. Chaînes du bouquet
//     // ----------------------------------------------------------

//     final bouquetChannelsResponse = await freebox.get(
//       '/api/v8/tv/bouquets/$bouquetId/channels',
//     );

//     if (bouquetChannelsResponse is! Map ||
//         bouquetChannelsResponse['success'] != true) {
//       throw Exception('Impossible de récupérer les chaînes du bouquet');
//     }

//     final dynamic bouquetResult = bouquetChannelsResponse['result'];

//     final List<dynamic> bouquetChannels = _extractList(bouquetResult);

//     // ----------------------------------------------------------
//     // 3. Métadonnées des chaînes
//     // ----------------------------------------------------------

//     final channelsResponse = await freebox.get('/api/v8/tv/channels/');

//     if (channelsResponse is! Map || channelsResponse['success'] != true) {
//       throw Exception('Impossible de récupérer les informations des chaînes');
//     }

//     final dynamic channelResult = channelsResponse['result'];

//     final Map<String, Map<String, dynamic>> channelMetadata = {};

//     if (channelResult is Map) {
//       channelResult.forEach((key, value) {
//         if (value is Map) {
//           final channel = Map<String, dynamic>.from(value);

//           final uuid = channel['uuid']?.toString() ?? key.toString();

//           channelMetadata[uuid] = channel;
//         }
//       });
//     }

//     // ----------------------------------------------------------
//     // 4. Fusion bouquet + métadonnées
//     // ----------------------------------------------------------

//     final channels = <TvChannel>[];

//     for (final item in bouquetChannels) {
//       if (item is! Map) {
//         continue;
//       }

//       final bouquetChannel = Map<String, dynamic>.from(item);

//       final uuid = bouquetChannel['uuid']?.toString();

//       if (uuid == null || uuid.isEmpty) {
//         continue;
//       }

//       final metadata = channelMetadata[uuid] ?? <String, dynamic>{};

//       final mergedChannel = <String, dynamic>{
//         ...metadata,
//         ...bouquetChannel,
//         'uuid': uuid,
//       };

//       // --------------------------------------------------------
//       // Suppression des déclinaisons régionales France 3
//       // --------------------------------------------------------

//       if (_isFrance3Regional(mergedChannel)) {
//         continue;
//       }

//       channels.add(TvChannel.fromMap(mergedChannel));
//     }

//     // ----------------------------------------------------------
//     // 5. Tri par numéro de chaîne
//     // ----------------------------------------------------------

//     channels.sort((a, b) => a.number.compareTo(b.number));

//     return channels;
//   }

//   // ============================================================
//   // FRANCE 3 REGIONAL
//   // ============================================================

//   bool _isFrance3Regional(Map<String, dynamic> channel) {
//     final name = channel['name']?.toString().trim() ?? '';

//     final shortName = channel['short_name']?.toString().trim() ?? '';

//     return (name.startsWith('France 3 ') && name != 'France 3') ||
//         (shortName.startsWith('France 3 ') && shortName != 'France 3');
//   }

//   // ============================================================
//   // RESULT -> LIST
//   // ============================================================

//   List<dynamic> _extractList(dynamic result) {
//     if (result is List) {
//       return result;
//     }

//     if (result is Map) {
//       return result.values.toList();
//     }

//     return [];
//   }
// }

import '../../freebox_os.dart';
import '../models/tv_channel.dart';
import 'tv_bouquet_repository.dart';
import 'tv_channel_mapper.dart';
import 'tv_channel_repository.dart';

class TvChannelsService {
  TvChannelsService({required this.freebox})
    : _bouquets = TvBouquetRepository(freebox: freebox),
      _channels = TvChannelRepository(freebox: freebox),
      _mapper = TvChannelMapper();

  final FreeboxOS freebox;

  final TvBouquetRepository _bouquets;
  final TvChannelRepository _channels;
  final TvChannelMapper _mapper;

  // Cache des chaînes chargées
  List<TvChannel>? _cachedChannels;

  // ============================================================
  // LOAD CHANNELS
  // ============================================================

  Future<List<TvChannel>> loadChannels({
    bool forceRefresh = false,
    bool? freeOnly,
  }) async {
    if (!forceRefresh && _cachedChannels != null) {
      return List<TvChannel>.unmodifiable(_cachedChannels!);
    }

    // ----------------------------------------------------------
    // 1. Bouquet Freebox TV
    // ----------------------------------------------------------

    final bouquet = await _bouquets.getFreeboxTvBouquet();

    final bouquetId =
        (bouquet['id'] as num?)?.toInt() ??
        TvBouquetRepository.freeboxTvBouquetId;

    // ----------------------------------------------------------
    // 2. Chaînes du bouquet
    // ----------------------------------------------------------

    final bouquetChannels = await _bouquets.getBouquetChannels(bouquetId);

    // ----------------------------------------------------------
    // 3. Métadonnées
    // ----------------------------------------------------------

    final metadata = await _channels.getChannelMetadata();

    // ----------------------------------------------------------
    // 4. Fusion / filtrage / conversion / tri
    // ----------------------------------------------------------

    final channels = _mapper.merge(
      bouquetChannels,
      metadata,
      freeOnly: freeOnly,
    );
    
    _cachedChannels = channels;

    return List<TvChannel>.unmodifiable(channels);
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<TvChannel>> searchChannels(String query) async {
    final channels = await loadChannels();

    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return channels;
    }

    return channels.where((channel) {
      final name = _normalize(channel.name);

      return name.contains(normalizedQuery);
    }).toList();
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  // ============================================================
  // CLEAR CACHE
  // ============================================================

  void clearCache() {
    _cachedChannels = null;
  }
}
