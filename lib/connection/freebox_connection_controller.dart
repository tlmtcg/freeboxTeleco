import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/freebox_player.dart';
import '../discovery/freebox_discovery.dart';
import '../hid/hid_client.dart';
import '../network/freebox_socket.dart';
import '../rudp/rudp_client.dart';
import '../rudp/rudp_packet.dart';

class FreeboxConnectionController {
  // ===========================================================================
  // SERVICES
  // ===========================================================================

  final FreeboxDiscovery discovery;

  FreeboxConnectionController({
    FreeboxDiscovery? discovery,
  }) : discovery = discovery ?? FreeboxDiscovery();

  // ===========================================================================
  // ETAT
  // ===========================================================================

  bool isConnected = false;
  bool isCheckingConnection = false;

  String connectionMessage =
      'Recherche de la Freebox sur le réseau local...';

  // ===========================================================================
  // CONNEXION
  // ===========================================================================

  FreeboxSocket? _socket;
  RudpClient? _rudp;
  HidClient? _hid;
  FreeboxPlayer? _player;

  StreamSubscription<RudpPacket>? _rudpSubscription;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  HidClient? get hid => _hid;

  FreeboxPlayer? get player => _player;

  // ===========================================================================
  // LISTENERS
  // ===========================================================================

  VoidCallback? onStateChanged;

  void _notify() {
    onStateChanged?.call();
  }

  // ===========================================================================
  // CONNECT
  // ===========================================================================

  Future<void> connect() async {
    isCheckingConnection = true;
    isConnected = false;
    connectionMessage =
        'Recherche du Player Delta sur le réseau local...';

    _notify();

    try {
      // -----------------------------------------------------------------------
      // Nettoyage
      // -----------------------------------------------------------------------

      await disconnect();

      // -----------------------------------------------------------------------
      // DISCOVERY
      // -----------------------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('       RECHERCHE FREEBOX PLAYER');
      debugPrint('========================================');

      final player = await discovery.discover();

      if (player == null) {
        throw StateError(
          'Player Freebox introuvable.',
        );
      }

      debugPrint(
        'Player trouvé : '
        '${player.address.address}:${player.port}',
      );

      // -----------------------------------------------------------------------
      // SOCKET
      // -----------------------------------------------------------------------

      final socket = FreeboxSocket();

      // -----------------------------------------------------------------------
      // RUDP
      // -----------------------------------------------------------------------

      final rudp = RudpClient(
        player: player,
        socket: socket,
      );

      // -----------------------------------------------------------------------
      // HID
      // -----------------------------------------------------------------------

      final hid = HidClient(
        rudp: rudp,
      );

      _socket = socket;
      _rudp = rudp;
      _hid = hid;
      _player = player;

      // -----------------------------------------------------------------------
      // RECEPTION RUDP
      // -----------------------------------------------------------------------

      _rudpSubscription = rudp.received.listen(
        (packet) {
          debugPrint(
            'CONNECTION <- RUDP '
            'cmd=0x${packet.command.toRadixString(16).padLeft(2, '0')}',
          );

          // CONN_RSP
          if (packet.command ==
              RudpClient.rudpCmdConnRsp) {
            rudp.processConnectionResponse(packet);
          }

          // HID
          hid.processPacket(packet);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            'Erreur stream RUDP : $error',
          );
        },
      );

      // -----------------------------------------------------------------------
      // CONNEXION RUDP
      // -----------------------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('             CONNEXION RUDP');
      debugPrint('========================================');

      await rudp.connect();

      // -----------------------------------------------------------------------
      // CONN_REQ
      // -----------------------------------------------------------------------

      var reliableSequence =
          DateTime.now().millisecondsSinceEpoch & 0xFFFF;

      if (reliableSequence == 0) {
        reliableSequence = 1;
      }

      await rudp.sendConnectionRequest(
        reliableSequence: reliableSequence,
      );

      // -----------------------------------------------------------------------
      // ATTENTE CONN_RSP
      // -----------------------------------------------------------------------

      final connected = await waitForRudpConnection(
        rudp,
        timeout: const Duration(seconds: 3),
      );

      if (!connected) {
        throw StateError(
          'Timeout ou refus de la connexion RUDP.',
        );
      }

      debugPrint('RUDP connecté.');

      // -----------------------------------------------------------------------
      // DEVICE_NEW
      // -----------------------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('             HID DEVICE_NEW');
      debugPrint('========================================');

      await hid.sendDeviceNew();

      // -----------------------------------------------------------------------
      // ATTENTE HID
      // -----------------------------------------------------------------------

      final hidReady = await waitForHidReady(
        hid,
        timeout: const Duration(seconds: 5),
      );

      if (!hidReady) {
        throw StateError(
          'Le Player n\'a pas activé les rapports HID nécessaires.',
        );
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('       HID CONNECTE AU FREEBOX PLAYER');
      debugPrint('========================================');

      isConnected = true;
      isCheckingConnection = false;

      connectionMessage =
          'Player Delta connecté '
          '(${player.address.address}:${player.port})';

      _notify();
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('         ERREUR CONNEXION');
      debugPrint('========================================');
      debugPrint('$error');
      debugPrint('$stackTrace');

      await disconnect();

      isConnected = false;
      isCheckingConnection = false;

      connectionMessage =
          'Player introuvable ou appairage refusé. '
          'Vérifiez le même Wi-Fi.';

      _notify();
    }
  }

  // ===========================================================================
  // WAIT RUDP
  // ===========================================================================

  Future<bool> waitForRudpConnection(
    RudpClient rudp, {
    required Duration timeout,
  }) async {
    final deadline =
        DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (rudp.isConnected) {
        return true;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }

    return rudp.isConnected;
  }

  // ===========================================================================
  // WAIT HID
  // ===========================================================================

  Future<bool> waitForHidReady(
    HidClient hid, {
    required Duration timeout,
  }) async {
    final deadline =
        DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (hid.isReady) {
        return true;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }

    return hid.isReady;
  }

  // ===========================================================================
  // COMMAND
  // ===========================================================================

  Future<void> sendCommand(
    Future<void> Function() command,
  ) async {
    if (!isConnected || _hid == null) {
      throw StateError(
        'Player Delta non connecté.',
      );
    }

    await command();
  }

  // ===========================================================================
  // DISCONNECT
  // ===========================================================================

  Future<void> disconnect() async {
    await _rudpSubscription?.cancel();

    _rudpSubscription = null;

    _hid = null;

    _rudp?.disconnect();
    _rudp?.dispose();

    _rudp = null;
    _socket = null;
    _player = null;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  Future<void> dispose() async {
    await disconnect();
  }
}

