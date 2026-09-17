import '../models/tv_channel.dart';
import 'tv_stream_selector.dart';

class TvChannelPlayer {
  final TvStreamSelector streamSelector;

  const TvChannelPlayer({this.streamSelector = const TvStreamSelector()});

  String? getStream(TvChannel channel) {
    return streamSelector.select(channel);
  }
}
