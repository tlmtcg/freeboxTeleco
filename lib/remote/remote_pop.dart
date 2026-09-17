import 'package:flutter/material.dart';

import '../hid/hid_client.dart';
import 'remote_common.dart';

class RemotePop extends StatelessWidget {
  final HidClient client;
  final RemoteSend send;

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

          const SizedBox(height: 25),

          // ==================================================
          // PAVE NUMERIQUE
          // ==================================================
          RemoteSection(
            title: 'Pavé numérique',
            child: RemoteNumericPad(client: client, send: send),
          ),

        ],
      ),
    );
  }
}
