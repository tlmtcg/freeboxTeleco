// import 'package:flutter/material.dart';

// import 'discovery/freebox_discovery.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   print('========================================');
//   print('       TEST FREEBOX DISCOVERY');
//   print('========================================');

//   final discovery = FreeboxDiscovery();

//   print('Recherche du Player Freebox...');

//   final player = await discovery.discover(timeout: const Duration(seconds: 5));

//   if (player == null) {
//     print('Aucun Player Freebox trouvé.');
//   } else {
//     print('Player Freebox trouvé !');
//     print('Adresse : ${player.address.address}');
//     print('Port    : ${player.port}');
//     print('Player  : $player');
//   }

//   print('========================================');

//   runApp(
//     const MaterialApp(
//       home: Scaffold(body: Center(child: Text('Test Freebox Discovery'))),
//     ),
//   );
// }

// import 'package:flutter/material.dart';

// import 'network/freebox_socket.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   print('========================================');
//   print('       TEST FREEBOX SOCKET');
//   print('========================================');

//   final socket = FreeboxSocket();

//   print('Ouverture du socket...');

//   await socket.open();

//   print('Socket ouvert : ${socket.isOpen}');

//   socket.received.listen((data) {
//     print('Datagramme reçu : ${data.length} octets');

//     print(data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' '));
//   });

//   print('Socket UDP prêt.');
//   print('========================================');

//   runApp(
//     const MaterialApp(
//       home: Scaffold(body: Center(child: Text('Test Freebox Socket'))),
//     ),
//   );
// }

// import 'package:flutter/material.dart';

// import 'rudp/rudp_packet.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   print('========================================');
//   print('          TEST RUDP PACKET');
//   print('========================================');

//   // Paquet CONN_REQ connu :
//   //
//   // 02 01 00 00 19 0B 00 00 00 00 00 00

//   final packet = RudpPacket(
//     command: 0x02,
//     options: 0x01,
//     reliableAck: 0x0000,
//     reliable: 0x0B19,
//     unreliable: 0x0000,
//   );

//   final encoded = packet.encode();

//   print('Paquet encode :');

//   print(
//     encoded
//         .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
//         .join(' '),
//   );

//   print('');

//   // ------------------------------------------------------------
//   // Vérification du décodage
//   // ------------------------------------------------------------

//   final decoded = RudpPacket.decode(encoded);

//   print('Paquet decode :');
//   print(decoded);

//   print('');

//   print(
//     'Command       : 0x'
//     '${decoded.command.toRadixString(16).padLeft(2, '0')}',
//   );

//   print(
//     'Options       : 0x'
//     '${decoded.options.toRadixString(16).padLeft(2, '0')}',
//   );

//   print('Reliable ACK  : ${decoded.reliableAck}');
//   print('Reliable      : ${decoded.reliable}');
//   print('Unreliable    : ${decoded.unreliable}');

//   print('');

//   // ------------------------------------------------------------
//   // Vérification automatique
//   // ------------------------------------------------------------

//   final expected = <int>[
//     0x02,
//     0x01,
//     0x00,
//     0x00,
//     0x19,
//     0x0B,
//     0x00,
//     0x00,
//     0x00,
//     0x00,
//     0x00,
//     0x00,
//   ];

//   final valid =
//       encoded.length == expected.length &&
//       List.generate(
//         expected.length,
//         (index) => encoded[index] == expected[index],
//       ).every((value) => value);

//   print('Vérification encodage : ${valid ? "OK" : "ERREUR"}');

//   print('========================================');

//   runApp(
//     const MaterialApp(
//       home: Scaffold(body: Center(child: Text('Test RUDP Packet'))),
//     ),
//   );
// }

import 'package:flutter/material.dart';

import 'discovery/freebox_player.dart';
import 'discovery/freebox_discovery.dart';
import 'network/freebox_socket.dart';
import 'rudp/rudp_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('========================================');
  print('          TEST RUDP FREEBOX');
  print('========================================');

  // ------------------------------------------------------------
  // DISCOVERY
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SOCKET
  // ------------------------------------------------------------

  final socket = FreeboxSocket();

  // ------------------------------------------------------------
  // RUDP
  // ------------------------------------------------------------

  final rudp = RudpClient(player: player, socket: socket);

  rudp.received.listen((packet) {
    print('');
    print('========================================');
    print('        PAQUET RUDP RECU');
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

    print('Payload : ${packet.payload.length} octets');

    print('========================================');
  });

  // ------------------------------------------------------------
  // CONNECT
  // ------------------------------------------------------------

  print('Connexion RUDP...');

  await rudp.connect();

  print('RUDP connecté.');

  // ------------------------------------------------------------
  // CONN_REQ
  // ------------------------------------------------------------

  const sequence = 0x0B19;

  print('');
  print('Envoi CONN_REQ...');
  print('Sequence : $sequence');

  rudp.sendConnectionRequest(reliableSequence: sequence);

  print('CONN_REQ envoyé.');

  print('========================================');

  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Test RUDP Freebox'))),
    ),
  );
}

