class VideoSettings {
  final String rtspTransport;
  final String videoQuality;
  final String audioLanguage;
  final bool fullscreenOnStart;
  final bool showControlsOnStart;

  const VideoSettings({
    this.rtspTransport = 'udp',
    this.videoQuality = 'hd',
    this.audioLanguage = 'fra',
    this.fullscreenOnStart = false,
    this.showControlsOnStart = true,
  });

  VideoSettings copyWith({
    String? rtspTransport,
    String? videoQuality,
    String? audioLanguage,
    bool? fullscreenOnStart,
    bool? showControlsOnStart,
  }) {
    return VideoSettings(
      rtspTransport: rtspTransport ?? this.rtspTransport,
      videoQuality: videoQuality ?? this.videoQuality,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      fullscreenOnStart: fullscreenOnStart ?? this.fullscreenOnStart,
      showControlsOnStart: showControlsOnStart ?? this.showControlsOnStart,
    );
  }
}
