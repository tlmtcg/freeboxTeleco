import '../../freebox_os.dart';

class TvBouquetRepository {
  TvBouquetRepository({required this.freebox});

  final FreeboxOS freebox;

  static const int freeboxTvBouquetId = 57;

  Future<Map<String, dynamic>> getFreeboxTvBouquet() async {
    final response = await freebox.get('/api/v8/tv/bouquets/');

    if (response is! Map || response['success'] != true) {
      throw Exception('Impossible de récupérer les bouquets TV');
    }

    final bouquets = response['result'] as List<dynamic>? ?? [];

    for (final bouquet in bouquets) {
      if (bouquet is Map && bouquet['id'] == freeboxTvBouquetId) {
        return Map<String, dynamic>.from(bouquet);
      }
    }

    throw Exception('Bouquet Freebox TV introuvable');
  }

  Future<List<dynamic>> getBouquetChannels(int bouquetId) async {
    final response = await freebox.get(
      '/api/v8/tv/bouquets/$bouquetId/channels',
    );

    if (response is! Map || response['success'] != true) {
      throw Exception('Impossible de récupérer les chaînes du bouquet');
    }

    return extractList(response['result']);
  }

  static List<dynamic> extractList(dynamic result) {
    if (result is List) {
      return result;
    }

    if (result is Map) {
      return result.values.toList();
    }

    return [];
  }
}
