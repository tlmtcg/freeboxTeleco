import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import '../hid/freebox_keys.dart';

// ============================================================
// TYPES COMMUNS
// ============================================================

typedef RemoteSend = Future<void> Function(
  String,
  Future<void> Function(),
);

// ============================================================
// SECTION
// ============================================================

class RemoteSection extends StatelessWidget {
  final String title;
  final Widget child;

  const RemoteSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121722),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDDE5FF),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// BOUTON GENERIQUE
// ============================================================

class RemoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final FreeboxKey keyCode;
  final HidClient client;
  final RemoteSend send;

  const RemoteButton({
    super.key,
    required this.icon,
    required this.label,
    required this.keyCode,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () {
        send(
          label,
          () async {
            await sendFreeboxKey(
              keyCode,
              client,
            );
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2233),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8EAEFF),
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB8BFCD),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAVE NUMERIQUE
// ============================================================

class RemoteNumericPad extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteNumericPad({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _numRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _numRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _numRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _numberButton(
              '0',
              FreeboxKey.key0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _numRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        return _numberButton(
          number,
          _keyFromNumber(number),
        );
      }).toList(),
    );
  }

  FreeboxKey _keyFromNumber(String number) {
    switch (number) {
      case '0':
        return FreeboxKey.key0;
      case '1':
        return FreeboxKey.key1;
      case '2':
        return FreeboxKey.key2;
      case '3':
        return FreeboxKey.key3;
      case '4':
        return FreeboxKey.key4;
      case '5':
        return FreeboxKey.key5;
      case '6':
        return FreeboxKey.key6;
      case '7':
        return FreeboxKey.key7;
      case '8':
        return FreeboxKey.key8;
      case '9':
        return FreeboxKey.key9;
      default:
        return FreeboxKey.key0;
    }
  }

  Widget _numberButton(
    String number,
    FreeboxKey key,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        send(
          number,
          () async {
            await sendFreeboxKey(
              key,
              client,
            );
          },
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF181F2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF27334A),
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDDE5FF),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION
// ============================================================

class RemotePad extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemotePad({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFF151B28),
                shape: BoxShape.circle,
              ),
            ),
            _padButton(
              Icons.keyboard_arrow_up_rounded,
              Alignment.topCenter,
              FreeboxKey.arrowUp,
            ),
            _padButton(
              Icons.keyboard_arrow_down_rounded,
              Alignment.bottomCenter,
              FreeboxKey.arrowDown,
            ),
            _padButton(
              Icons.keyboard_arrow_left_rounded,
              Alignment.centerLeft,
              FreeboxKey.arrowLeft,
            ),
            _padButton(
              Icons.keyboard_arrow_right_rounded,
              Alignment.centerRight,
              FreeboxKey.arrowRight,
            ),
            GestureDetector(
              onTap: () {
                send(
                  'OK',
                  () async {
                    await sendFreeboxKey(
                      FreeboxKey.ok,
                      client,
                    );
                  },
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFF5B8CFF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _padButton(
    IconData icon,
    Alignment alignment,
    FreeboxKey key,
  ) {
    return Align(
      alignment: alignment,
      child: IconButton(
        icon: Icon(
          icon,
          size: 34,
          color: const Color(0xFFDDE5FF),
        ),
        onPressed: () {
          send(
            key.name,
            () async {
              await sendFreeboxKey(
                key,
                client,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// TV
// ============================================================

class RemoteTVControls extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteTVControls({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(
          icon: Icons.volume_down_rounded,
          label: 'Vol -',
          keyCode: FreeboxKey.volumeDown,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.volume_up_rounded,
          label: 'Vol +',
          keyCode: FreeboxKey.volumeUp,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'Prog -',
          keyCode: FreeboxKey.channelDown,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: 'Prog +',
          keyCode: FreeboxKey.channelUp,
          client: client,
          send: send,
        ),
      ],
    );
  }
}

// ============================================================
// APPLICATIONS
// ============================================================

class RemoteApps extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteApps({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 22,
      children: [
        RemoteButton(
          icon: Icons.live_tv_rounded,
          label: 'TV',
          keyCode: FreeboxKey.launchTV,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.replay_rounded,
          label: 'Replay',
          keyCode: FreeboxKey.launchReplay,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.movie_rounded,
          label: 'Vidéos',
          keyCode: FreeboxKey.launchVideoclub,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.radio_rounded,
          label: 'Radios',
          keyCode: FreeboxKey.launchRadios,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.video_library_rounded,
          label: 'YouTube',
          keyCode: FreeboxKey.launchYouTube,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.movie_filter_rounded,
          label: 'Netflix',
          keyCode: FreeboxKey.launchNetflix,
          client: client,
          send: send,
        ),
      ],
    );
  }
}

// ============================================================
// LECTURE
// ============================================================

class RemoteTransport extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteTransport({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(
          icon: Icons.replay_10_rounded,
          label: 'Retour',
          keyCode: FreeboxKey.rewind,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.pause_rounded,
          label: 'Pause',
          keyCode: FreeboxKey.playPause,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.stop_rounded,
          label: 'Stop',
          keyCode: FreeboxKey.stop,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.forward_10_rounded,
          label: 'Avance',
          keyCode: FreeboxKey.fastForward,
          client: client,
          send: send,
        ),
      ],
    );
  }
}

// ============================================================
// SYSTEME
// ============================================================

class RemoteSystem extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteSystem({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 22,
      children: [
        RemoteButton(
          icon: Icons.power_settings_new_rounded,
          label: 'Power',
          keyCode: FreeboxKey.power,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.info_rounded,
          label: 'Info',
          keyCode: FreeboxKey.info,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.home_rounded,
          label: 'Free',
          keyCode: FreeboxKey.free,
          client: client,
          send: send,
        ),
        RemoteButton(
          icon: Icons.arrow_back_rounded,
          label: 'Retour',
          keyCode: FreeboxKey.back,
          client: client,
          send: send,
        ),
      ],
    );
  }
}
