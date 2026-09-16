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

import 'package:flutter/material.dart';

import 'network/freebox_socket.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('========================================');
  print('       TEST FREEBOX SOCKET');
  print('========================================');

  final socket = FreeboxSocket();

  print('Ouverture du socket...');

  await socket.open();

  print('Socket ouvert : ${socket.isOpen}');

  socket.received.listen((data) {
    print('Datagramme reçu : ${data.length} octets');

    print(data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' '));
  });

  print('Socket UDP prêt.');
  print('========================================');

  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Test Freebox Socket'))),
    ),
  );
}
