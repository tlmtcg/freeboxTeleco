import '../rudp/rudp_packet.dart';

import 'commands/hid_data.dart';
import 'commands/hid_device_close.dart';
import 'commands/hid_device_dropped.dart';
import 'commands/hid_feature.dart';
import 'commands/hid_grab.dart';
import 'commands/hid_release.dart';
import 'commands/hid_solicit.dart';

import 'hid_codec.dart';
import 'hid_commands.dart';
import 'hid_state.dart';

class HidReceiver {
  HidReceiver({required this.state});

  final HidState state;

  static const int rudpCommandApp = 0x10;

  static const int deviceId = 1;

  // ============================================================
  // PACKET
  // ============================================================

  void processPacket(RudpPacket packet) {
    print('');
    print('========================================');
    print('        HID RECEIVER PACKET');
    print('========================================');
    print(
      'RUDP command : '
      '0x${packet.command.toRadixString(16).padLeft(2, '0')}',
    );
    print(
      'Payload      : '
      '${packet.payload.length} octets',
    );
    print('========================================');

    if (packet.command < rudpCommandApp) {
      print('Paquet ignoré : commande RUDP < 0x10.');
      return;
    }

    final appCommand = packet.command - rudpCommandApp;

    print(
      'HID command  : '
      '0x${appCommand.toRadixString(16).padLeft(2, '0')}',
    );

    switch (appCommand) {
      case HidCommands.deviceDropped:
        _processDeviceDropped(packet);
        break;

      case HidCommands.deviceCreated:
        _processDeviceCreated(packet);
        break;

      case HidCommands.deviceClose:
        _processDeviceClose(packet);
        break;

      case HidCommands.deviceFeature:
        _processFeature(packet);
        break;

      case HidCommands.deviceData:
        _processData(packet);
        break;

      case HidCommands.deviceGrab:
        _processGrab(packet);
        break;

      case HidCommands.deviceRelease:
        _processRelease(packet);
        break;

      case HidCommands.deviceSolicit:
        _processSolicit(packet);
        break;

      default:
        print(
          'HID commande inconnue : '
          '0x${appCommand.toRadixString(16).padLeft(2, '0')}',
        );
        break;
    }
  }

  // ============================================================
  // DEVICE_DROPPED
  // ============================================================

  void _processDeviceDropped(RudpPacket packet) {
    try {
      final receivedDeviceId = HidDeviceDropped.readDeviceId(packet.payload);

      print('');
      print('========================================');
      print('          HID DEVICE_DROPPED');
      print('========================================');
      print('Device ID : $receivedDeviceId');

      if (receivedDeviceId != deviceId) {
        print(
          'DEVICE_DROPPED ignoré : '
          'device ID inattendu.',
        );
        print('========================================');
        return;
      }

      state.reset();

      print('HID supprimé.');
      print('========================================');
    } on FormatException catch (e) {
      print('DEVICE_DROPPED invalide : $e');
    }
  }

  // ============================================================
  // DEVICE_CREATED
  // ============================================================

  void _processDeviceCreated(RudpPacket packet) {
    if (packet.payload.length < 8) {
      print(
        'DEVICE_CREATED invalide : '
        'payload trop court.',
      );
      return;
    }

    final receivedDeviceId = HidCodec.readU32(packet.payload, 0);

    final receivedValue = HidCodec.readU32(packet.payload, 4);

    print('');
    print('========================================');
    print('          DEVICE_CREATED');
    print('========================================');
    print('Device ID : $receivedDeviceId');
    print('Value     : $receivedValue');

    if (receivedDeviceId != deviceId) {
      print(
        'DEVICE_CREATED ignoré : '
        'device ID inattendu.',
      );
      print('========================================');
      return;
    }

    if (state.isRegistered) {
      print('DEVICE_CREATED déjà enregistré.');
      print('Retransmission ignorée.');
      print('========================================');
      return;
    }

    // C'est ICI que le HID devient enregistré.
    state.register();

    print('HID enregistré : true');
    print('========================================');
  }

  // ============================================================
  // DEVICE_CLOSE
  // ============================================================

  void _processDeviceClose(RudpPacket packet) {
    try {
      final receivedDeviceId = HidDeviceClose.readDeviceId(packet.payload);

      print('');
      print('========================================');
      print('           HID DEVICE_CLOSE');
      print('========================================');
      print('Device ID : $receivedDeviceId');

      if (receivedDeviceId != deviceId) {
        print(
          'DEVICE_CLOSE ignoré : '
          'device ID inattendu.',
        );
        print('========================================');
        return;
      }

      state.reset();

      print('HID fermé par le Player.');
      print('========================================');
    } on FormatException catch (e) {
      print('DEVICE_CLOSE invalide : $e');
    }
  }

