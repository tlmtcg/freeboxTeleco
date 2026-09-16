import 'dart:async';
import 'dart:io';

import '../core/freebox_player.dart';
import '../network/freebox_socket.dart';
import 'rudp_packet.dart';

class RudpClient {
  RudpClient({required this.player, required this.socket});

  final FreeboxPlayer player;
  final FreeboxSocket socket;

  RawDatagramSocket? _udpSocket;

  int _remoteSequence = 0;
  int _reliableSequence = 0;

  bool _connected = false;

  final StreamController<RudpPacket> _receivedController =
      StreamController<RudpPacket>.broadcast();

  Stream<RudpPacket> get received => _receivedController.stream;

  bool get isConnected => _connected;

  int get remoteReliableSequence => _remoteSequence;

  int get reliableSequence => _reliableSequence;

  // ============================================================
  // RUDP CONSTANTS
  // ============================================================

  static const int rudpCmdConnReq = 0x02;
  static const int rudpCmdConnRsp = 0x03;
  static const int rudpCmdApp = 0x10;

  static const int rudpOptReliable = 0x01;
  static const int rudpOptAck = 0x02;

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect() async {
    if (_udpSocket != null) {
      return;
    }

    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    print('Socket RUDP initialisée.');

    _udpSocket!.listen((RawSocketEvent event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      final datagram = _udpSocket!.receive();

      if (datagram == null) {
        return;
      }

      final packet = RudpPacket.decode(datagram.data);

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

      // --------------------------------------------------------
      // Le traitement du paquet est délégué à l'appelant.
      // --------------------------------------------------------

      _receivedController.add(packet);
    });
  }

  // ============================================================
  // CONN_REQ
  // ============================================================

  Future<void> sendConnectionRequest({required int reliableSequence}) async {
    if (_udpSocket == null) {
      throw StateError('Socket RUDP non initialisée.');
    }

    _reliableSequence = reliableSequence & 0xFFFF;

    if (_reliableSequence == 0) {
      _reliableSequence = 1;
    }

    final packet = RudpPacket(
      command: rudpCmdConnReq,
      options: rudpOptReliable,
      reliableAck: 0,
      reliable: _reliableSequence,
      unreliable: 0,
      payload: const <int>[0x00, 0x00, 0x00, 0x00],
    );

    print('');
    print('========================================');
    print('          RUDP CONN_REQ');
    print('========================================');

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

    await send(packet);
  }

  // ============================================================
  // SEND
  // ============================================================

  Future<void> send(RudpPacket packet) async {
    final udpSocket = _udpSocket;

    if (udpSocket == null) {
      throw StateError('Socket RUDP non initialisée.');
    }

    udpSocket.send(packet.encode(), player.address, player.port);
  }

  // ============================================================
  // CONN_RSP
  // ============================================================

  void processConnectionResponse(RudpPacket packet) {
    if (packet.command != rudpCmdConnRsp) {
      return;
    }

    print('');
    print('========================================');
    print('          RUDP CONN_RSP RECU');
    print('========================================');

    print('Reliable ACK : ${packet.reliableAck}');
    print('Reliable     : ${packet.reliable}');
    print('Unreliable   : ${packet.unreliable}');
    print('Payload      : ${packet.payload.length} octets');

    // Le protocole attend 4 octets dans le payload.
    if (packet.payload.length < 4) {
      print('CONN_RSP invalide : payload trop court.');
      return;
    }

    final accepted =
        (packet.payload[0] << 24) |
        (packet.payload[1] << 16) |
        (packet.payload[2] << 8) |
        packet.payload[3];

    print('Accepted     : $accepted');

    if (accepted == 0) {
      print('CONN_RSP refusé.');
      return;
    }

    // ----------------------------------------------------------
    // Même comportement que l'ancien FreeboxPlayerClient.
    // ----------------------------------------------------------

    _remoteSequence = packet.reliable;

    _connected = true;

    print('RUDP CONNECTE');
    print('Remote sequence : $_remoteSequence');

    print('========================================');
  }

  // ============================================================
  // SEND APP
  // ============================================================

  Future<void> sendApp(
    int command,
    List<int> payload, {
    required bool reliable,
  }) async {
    if (!_connected) {
      throw StateError('RUDP non connecté.');
    }

    int nextReliable = _reliableSequence;

    if (reliable) {
      nextReliable = (_reliableSequence + 1) & 0xFFFF;

      if (nextReliable == 0) {
        nextReliable = 1;
      }
    }

    var options = rudpOptAck;

    if (reliable) {
      options |= rudpOptReliable;
    }

    final packet = RudpPacket(
      command: rudpCmdApp + command,
      options: options,
      reliableAck: _remoteSequence,
      reliable: nextReliable,
      unreliable: 0,
      payload: payload,
    );

    print('');
    print('========================================');
    print('          RUDP APP ENVOI');
    print('========================================');

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
    print('Payload      : ${payload.length} octets');

    print('========================================');

    await send(packet);

    if (reliable) {
      _reliableSequence = nextReliable;
    }
  }

  // ============================================================
  // SET CONNECTED
  // ============================================================

  void setConnected({required int remoteSequence}) {
    _remoteSequence = remoteSequence;
    _connected = true;
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  void disconnect() {
    _connected = false;

    _udpSocket?.close();
    _udpSocket = null;

    _remoteSequence = 0;
    _reliableSequence = 0;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _udpSocket?.close();
    _udpSocket = null;

    if (!_receivedController.isClosed) {
      _receivedController.close();
    }
  }
}
