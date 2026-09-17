import 'commands/hid_device_dropped.dart';
import 'commands/hid_device_new.dart';

import 'hid_commands.dart';
import 'hid_descriptor.dart';
import 'hid_codec.dart';
import 'hid_sender.dart';
import 'hid_state.dart';

class HidDeviceManager {
  HidDeviceManager({required this.sender, required this.state});

  final HidSender sender;
  final HidState state;

  static const int deviceId = 1;

  static const String deviceName = 'FreeboxRemote';

  static const String deviceSerial = 'FreeboxRemote-001';

  // ============================================================
  // DEVICE_NEW
  // ============================================================

  Future<void> register() async {
    if (!sender.rudp.isConnected) {
      throw StateError('RUDP non connecté.');
    }

    final payload = HidDeviceNew.build(
      deviceId: deviceId,
      deviceName: deviceName,
    );

    print('');
    print('========================================');
    print('       DEVICE_NEW DEBUG');
    print('========================================');

    print('HID header      : 8');
    print('DEVICE_NEW      : 112');

    print(
      'Descriptor      : '
      '${HidDescriptor.data.length}',
    );

    print(
      'Descriptor blob : '
      '${HidCodec.roundUp4(HidDescriptor.data.length)}',
    );

    print('Physical size   : 0');
    print('Strings size    : 0');
    print('Trailing        : 8');
    print('Total payload   : ${payload.length}');

    print('========================================');

    await sender.send(HidCommands.deviceNew, payload, reliable: true);

    print('');
    print('========================================');
    print('          HID DEVICE_NEW ENVOYE');
    print('========================================');
    print('Device ID : $deviceId');
    print('Payload   : ${payload.length} octets');
    print('========================================');

    // IMPORTANT :
    // On ne fait PAS state.register() ici.
    //
    // L'enregistrement est confirmé uniquement lorsque
    // le Player nous renvoie DEVICE_CREATED.
  }

  // ============================================================
  // DEVICE_DROPPED
  // ============================================================

  Future<void> drop() async {
    if (!sender.rudp.isConnected) {
      throw StateError('RUDP non connecté.');
    }

    final payload = HidDeviceDropped.build(deviceId: deviceId);

    await sender.send(HidCommands.deviceDropped, payload, reliable: true);

    state.reset();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    state.reset();
  }
}

