import '../models/tv_channel.dart';

class TvStreamSelector {
  const TvStreamSelector();

  String? select(TvChannel channel) {
    return selectFromStreams(channel.streams);
  }

  String? selectFromStreams(List<Map<String, dynamic>> streams) {
    const priorities = ['hd', 'auto', 'sd'];

    for (final quality in priorities) {
      for (final stream in streams) {
        final streamQuality = stream['quality']?.toString();
        final rtsp = stream['rtsp']?.toString();

        if (streamQuality == quality && rtsp != null && rtsp.isNotEmpty) {
          return rtsp;
        }
      }
    }

    return null;
  }
}
