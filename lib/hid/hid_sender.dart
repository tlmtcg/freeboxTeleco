import '../rudp/rudp_client.dart';
import 'hid_codec.dart';

class HidSender {
  HidSender({required this.rudp});

  final RudpClient rudp;

  Future<void> send(
    int command,
    List<int> payload, {
    required bool reliable,
  }) async {
    if (!rudp.isConnected) {
      throw StateError('RUDP non connecté.');
    }

    print('');
    print('========================================');
    print('             HID TX');
    print('========================================');

    print(
      'Command : '
      '0x${command.toRadixString(16).padLeft(2, '0')}',
    );

    print(
      'Payload : '
      '${payload.length} octets',
    );

    print(
      'Data    : '
      '${HidCodec.hex(payload)}',
    );

    print('========================================');

    await rudp.sendApp(command, payload, reliable: reliable);
  }
}
