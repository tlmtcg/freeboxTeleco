import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../discovery/freebox_player.dart';
import '../network/freebox_socket.dart';
import 'rudp_packet.dart';

class RudpClient {
  RudpClient({required FreeboxPlayer player, required FreeboxSocket socket})
    : _player = player,
      _socket = socket;

  final FreeboxPlayer _player;
  final FreeboxSocket _socket;

  StreamSubscription<Uint8List>? _subscription;

  final StreamController<RudpPacket> _receivedController =
      StreamController<RudpPacket>.broadcast();

  Stream<RudpPacket> get received => _receivedController.stream;

  bool _connected = false;

  bool get isConnected => _connected;

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect() async {
    if (_connected) {
      return;
    }

    await _socket.open();

    _subscription = _socket.received.listen(_onDatagram);

    _connected = true;
  }

  // ============================================================
  // RECEIVE
  // ============================================================

  void _onDatagram(Uint8List data) {
    try {
      final packet = RudpPacket.decode(data);

      _receivedController.add(packet);
    } on FormatException {
      // Paquet UDP qui n'est pas un paquet RUDP valide.
    }
  }

  // ============================================================
  // SEND
  // ============================================================

  void send(RudpPacket packet) {
    if (!_connected) {
      throw StateError('RudpClient non connecté.');
    }

    final data = packet.encode();

    _socket.send(data, _player.address, _player.port);
  }

  // ============================================================
  // CONN_REQ
  // ============================================================

  void sendConnectionRequest({required int reliableSequence}) {
    final packet = RudpPacket(
      command: 0x02,
      options: 0x01,
      reliableAck: 0,
      reliable: reliableSequence,
      unreliable: 0,
    );

    send(packet);
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    _connected = false;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await disconnect();

    await _socket.dispose();

    await _receivedController.close();
  }
}
