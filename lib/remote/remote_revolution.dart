import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import '../hid/freebox_keys.dart';
import 'remote_common.dart';

class RemoteRevolution extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

  const RemoteRevolution({
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
          // POWER
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          // ACTIONS
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
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // VOLUME & PROGRAMMES
          // ==================================================

          RemoteSection(
            title: 'Volume & Programmes',
            child: Column(
              children: [
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
                      icon: Icons.volume_mute_rounded,
                      label: 'Mute',
                      keyCode: FreeboxKey.mute,
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
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // APPLICATIONS
          // ==================================================

          RemoteSection(
            title: 'Applications',
            child: Wrap(
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
                  icon: Icons.video_library_rounded,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}