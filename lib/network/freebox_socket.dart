import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class FreeboxSocket {
  RawDatagramSocket? _socket;

  StreamSubscription<RawSocketEvent>? _subscription;

  final StreamController<Uint8List> _receivedController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get received => _receivedController.stream;

  bool get isOpen => _socket != null;

  // ============================================================
  // OPEN
  // ============================================================

  Future<void> open() async {
    if (_socket != null) {
      return;
    }

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );

    _socket = socket;

    _subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      final datagram = socket.receive();

      if (datagram == null) {
        return;
      }

      _receivedController.add(Uint8List.fromList(datagram.data));
    });
  }

  // ============================================================
  // SEND
  // ============================================================

  void send(Uint8List data, InternetAddress address, int port) {
    final socket = _socket;

    if (socket == null) {
      throw StateError('Socket Freebox non ouvert.');
    }

    socket.send(data, address, port);
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;

    _socket?.close();
    _socket = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await close();
    await _receivedController.close();
  }
}

