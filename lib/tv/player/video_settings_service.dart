import 'package:shared_preferences/shared_preferences.dart';

import 'video_settings.dart';

class VideoSettingsService {
  static const _keyRtspTransport = 'video_rtsp_transport';
  static const _keyVideoQuality = 'video_quality';
  static const _keyAudioLanguage = 'video_audio_language';
  static const _keyFullscreenOnStart = 'video_fullscreen_on_start';
  static const _keyShowControlsOnStart = 'video_show_controls_on_start';

  Future<VideoSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return VideoSettings(
      rtspTransport: prefs.getString(_keyRtspTransport) ?? 'udp',
      videoQuality: prefs.getString(_keyVideoQuality) ?? 'hd',
      audioLanguage: prefs.getString(_keyAudioLanguage) ?? 'fra',
      fullscreenOnStart: prefs.getBool(_keyFullscreenOnStart) ?? false,
      showControlsOnStart: prefs.getBool(_keyShowControlsOnStart) ?? true,
    );
  }

  Future<void> save(VideoSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyRtspTransport, settings.rtspTransport);

    await prefs.setString(_keyVideoQuality, settings.videoQuality);

    await prefs.setString(_keyAudioLanguage, settings.audioLanguage);

    await prefs.setBool(_keyFullscreenOnStart, settings.fullscreenOnStart);

    await prefs.setBool(_keyShowControlsOnStart, settings.showControlsOnStart);
  }
}
