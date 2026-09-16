import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import '../hid/freebox_keys.dart';

class RemotePop extends StatelessWidget {
  final HidClient client;
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

  const RemotePop({
    super.key,
    required this.client,
    required this.send,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          RemoteSection(
            title: 'Navigation',
            child: RemotePad(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 20),

          RemoteSection(
            title: 'TV',
            child: RemoteTVControls(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 20),

          RemoteSection(
            title: 'Applications',
            child: RemoteApps(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 20),

          RemoteSection(
            title: 'Lecture',
            child: RemoteTransport(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 20),

          RemoteSection(
            title: 'Système',
            child: RemoteSystem(
              client: client,
              send: send,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
// NAVIGATION
// ============================================================

class RemotePad extends StatelessWidget {
  final HidClient client;
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
