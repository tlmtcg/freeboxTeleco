import 'package:flutter/material.dart';

import 'discovery/freebox_discovery.dart';
import 'network/freebox_socket.dart';
import 'rudp/rudp_client.dart';
import 'hid/hid_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('========================================');
  print('          TEST HID FREEBOX');
  print('========================================');

  // --------------------------------------------------
  // DISCOVERY
  // --------------------------------------------------

  final discovery = FreeboxDiscovery();

  print('Recherche du Player Freebox...');

  final player = await discovery.discover(timeout: const Duration(seconds: 5));

  if (player == null) {
    print('Aucun Player Freebox trouvé.');

    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Player Freebox introuvable'))),
      ),
    );

    return;
  }

  print('Player trouvé : $player');

  // --------------------------------------------------
  // SOCKET
  // --------------------------------------------------

  final socket = FreeboxSocket();

  // --------------------------------------------------
  // RUDP
  // --------------------------------------------------

  final rudp = RudpClient(player: player, socket: socket);

  // --------------------------------------------------
  // HID
  // --------------------------------------------------

  final hid = HidClient(rudp: rudp);

  // --------------------------------------------------
  // RECEPTION RUDP
  // --------------------------------------------------

  bool deviceNewSent = false;
  bool okSent = false;

  rudp.received.listen((packet) async {
    print('');
    print('========================================');
    print('          PAQUET RUDP RECU');
    print('========================================');

    print(packet);

    print(
      'Command : 0x'
      '${packet.command.toRadixString(16).padLeft(2, '0')}',
    );

    print(
      'Options : 0x'
      '${packet.options.toRadixString(16).padLeft(2, '0')}',
    );

    print('Reliable ACK : ${packet.reliableAck}');
    print('Reliable     : ${packet.reliable}');
    print('Unreliable   : ${packet.unreliable}');
    print('Payload      : ${packet.payload.length} octets');

    // ------------------------------------------------
    // CONN_RSP
    // ------------------------------------------------

    if (packet.command == 0x03) {
      print('');
      print('========================================');
      print('          CONN_RSP RECU');
      print('========================================');

      // Valide réellement la connexion RUDP.
      rudp.processConnectionResponse(packet);

      if (rudp.isConnected) {
        print('Connexion RUDP acceptée.');

        // ------------------------------------------------
        // HID DEVICE_NEW
        // ------------------------------------------------

        if (!deviceNewSent) {
          deviceNewSent = true;

          print('');
          print('========================================');
          print('          ENVOI HID DEVICE_NEW');
          print('========================================');

          try {
            await hid.sendDeviceNew();

            print('HID DEVICE_NEW envoyé.');
          } catch (e) {
            // Si l'envoi échoue, on autorise une nouvelle tentative.
            deviceNewSent = false;

            print('');
            print('ERREUR DEVICE_NEW : $e');
          }
        }
      }
    }

    // ------------------------------------------------
    // HID
    // ------------------------------------------------

    hid.processPacket(packet);

    // ------------------------------------------------
    // TEST TOUCHE INFO
    // ------------------------------------------------

    if (hid.isReady && !okSent) {
      okSent = true;

      print('');
      print('========================================');
      print(' TEST TOUCHE INFO');
      print('========================================');
      print('Envoi Consumer : 0x60');
      try {
        await hid.sendConsumer(0x60);
        print('Touche INFO envoyée.');
      } catch (e) {
        okSent = false;
        print('');
        print('ERREUR TOUCHE INFO : $e');
      }
    }
  });

  // --------------------------------------------------
  // CONNEXION RUDP
  // --------------------------------------------------

  print('');
  print('Connexion RUDP...');

  await rudp.connect();

  print('Socket RUDP initialisée.');

  // --------------------------------------------------
  // CONN_REQ
  // --------------------------------------------------

  const sequence = 0x0B19;

  print('');
  print('Envoi CONN_REQ...');
  print('Sequence : $sequence');

  await rudp.sendConnectionRequest(reliableSequence: sequence);

  print('CONN_REQ envoyé.');

  // --------------------------------------------------
  // IMPORTANT
  // --------------------------------------------------
  //
  // Aucun délai artificiel ici.
  //
  // La suite est déclenchée par la réception
  // effective du CONN_RSP.
  //
  // CONN_REQ
  //     ↓
  // CONN_RSP 0x03
  //     ↓
  // processConnectionResponse()
  //     ↓
  // _connected = true
  //     ↓
  // DEVICE_NEW
  //
  // --------------------------------------------------

  // --------------------------------------------------
  // INTERFACE FLUTTER
  // --------------------------------------------------

  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Test HID Freebox'))),
    ),
  );
}
