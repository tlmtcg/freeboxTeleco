import '../../freebox_os.dart';

class TvChannelRepository {
  TvChannelRepository({required this.freebox});

  final FreeboxOS freebox;

  Future<Map<String, Map<String, dynamic>>> getChannelMetadata() async {
    final response = await freebox.get('/api/v8/tv/channels/');

    if (response is! Map || response['success'] != true) {
      throw Exception('Impossible de récupérer les informations des chaînes');
    }

    final result = response['result'];

    final metadata = <String, Map<String, dynamic>>{};

    if (result is Map) {
      result.forEach((key, value) {
        if (value is Map) {
          final channel = Map<String, dynamic>.from(value);

          final uuid = channel['uuid']?.toString() ?? key.toString();

          metadata[uuid] = channel;
        }
      });
    }

    return metadata;
  }
}
