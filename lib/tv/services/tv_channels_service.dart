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
