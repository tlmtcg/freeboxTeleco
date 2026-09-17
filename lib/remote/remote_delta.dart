import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import '../hid/freebox_keys.dart';
import 'remote_common.dart';

class RemoteDelta extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteDelta({
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
          // ==================================================
          // MICRO + POWER
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _DisabledButton(
                Icons.mic_rounded,
                'Micro',
              ),
              RemoteButton(
                icon: Icons.power_settings_new_rounded,
                label: 'Power',
                keyCode: FreeboxKey.power,
                client: client,
                send: send,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ==================================================
          // PAVE NUMERIQUE
          // ==================================================

          RemoteSection(
            title: 'Pavé numérique',
            child: RemoteNumericPad(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // RETOUR + RECHERCHE
          // ==================================================

          RemoteSection(
            title: 'Actions',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RemoteButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Retour',
                  keyCode: FreeboxKey.back,
                  client: client,
                  send: send,
                ),
                RemoteButton(
                  icon: Icons.search,
                  label: 'Cherche',
                  keyCode: FreeboxKey.search,
                  client: client,
                  send: send,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // NAVIGATION
          // ==================================================

          RemoteSection(
            title: 'Navigation',
            child: RemotePad(
              client: client,
              send: send,
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // MENU + FREE + INFO
          // ==================================================

          RemoteSection(
            title: 'Actions',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RemoteButton(
                  icon: Icons.menu,
                  label: 'Menu',
                  keyCode: FreeboxKey.menu,
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
                  icon: Icons.info_rounded,
                  label: 'Info',
                  keyCode: FreeboxKey.info,
                  client: client,
                  send: send,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // VOLUME + PROGRAMMES
          // ==================================================

          RemoteSection(
            title: 'Volume & Programmes',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RemoteButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Vol +',
                      keyCode: FreeboxKey.volumeUp,
                      client: client,
                      send: send,
                    ),
                    RemoteButton(
                      icon: Icons.volume_mute_rounded,
                      label: 'Mute',
                      keyCode: FreeboxKey.mute,
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
                ),

                const SizedBox(height: 20),

                Row(
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
                      icon: Icons.fiber_manual_record,
                      label: 'Record',
                      keyCode: FreeboxKey.record,
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // LECTURE
          // ==================================================

          RemoteSection(
            title: 'Lecture',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RemoteButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Play',
                      keyCode: FreeboxKey.play,
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
                  ],
                ),

                const SizedBox(height: 20),

                Row(
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
                      icon: Icons.forward_10_rounded,
                      label: 'Avance',
                      keyCode: FreeboxKey.fastForward,
                      client: client,
                      send: send,
                    ),
                    RemoteButton(
                      icon: Icons.search_rounded,
                      label: 'Recherche',
                      keyCode: FreeboxKey.search,
                      client: client,
                      send: send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOUTON DESACTIVE
// ============================================================

class _DisabledButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DisabledButton(
    this.icon,
    this.label,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2233),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Color(0xFF555A66),
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF555A66),
          ),
        ),
      ],
    );
  }
}