  // ============================================================
  // FEATURE
  // ============================================================

  void _processFeature(RudpPacket packet) {
    try {
      final receivedDeviceId = HidFeature.readDeviceId(packet.payload);

      final reportId = HidFeature.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'FEATURE ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      final data = HidFeature.readData(packet.payload);

      print('');
      print('========================================');
      print('             HID FEATURE');
      print('========================================');
      print('Device ID : $receivedDeviceId');
      print('Report ID : $reportId');
      print('Data      : ${data.length} octets');
      print('Hex       : ${HidCodec.hex(data)}');
      print('========================================');
    } on FormatException catch (e) {
      print('FEATURE invalide : $e');
    }
  }

  // ============================================================
  // DATA
  // ============================================================

  void _processData(RudpPacket packet) {
    try {
      final receivedDeviceId = HidData.readDeviceId(packet.payload);

      final reportId = HidData.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'DATA ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      final report = HidData.readData(packet.payload);

      print('');
      print('========================================');
      print('               HID DATA');
      print('========================================');
      print('Device ID : $receivedDeviceId');
      print('Report ID : $reportId');
      print('Data      : ${HidCodec.hex(report)}');
      print('========================================');
    } on FormatException catch (e) {
      print('DATA invalide : $e');
    }
  }

  // ============================================================
  // GRAB
  // ============================================================

  void _processGrab(RudpPacket packet) {
    try {
      final receivedDeviceId = HidGrab.readDeviceId(packet.payload);

      final reportId = HidGrab.readReportId(packet.payload);

      print('');
      print('========================================');
      print('             HID GRAB');
      print('========================================');
      print('Device ID : $receivedDeviceId');
      print('Report ID : $reportId');

      if (receivedDeviceId != deviceId) {
        print(
          'GRAB ignoré : '
          'device ID inattendu.',
        );
        print('========================================');
        return;
      }

      if (!HidCommands.isValidReportId(reportId)) {
        print(
          'GRAB ignoré : '
          'Report ID inconnu ($reportId).',
        );
        print('========================================');
        return;
      }

      state.grabReport(reportId);

      print(
        'Report ID enregistré : '
        '$reportId',
      );

      final reports = state.grabbedReportIds.toList()..sort();

      print(
        'Reports HID reçus : '
        '$reports',
      );

      print(
        'HID prêt : '
        '${state.isReady}',
      );

      print('========================================');

      if (state.isReady) {
        _printReady();
      }
    } on FormatException catch (e) {
      print('GRAB invalide : $e');
    }
  }

  // ============================================================
  // RELEASE
  // ============================================================

  void _processRelease(RudpPacket packet) {
    try {
      final receivedDeviceId = HidRelease.readDeviceId(packet.payload);

      final reportId = HidRelease.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'RELEASE ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      state.releaseReport(reportId);

      print('');
      print('========================================');
      print('            HID RELEASE');
      print('========================================');
      print('Device ID : $receivedDeviceId');
      print('Report ID : $reportId');
      print('========================================');
    } on FormatException catch (e) {
      print('RELEASE invalide : $e');
    }
  }

  // ============================================================
  // FEATURE_SOLLICIT
  // ============================================================

  void _processSolicit(RudpPacket packet) {
    try {
      final receivedDeviceId = HidSolicit.readDeviceId(packet.payload);

      final reportId = HidSolicit.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'FEATURE_SOLLICIT ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      print('');
      print('========================================');
      print('        HID FEATURE_SOLLICIT');
      print('========================================');
      print('Device ID : $receivedDeviceId');
      print('Report ID : $reportId');
      print('========================================');
    } on FormatException catch (e) {
      print('FEATURE_SOLLICIT invalide : $e');
    }
  }

  // ============================================================
  // READY
  // ============================================================

  void _printReady() {
    print('');
    print('========================================');
    print('       HID COMPLETEMENT INITIALISE');
    print('========================================');

    print(
      'Unicode : '
      '${state.unicodeGrabbed} '
      '(Report ID ${HidCommands.reportUnicode})',
    );

    print(
      'Keyboard: '
      '${state.keyboardGrabbed} '
      '(Report ID ${HidCommands.reportKeyboard})',
    );

    print(
      'Consumer: '
      '${state.consumerGrabbed} '
      '(Report ID ${HidCommands.reportConsumer})',
    );

    print(
      'System  : '
      '${state.desktopGrabbed} '
      '(Report ID ${HidCommands.reportDesktop})',
    );

    print('========================================');
  }
}
