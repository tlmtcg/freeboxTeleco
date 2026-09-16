import 'hid_client.dart';

/// ============================================================
/// TOUCHES / COMMANDES FREEBOX
/// ============================================================

enum FreeboxKey {
  power,
  av,
  back,
  search,
  info,
  free,
  volumeUp,
  volumeDown,
  mute,
  channelUp,
  channelDown,
  rewind,
  playPause,
  fastForward,
  stop,
  play,
  shuffle,
  nextTrack,
  previousTrack,
  key0,
  key1,
  key2,
  key3,
  key4,
  key5,
  key6,
  key7,
  key8,
  key9,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  ok,
  backspace,
  menu,
  sleep,
  wake,
  browserBack,
  browserForward,
  browserRefresh,
  browserStop,
  nextVideoTrack,
  nextAudioTrack,
  nextSubtitleTrack,
  launchTV,
  launchReplay,
  launchVideoclub,
  showTVGuide,
  showTVRecords,
  launchFileBrowser,
  launchYouTube,
  launchRadios,
  launchCanalVOD,
  togglePiP,
  launchNetflix,
  record,
}

/// ============================================================
/// CODES HID FREEBOX
/// ============================================================

final Map<FreeboxKey, int> freeboxHidCodes = {
  FreeboxKey.power: 0x30,
  FreeboxKey.av: 0x63,
  FreeboxKey.back: 0x204,
  FreeboxKey.search: 0x221,
  FreeboxKey.info: 0x209,
  FreeboxKey.free: 0x18F,
  FreeboxKey.volumeUp: 0xE9,
  FreeboxKey.volumeDown: 0xEA,
  FreeboxKey.mute: 0xE2,
  FreeboxKey.channelUp: 0x9C,
  FreeboxKey.channelDown: 0x9D,
  FreeboxKey.rewind: 0xB4,
  FreeboxKey.playPause: 0xCD,
  FreeboxKey.fastForward: 0xB3,
  FreeboxKey.stop: 0xB7,
  FreeboxKey.play: 0xB0,
  FreeboxKey.shuffle: 0xB9,
  FreeboxKey.nextTrack: 0xB5,
  FreeboxKey.previousTrack: 0xB6,

  // ==========================================================
  // NUMERIQUE
  // ==========================================================

  FreeboxKey.key0: 0x62,
  FreeboxKey.key1: 0x59,
  FreeboxKey.key2: 0x5A,
  FreeboxKey.key3: 0x5B,
  FreeboxKey.key4: 0x5C,
  FreeboxKey.key5: 0x5D,
  FreeboxKey.key6: 0x5E,
  FreeboxKey.key7: 0x5F,
  FreeboxKey.key8: 0x60,
  FreeboxKey.key9: 0x61,

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  FreeboxKey.arrowUp: 0x52,
  FreeboxKey.arrowDown: 0x51,
  FreeboxKey.arrowLeft: 0x50,
  FreeboxKey.arrowRight: 0x4F,
  FreeboxKey.ok: 0x28,
  FreeboxKey.backspace: 0x2A,

  // ==========================================================
  // DESKTOP / SYSTEM
  // ==========================================================

  FreeboxKey.menu: 0x86,
  FreeboxKey.sleep: 0x82,
  FreeboxKey.wake: 0x83,

  // ==========================================================
  // BROWSER
  // ==========================================================

  FreeboxKey.browserBack: 0x224,
  FreeboxKey.browserForward: 0x225,
  FreeboxKey.browserRefresh: 0x227,
  FreeboxKey.browserStop: 0x226,

  // ==========================================================
  // MEDIA
  // ==========================================================

  FreeboxKey.nextVideoTrack: 0x171,
  FreeboxKey.nextAudioTrack: 0x173,
  FreeboxKey.nextSubtitleTrack: 0x175,

  // ==========================================================
  // RACCOURCIS FREEBOX
  // ==========================================================

  FreeboxKey.launchTV: 0xF01,
  FreeboxKey.launchReplay: 0xF02,
  FreeboxKey.launchVideoclub: 0xF03,
  FreeboxKey.showTVGuide: 0xF04,
  FreeboxKey.showTVRecords: 0xF05,
  FreeboxKey.launchFileBrowser: 0xF06,
  FreeboxKey.launchYouTube: 0xF07,
  FreeboxKey.launchRadios: 0xF08,
  FreeboxKey.launchCanalVOD: 0xF09,
  FreeboxKey.togglePiP: 0xF0A,
  FreeboxKey.launchNetflix: 0xF0B,

  // ==========================================================
  // ENREGISTREMENT
  // ==========================================================

  FreeboxKey.record: 0xB2,
};

/// ============================================================
/// CODES RELEVANT DU REPORT KEYBOARD
/// ============================================================

const Set<int> _keyboardCodes = {
  // 0–9
  0x62,
  0x59,
  0x5A,
  0x5B,
  0x5C,
  0x5D,
  0x5E,
  0x5F,
  0x60,
  0x61,

  // Arrows
  0x4F,
  0x50,
  0x51,
  0x52,

  // OK
  0x28,

  // Backspace
  0x2A,
};

/// ============================================================
/// CODES RELEVANT DU REPORT DESKTOP / SYSTEM
/// ============================================================

const Set<int> _desktopCodes = {
  0x86, // Menu
  0x82, // Sleep
  0x83, // Wake
};

/// ============================================================
/// ENVOI D'UNE TOUCHE FREEBOX
/// ============================================================
///
/// Cette fonction choisit automatiquement le report HID :
///
/// Keyboard -> sendKeyboard()
/// Desktop  -> sendDesktop()
/// Consumer -> sendConsumer()
///
/// Le code HID reste donc totalement indépendant de l'UI.
///

Future<void> sendFreeboxKey(
  FreeboxKey key,
  HidClient client,
) async {
  final code = freeboxHidCodes[key];

  if (code == null) {
    throw StateError(
      'Code HID manquant pour $key',
    );
  }

  // ==========================================================
  // KEYBOARD PAGE
  // ==========================================================

  if (_keyboardCodes.contains(code)) {
    await client.sendKeyboard(code);
    return;
  }

  // ==========================================================
  // DESKTOP / SYSTEM PAGE
  // ==========================================================

  if (_desktopCodes.contains(code)) {
    await client.sendDesktop(code);
    return;
  }

  // ==========================================================
  // CONSUMER PAGE
  // ==========================================================

  await client.sendConsumer(code);
}
