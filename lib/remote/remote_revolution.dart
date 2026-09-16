import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import '../hid/freebox_keys.dart';
import 'remote_pop.dart';

class RemoteRevolution extends StatelessWidget {
  final HidClient client;
  final Future<void> Function(
    String,
    Future<void> Function(),
  ) send;

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
            child: Column(
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
                    _numberButton('0', FreeboxKey.key0),
                  ],
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

  // ==========================================================
  // PAVE NUMERIQUE
  // ==========================================================

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
