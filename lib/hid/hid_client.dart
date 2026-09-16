import 'dart:typed_data';

import '../rudp/rudp_client.dart';
import '../rudp/rudp_packet.dart';

import 'hid_commands.dart';
import 'hid_codec.dart';
import 'hid_descriptor.dart';
import 'hid_device.dart';

import 'commands/hid_data.dart';
import 'commands/hid_device_close.dart';
import 'commands/hid_device_dropped.dart';
import 'commands/hid_device_new.dart';
import 'commands/hid_feature.dart';
import 'commands/hid_grab.dart';
import 'commands/hid_release.dart';
import 'commands/hid_solicit.dart';

class HidClient {
  HidClient({required this.rudp});

  final RudpClient rudp;

  // ============================================================
  // RUDP
  // ============================================================

  static const int rudpCommandApp = 0x10;

  // ============================================================
  // DEVICE
  // ============================================================

  static const int deviceId = 1;

  static const String deviceName = 'FreeboxRemote';

  static const String deviceSerial = 'FreeboxRemote-001';

  // ============================================================
  // ETAT
  // ============================================================

  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  final Set<int> _grabbedReportIds = <int>{};

  // ============================================================
  // HID DEVICE
  // ============================================================

  HidDevice get device => HidDevice.freeboxRemote;

  // ============================================================
  // ETAT HID
  // ============================================================

  bool get isReady {
    return _isRegistered &&
        keyboardGrabbed &&
        consumerGrabbed;
  }

  bool get unicodeGrabbed {
    return _grabbedReportIds.contains(
      HidCommands.reportUnicode,
    );
  }

  bool get keyboardGrabbed {
    return _grabbedReportIds.contains(
      HidCommands.reportKeyboard,
    );
  }

  bool get consumerGrabbed {
    return _grabbedReportIds.contains(
      HidCommands.reportConsumer,
    );
  }

  bool get desktopGrabbed {
    return _grabbedReportIds.contains(
      HidCommands.reportDesktop,
    );
  }

  Set<int> get grabbedReportIds {
    return Set<int>.unmodifiable(
      _grabbedReportIds,
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _isRegistered = false;
    _grabbedReportIds.clear();
  }

  // ============================================================
  // DEVICE_NEW
  //
  // Client -> Player
  // ============================================================

  Future<void> sendDeviceNew() async {
    _checkConnected();

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

    await _sendHidCommand(
      HidCommands.deviceNew,
      payload,
      reliable: true,
    );

    print('');
    print('========================================');
    print('          HID DEVICE_NEW ENVOYE');
    print('========================================');
    print('Device ID : $deviceId');
    print('Payload   : ${payload.length} octets');
    print('========================================');
  }

  // ============================================================
  // DEVICE_DROPPED
  //
  // Client -> Player
  // ============================================================

  Future<void> sendDeviceDropped() async {
    _checkConnected();

    final payload = HidDeviceDropped.build(
      deviceId: deviceId,
    );

    await _sendHidCommand(
      HidCommands.deviceDropped,
      payload,
      reliable: true,
    );

    reset();
  }

  // ============================================================
  // DEVICE_CLOSE
  //
  // Player -> Client
  // ============================================================
  //
  // Il n'existe pas de sendDeviceClose().
  //

  // ============================================================
  // FEATURE
  //
  // Bidirectionnel
  // ============================================================

  Future<void> sendFeature(
    int reportId,
    List<int> data,
  ) async {
    _checkHidReadyForReport(reportId);

    final payload = HidFeature.build(
      deviceId: deviceId,
      reportId: reportId,
      data: data,
    );

    await _sendHidCommand(
      HidCommands.deviceFeature,
      payload,
      reliable: true,
    );
  }

  // ============================================================
  // FEATURE_SOLLICIT
  //
  // Player -> Client
  // ============================================================
  //
  // Il n'existe pas de sendFeatureSolicit().
  //

  // ============================================================
  // GRAB
  //
  // Player -> Client
  // ============================================================
  //
  // Il n'existe pas de sendGrab().
  //

  // ============================================================
  // RELEASE
  //
  // Player -> Client
  // ============================================================
  //
  // Il n'existe pas de sendRelease().
  //

  // ============================================================
  // RECEPTION RUDP / HID
  // ============================================================

  void processPacket(RudpPacket packet) {
    if (packet.command < rudpCommandApp) {
      return;
    }

    final appCommand = packet.command - rudpCommandApp;

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
  //
  // Client -> Player / notification reçue
  // ============================================================

  void _processDeviceDropped(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidDeviceDropped.readDeviceId(packet.payload);

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

      reset();

      print('HID supprimé.');
      print('========================================');
    } on FormatException catch (e) {
      print('DEVICE_DROPPED invalide : $e');
    }
  }

  // ============================================================
  // DEVICE_CREATED
  //
  // Player -> Client
  //
  // Pas de fichier dédié pour le moment.
  // ============================================================

  void _processDeviceCreated(RudpPacket packet) {
    if (packet.payload.length < 8) {
      print(
        'DEVICE_CREATED invalide : '
        'payload trop court.',
      );
      return;
    }

    final receivedDeviceId = HidCodec.readU32(
      packet.payload,
      0,
    );

    final receivedValue = HidCodec.readU32(
      packet.payload,
      4,
    );

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

    if (_isRegistered) {
      print('DEVICE_CREATED déjà enregistré.');
      print('Retransmission ignorée.');
      print('========================================');
      return;
    }

    _isRegistered = true;

    print('HID enregistré : true');
    print('========================================');
  }

  // ============================================================
  // DEVICE_CLOSE
  //
  // Player -> Client
  // ============================================================

  void _processDeviceClose(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidDeviceClose.readDeviceId(packet.payload);

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

      reset();

      print('HID fermé par le Player.');
      print('========================================');
    } on FormatException catch (e) {
      print('DEVICE_CLOSE invalide : $e');
    }
  }

  // ============================================================
  // FEATURE
  //
  // Player -> Client
  // ============================================================

  void _processFeature(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidFeature.readDeviceId(packet.payload);

      final reportId =
          HidFeature.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'FEATURE ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      final data =
          HidFeature.readData(packet.payload);

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
  //
  // Player -> Client
  // ============================================================

  void _processData(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidData.readDeviceId(packet.payload);

      final reportId =
          HidData.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'DATA ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      final report =
          HidData.readData(packet.payload);

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
  //
  // Player -> Client
  // ============================================================

  void _processGrab(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidGrab.readDeviceId(packet.payload);

      final reportId =
          HidGrab.readReportId(packet.payload);

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

      _grabbedReportIds.add(reportId);

      print(
        'Report ID enregistré : '
        '$reportId',
      );

      final reports =
          _grabbedReportIds.toList()..sort();

      print(
        'Reports HID reçus : '
        '$reports',
      );

      print(
        'HID prêt : '
        '$isReady',
      );

      print('========================================');

      if (isReady) {
        _printReady();
      }
    } on FormatException catch (e) {
      print('GRAB invalide : $e');
    }
  }

  // ============================================================
  // RELEASE
  //
  // Player -> Client
  // ============================================================

  void _processRelease(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidRelease.readDeviceId(packet.payload);

      final reportId =
          HidRelease.readReportId(packet.payload);

      if (receivedDeviceId != deviceId) {
        print(
          'RELEASE ignoré : '
          'device ID inattendu.',
        );
        return;
      }

      _grabbedReportIds.remove(reportId);

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
  //
  // Player -> Client
  // ============================================================

  void _processSolicit(RudpPacket packet) {
    try {
      final receivedDeviceId =
          HidSolicit.readDeviceId(packet.payload);

      final reportId =
          HidSolicit.readReportId(packet.payload);

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
  // HID DATA
  //
  // Client -> Player
  // ============================================================

  Future<void> _sendData(
    int reportId,
    List<int> report,
  ) async {
    _checkConnected();

    if (!_isRegistered) {
      throw StateError('HID non enregistré.');
    }

    _validateReportId(reportId);

    if (!_grabbedReportIds.contains(reportId)) {
      throw StateError(
        'Report HID $reportId non disponible.',
      );
    }

    if (report.length != 2) {
      throw ArgumentError(
        'Un report HID doit contenir '
        'exactement 2 octets.',
      );
    }

    final payload = HidData.build(
      deviceId: deviceId,
      reportId: reportId,
      data: report,
    );

    await _sendHidCommand(
      HidCommands.deviceData,
      payload,
      reliable: true,
    );
  }

  // ============================================================
  // KEYBOARD
  // ============================================================

  Future<void> sendKeyboard(int keyCode) async {
    final report = <int>[
      keyCode & 0xFF,
      0x00,
    ];

    await _sendData(
      HidCommands.reportKeyboard,
      report,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await _sendData(
      HidCommands.reportKeyboard,
      const <int>[
        0x00,
        0x00,
      ],
    );
  }

  // ============================================================
  // CONSUMER
  // ============================================================

  Future<void> sendConsumer(int usage) async {
    final report = Uint8List(2);

    final data = ByteData.sublistView(report);

    data.setUint16(
      0,
      usage,
      Endian.little,
    );

    await _sendData(
      HidCommands.reportConsumer,
      report,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await _sendData(
      HidCommands.reportConsumer,
      const <int>[
        0x00,
        0x00,
      ],
    );
  }

  // ============================================================
  // DESKTOP / SYSTEM
  // ============================================================

  Future<void> sendDesktop(int usage) async {
    final report = Uint8List(2);

    final data = ByteData.sublistView(report);

    data.setUint16(
      0,
      usage,
      Endian.little,
    );

    await _sendData(
      HidCommands.reportDesktop,
      report,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    await _sendData(
      HidCommands.reportDesktop,
      const <int>[
        0x00,
        0x00,
      ],
    );
  }

  // ============================================================
  // ENVOI COMMANDE HID GENERIQUE
  // ============================================================

  Future<void> _sendHidCommand(
    int command,
    List<int> payload, {
    required bool reliable,
  }) async {
    _checkConnected();

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

    await rudp.sendApp(
      command,
      payload,
      reliable: reliable,
    );
  }

  // ============================================================
  // AFFICHAGE HID READY
  // ============================================================

  void _printReady() {
    print('');
    print('========================================');
    print('       HID COMPLETEMENT INITIALISE');
    print('========================================');

    print(
      'Unicode : '
      '$unicodeGrabbed '
      '(Report ID ${HidCommands.reportUnicode})',
    );

    print(
      'Keyboard: '
      '$keyboardGrabbed '
      '(Report ID ${HidCommands.reportKeyboard})',
    );

    print(
      'Consumer: '
      '$consumerGrabbed '
      '(Report ID ${HidCommands.reportConsumer})',
    );

    print(
      'System  : '
      '$desktopGrabbed '
      '(Report ID ${HidCommands.reportDesktop})',
    );

    print('========================================');
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  void _checkConnected() {
    if (!rudp.isConnected) {
      throw StateError(
        'RUDP non connecté.',
      );
    }
  }

  void _checkHidReadyForReport(
    int reportId,
  ) {
    _checkConnected();

    if (!_isRegistered) {
      throw StateError(
        'HID non enregistré.',
      );
    }

    _validateReportId(reportId);

    if (!_grabbedReportIds.contains(reportId)) {
      throw StateError(
        'Report HID $reportId non disponible.',
      );
    }
  }

  static void _validateReportId(
    int reportId,
  ) {
    if (!HidCommands.isValidReportId(reportId)) {
      throw ArgumentError(
        'Report HID invalide : $reportId',
      );
    }
  }
}

// import 'dart:typed_data';

// import '../rudp/rudp_client.dart';
// import '../rudp/rudp_packet.dart';

// import 'hid_commands.dart';
// import 'hid_codec.dart';
// import 'hid_device.dart';

// import 'commands/hid_data.dart';
// import 'commands/hid_device_close.dart';
// import 'commands/hid_device_dropped.dart';
// import 'commands/hid_device_new.dart';
// import 'commands/hid_feature.dart';
// import 'commands/hid_grab.dart';
// import 'commands/hid_release.dart';
// import 'commands/hid_solicit.dart';

// class HidClient {
//   HidClient({required this.rudp});

//   final RudpClient rudp;

//   // ============================================================
//   // RUDP
//   // ============================================================

//   static const int rudpCommandApp = 0x10;

//   // ============================================================
//   // DEVICE
//   // ============================================================

//   static const int deviceId = 1;

//   static const String deviceName = 'FreeboxRemote';

//   static const String deviceSerial = 'FreeboxRemote-001';

//   // ============================================================
//   // ETAT
//   // ============================================================

//   bool _isRegistered = false;

//   bool get isRegistered => _isRegistered;

//   final Set<int> _grabbedReportIds = <int>{};

//   // ============================================================
//   // HID DEVICE
//   // ============================================================

//   HidDevice get device => HidDevice.freeboxRemote;

//   // ============================================================
//   // ETAT HID
//   // ============================================================

//   bool get isReady {
//     return _isRegistered &&
//         _grabbedReportIds.contains(HidCommands.reportKeyboard) &&
//         _grabbedReportIds.contains(HidCommands.reportConsumer);
//   }

//   bool get unicodeGrabbed {
//     return _grabbedReportIds.contains(HidCommands.reportUnicode);
//   }

//   bool get keyboardGrabbed {
//     return _grabbedReportIds.contains(HidCommands.reportKeyboard);
//   }

//   bool get consumerGrabbed {
//     return _grabbedReportIds.contains(HidCommands.reportConsumer);
//   }

//   bool get desktopGrabbed {
//     return _grabbedReportIds.contains(HidCommands.reportDesktop);
//   }

//   Set<int> get grabbedReportIds {
//     return Set<int>.unmodifiable(_grabbedReportIds);
//   }

//   // ============================================================
//   // RESET
//   // ============================================================

//   void reset() {
//     _isRegistered = false;
//     _grabbedReportIds.clear();
//   }

//   // ============================================================
//   // DEVICE_NEW
//   //
//   // Client -> Player
//   // ============================================================

//   Future<void> sendDeviceNew() async {
//     _checkConnected();

//     final payload = HidDeviceNew.build(
//       deviceId: deviceId,
//       deviceName: deviceName,
//     );

//     print('');
//     print('========================================');
//     print('       DEVICE_NEW DEBUG');
//     print('========================================');

//     print('HID header      : 8');
//     print('DEVICE_NEW      : 112');
//     print(
//       'Descriptor      : '
//       '${payload.length - 8 - 112 - 8}',
//     );
//     print(
//       'Descriptor blob : '
//       '${payload.length - 8 - 112 - 8}',
//     );
//     print('Physical size   : 0');
//     print('Strings size    : 0');
//     print('Trailing        : 8');
//     print('Total payload   : ${payload.length}');

//     print('========================================');

//     await _sendHidCommand(HidCommands.deviceNew, payload, reliable: true);

//     print('');
//     print('========================================');
//     print('          HID DEVICE_NEW ENVOYE');
//     print('========================================');
//     print('Device ID : $deviceId');
//     print('Payload   : ${payload.length} octets');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_DROPPED
//   //
//   // Client -> Player
//   // ============================================================

//   Future<void> sendDeviceDropped() async {
//     _checkConnected();

//     final payload = HidDeviceDropped.build(deviceId: deviceId);

//     await _sendHidCommand(HidCommands.deviceDropped, payload, reliable: true);

//     reset();
//   }

//   // ============================================================
//   // DEVICE_CLOSE
//   //
//   // Player -> Client
//   //
//   // Il n'existe pas de sendDeviceClose().
//   // ============================================================

//   // ============================================================
//   // FEATURE
//   //
//   // Bidirectionnel
//   // ============================================================

//   Future<void> sendFeature(int reportId, List<int> data) async {
//     _checkHidReadyForReport(reportId);

//     final payload = HidFeature.build(
//       deviceId: deviceId,
//       reportId: reportId,
//       data: data,
//     );

//     await _sendHidCommand(HidCommands.deviceFeature, payload, reliable: true);
//   }

//   // ============================================================
//   // FEATURE_SOLLICIT
//   //
//   // Player -> Client
//   //
//   // Il n'existe pas de sendFeatureSolicit().
//   // ============================================================

//   // ============================================================
//   // GRAB
//   //
//   // Player -> Client
//   //
//   // Il n'existe pas de sendGrab().
//   // ============================================================

//   // ============================================================
//   // RELEASE
//   //
//   // Player -> Client
//   //
//   // Il n'existe pas de sendRelease().
//   // ============================================================

//   // ============================================================
//   // RECEPTION RUDP / HID
//   // ============================================================

//   void processPacket(RudpPacket packet) {
//     if (packet.command < rudpCommandApp) {
//       return;
//     }

//     final appCommand = packet.command - rudpCommandApp;

//     switch (appCommand) {
//       case HidCommands.deviceDropped:
//         _processDeviceDropped(packet);
//         break;

//       case HidCommands.deviceCreated:
//         _processDeviceCreated(packet);
//         break;

//       case HidCommands.deviceClose:
//         _processDeviceClose(packet);
//         break;

//       case HidCommands.deviceFeature:
//         _processFeature(packet);
//         break;

//       case HidCommands.deviceData:
//         _processData(packet);
//         break;

//       case HidCommands.deviceGrab:
//         _processGrab(packet);
//         break;

//       case HidCommands.deviceRelease:
//         _processRelease(packet);
//         break;

//       case HidCommands.deviceSolicit:
//         _processSolicit(packet);
//         break;

//       default:
//         print(
//           'HID commande inconnue : '
//           '0x${appCommand.toRadixString(16).padLeft(2, '0')}',
//         );
//         break;
//     }
//   }

//   // ============================================================
//   // DEVICE_DROPPED
//   //
//   // Le C FOILS utilise le header complet de 8 octets.
//   // ============================================================

//   void _processDeviceDropped(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'DEVICE_DROPPED invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidDeviceDropped.readDeviceId(packet.payload);

//     print('');
//     print('========================================');
//     print('          HID DEVICE_DROPPED');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_DROPPED ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     reset();

//     print('HID supprimé.');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_CREATED
//   //
//   // Player -> Client
//   //
//   // Pas de fichier dédié : ce n'est pas une des commandes
//   // demandées et son traitement reste spécifique à HidClient.
//   // ============================================================

//   void _processDeviceCreated(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'DEVICE_CREATED invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidCodec.readU32(packet.payload, 0);

//     final receivedValue = HidCodec.readU32(packet.payload, 4);

//     print('');
//     print('========================================');
//     print('          DEVICE_CREATED');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Value     : $receivedValue');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_CREATED ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     if (_isRegistered) {
//       print('DEVICE_CREATED déjà enregistré.');
//       print('Retransmission ignorée.');
//       print('========================================');
//       return;
//     }

//     _isRegistered = true;

//     print('HID enregistré : true');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_CLOSE
//   //
//   // Player -> Client
//   // ============================================================

//   void _processDeviceClose(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'DEVICE_CLOSE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidDeviceClose.readDeviceId(packet.payload);

//     print('');
//     print('========================================');
//     print('           HID DEVICE_CLOSE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_CLOSE ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     reset();

//     print('HID fermé par le Player.');
//     print('========================================');
//   }

//   // ============================================================
//   // FEATURE
//   //
//   // Player -> Client
//   // ============================================================

//   void _processFeature(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'FEATURE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidFeature.readDeviceId(packet.payload);

//     final reportId = HidFeature.readReportId(packet.payload);

//     if (receivedDeviceId != deviceId) {
//       print(
//         'FEATURE ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     final data = HidFeature.readData(packet.payload);

//     print('');
//     print('========================================');
//     print('             HID FEATURE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print(
//       'Data      : '
//       '${data.length} octets',
//     );
//     print(
//       'Hex       : '
//       '${HidCodec.hex(data)}',
//     );
//     print('========================================');
//   }

//   // ============================================================
//   // DATA
//   //
//   // Player -> Client
//   // ============================================================

//   void _processData(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'DATA invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidData.readDeviceId(packet.payload);

//     final reportId = HidData.readReportId(packet.payload);

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DATA ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     final report = HidData.readData(packet.payload);

//     print('');
//     print('========================================');
//     print('               HID DATA');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print(
//       'Data      : '
//       '${HidCodec.hex(report)}',
//     );
//     print('========================================');
//   }

//   // ============================================================
//   // GRAB
//   //
//   // Player -> Client
//   // ============================================================

//   void _processGrab(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'GRAB invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidGrab.readDeviceId(packet.payload);

//     final reportId = HidGrab.readReportId(packet.payload);

//     print('');
//     print('========================================');
//     print('             HID GRAB');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'GRAB ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     switch (reportId) {
//       case HidCommands.reportUnicode:
//       case HidCommands.reportKeyboard:
//       case HidCommands.reportConsumer:
//       case HidCommands.reportDesktop:
//         _grabbedReportIds.add(reportId);

//         print(
//           'Report ID enregistré : '
//           '$reportId',
//         );

//         final reports = _grabbedReportIds.toList()..sort();

//         print(
//           'Reports HID reçus : '
//           '$reports',
//         );

//         print(
//           'HID prêt : '
//           '$isReady',
//         );
//         break;

//       default:
//         print(
//           'GRAB ignoré : '
//           'Report ID inconnu ($reportId).',
//         );
//         break;
//     }

//     print('========================================');

//     if (isReady) {
//       _printReady();
//     }
//   }

//   // ============================================================
//   // RELEASE
//   //
//   // Player -> Client
//   // ============================================================

//   void _processRelease(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'RELEASE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidRelease.readDeviceId(packet.payload);

//     final reportId = HidRelease.readReportId(packet.payload);

//     if (receivedDeviceId != deviceId) {
//       print(
//         'RELEASE ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     _grabbedReportIds.remove(reportId);

//     print('');
//     print('========================================');
//     print('            HID RELEASE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print('========================================');
//   }

//   // ============================================================
//   // FEATURE_SOLLICIT
//   //
//   // Player -> Client
//   // ============================================================

//   void _processSolicit(RudpPacket packet) {
//     if (packet.payload.length < 8) {
//       print(
//         'FEATURE_SOLLICIT invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId = HidSolicit.readDeviceId(packet.payload);

//     final reportId = HidSolicit.readReportId(packet.payload);

//     if (receivedDeviceId != deviceId) {
//       print(
//         'FEATURE_SOLLICIT ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     print('');
//     print('========================================');
//     print('        HID FEATURE_SOLLICIT');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print('========================================');
//   }

//   // ============================================================
//   // HID DATA
//   //
//   // Client -> Player
//   // ============================================================

//   Future<void> _sendData(int reportId, List<int> report) async {
//     if (!rudp.isConnected) {
//       throw StateError('RUDP non connecté.');
//     }

//     if (!_isRegistered) {
//       throw StateError('HID non enregistré.');
//     }

//     if (!_grabbedReportIds.contains(reportId)) {
//       throw StateError('Report HID $reportId non disponible.');
//     }

//     if (report.length != 2) {
//       throw ArgumentError(
//         'Un report HID doit contenir '
//         'exactement 2 octets.',
//       );
//     }

//     final payload = HidData.build(
//       deviceId: deviceId,
//       reportId: reportId,
//       data: report,
//     );

//     await _sendHidCommand(HidCommands.deviceData, payload, reliable: true);
//   }

//   // ============================================================
//   // KEYBOARD
//   // ============================================================

//   Future<void> sendKeyboard(int keyCode) async {
//     final report = <int>[keyCode & 0xFF, 0x00];

//     await _sendData(HidCommands.reportKeyboard, report);

//     await Future<void>.delayed(const Duration(milliseconds: 100));

//     await _sendData(HidCommands.reportKeyboard, const <int>[0x00, 0x00]);
//   }

//   // ============================================================
//   // CONSUMER
//   // ============================================================

//   Future<void> sendConsumer(int usage) async {
//     final report = Uint8List(2);

//     final data = ByteData.sublistView(report);

//     data.setUint16(0, usage, Endian.little);

//     await _sendData(HidCommands.reportConsumer, report);

//     await Future<void>.delayed(const Duration(milliseconds: 100));

//     await _sendData(HidCommands.reportConsumer, const <int>[0x00, 0x00]);
//   }

//   // ============================================================
//   // DESKTOP / SYSTEM
//   // ============================================================

//   Future<void> sendDesktop(int usage) async {
//     final report = Uint8List(2);

//     final data = ByteData.sublistView(report);

//     data.setUint16(0, usage, Endian.little);

//     await _sendData(HidCommands.reportDesktop, report);

//     await Future<void>.delayed(const Duration(milliseconds: 100));

//     await _sendData(HidCommands.reportDesktop, const <int>[0x00, 0x00]);
//   }

//   // ============================================================
//   // ENVOI COMMANDE HID GENERIQUE
//   // ============================================================

//   Future<void> _sendHidCommand(
//     int command,
//     List<int> payload, {
//     required bool reliable,
//   }) async {
//     _checkConnected();

//     print('');
//     print('========================================');
//     print('             HID TX');
//     print('========================================');

//     print(
//       'Command : '
//       '0x${command.toRadixString(16).padLeft(2, '0')}',
//     );

//     print(
//       'Payload : '
//       '${payload.length} octets',
//     );

//     print(
//       'Data    : '
//       '${HidCodec.hex(payload)}',
//     );

//     print('========================================');

//     await rudp.sendApp(command, payload, reliable: reliable);
//   }

//   // ============================================================
//   // AFFICHAGE HID READY
//   // ============================================================

//   void _printReady() {
//     print('');
//     print('========================================');
//     print('       HID COMPLETEMENT INITIALISE');
//     print('========================================');

//     print(
//       'Unicode : '
//       '$unicodeGrabbed '
//       '(Report ID ${HidCommands.reportUnicode})',
//     );

//     print(
//       'Keyboard: '
//       '$keyboardGrabbed '
//       '(Report ID ${HidCommands.reportKeyboard})',
//     );

//     print(
//       'Consumer: '
//       '$consumerGrabbed '
//       '(Report ID ${HidCommands.reportConsumer})',
//     );

//     print(
//       'System  : '
//       '$desktopGrabbed '
//       '(Report ID ${HidCommands.reportDesktop})',
//     );

//     print('========================================');
//   }

//   // ============================================================
//   // VALIDATION
//   // ============================================================

//   void _checkConnected() {
//     if (!rudp.isConnected) {
//       throw StateError('RUDP non connecté.');
//     }
//   }

//   void _checkHidReadyForReport(int reportId) {
//     _checkConnected();

//     if (!_isRegistered) {
//       throw StateError('HID non enregistré.');
//     }

//     _validateReportId(reportId);

//     if (!_grabbedReportIds.contains(reportId)) {
//       throw StateError('Report HID $reportId non disponible.');
//     }
//   }

//   static void _validateReportId(int reportId) {
//     if (!HidCommands.isValidReportId(reportId)) {
//       throw ArgumentError('Report HID invalide : $reportId');
//     }
//   }
// }

// import 'dart:typed_data';

// import '../rudp/rudp_client.dart';
// import '../rudp/rudp_packet.dart';
// import 'hid_commands.dart';
// import 'hid_codec.dart';
// import 'hid_descriptor.dart';
// import 'hid_device.dart';

// class HidClient {
//   HidClient({required this.rudp});

//   final RudpClient rudp;

//   // ============================================================
//   // RUDP
//   // ============================================================

//   static const int rudpCommandApp = 0x10;

//   // ============================================================
//   // DEVICE
//   // ============================================================

//   static const int deviceId = 1;

//   static const String deviceName = 'FreeboxRemote';

//   static const String deviceSerial = 'FreeboxRemote-001';

//   // ============================================================
//   // ETAT
//   // ============================================================

//   bool _isRegistered = false;

//   bool get isRegistered => _isRegistered;

//   final Set<int> _grabbedReportIds = <int>{};

//   // ============================================================
//   // HID DEVICE
//   // ============================================================

//   HidDevice get device => HidDevice.freeboxRemote;

//   // ============================================================
//   // ETAT HID
//   // ============================================================

//   bool get isReady {
//     return _isRegistered &&
//         _grabbedReportIds.contains(
//           HidCommands.reportKeyboard,
//         ) &&
//         _grabbedReportIds.contains(
//           HidCommands.reportConsumer,
//         );
//   }

//   bool get unicodeGrabbed {
//     return _grabbedReportIds.contains(
//       HidCommands.reportUnicode,
//     );
//   }

//   bool get keyboardGrabbed {
//     return _grabbedReportIds.contains(
//       HidCommands.reportKeyboard,
//     );
//   }

//   bool get consumerGrabbed {
//     return _grabbedReportIds.contains(
//       HidCommands.reportConsumer,
//     );
//   }

//   bool get desktopGrabbed {
//     return _grabbedReportIds.contains(
//       HidCommands.reportDesktop,
//     );
//   }

//   Set<int> get grabbedReportIds {
//     return Set<int>.unmodifiable(
//       _grabbedReportIds,
//     );
//   }

//   // ============================================================
//   // RESET
//   // ============================================================

//   void reset() {
//     _isRegistered = false;
//     _grabbedReportIds.clear();
//   }

//   // ============================================================
//   // DEVICE_NEW
//   // ============================================================

//   Future<void> sendDeviceNew() async {
//     if (!rudp.isConnected) {
//       throw StateError('RUDP non connecté.');
//     }

//     final payload =
//         HidDescriptor.buildDeviceNewPayload(
//       deviceId: deviceId,
//       deviceName: deviceName,
//     );

//     print('');
//     print('========================================');
//     print('       DEVICE_NEW DEBUG');
//     print('========================================');

//     print('HID header      : 8');
//     print('DEVICE_NEW      : 112');
//     print(
//       'Descriptor      : '
//       '${HidDescriptor.data.length}',
//     );
//     print(
//       'Descriptor blob : '
//       '${HidCodec.roundUp4(HidDescriptor.data.length)}',
//     );
//     print('Physical size   : 0');
//     print('Strings size    : 0');
//     print('Trailing        : 8');
//     print('Total payload   : ${payload.length}');

//     print('========================================');

//     await rudp.sendApp(
//       HidCommands.deviceNew,
//       payload,
//       reliable: true,
//     );

//     print('');
//     print('========================================');
//     print('          HID DEVICE_NEW ENVOYE');
//     print('========================================');
//     print('Device ID : $deviceId');
//     print('Payload   : ${payload.length} octets');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_DROPPED
//   // ============================================================

//   Future<void> sendDeviceDropped() async {
//     _checkConnected();

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceDropped,
//       payload,
//       reliable: true,
//     );

//     reset();
//   }

//   // ============================================================
//   // DEVICE_CLOSE
//   // ============================================================

//   Future<void> sendDeviceClose() async {
//     _checkConnected();

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceClose,
//       payload,
//       reliable: true,
//     );

//     reset();
//   }

//   // ============================================================
//   // FEATURE
//   // ============================================================

//   Future<void> sendFeature(
//     int reportId,
//     List<int> data,
//   ) async {
//     _checkHidReadyForReport(reportId);

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//       ...HidCodec.u32(reportId),
//       ...data,
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceFeature,
//       payload,
//       reliable: true,
//     );
//   }

//   // ============================================================
//   // FEATURE_SOLLICIT
//   // ============================================================

//   Future<void> sendFeatureSolicit(
//     int reportId,
//   ) async {
//     _checkConnected();

//     _validateReportId(reportId);

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//       ...HidCodec.u32(reportId),
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceSolicit,
//       payload,
//       reliable: true,
//     );
//   }

//   // ============================================================
//   // GRAB
//   // ============================================================

//   Future<void> sendGrab(
//     int reportId,
//   ) async {
//     _checkConnected();

//     _validateReportId(reportId);

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//       ...HidCodec.u32(reportId),
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceGrab,
//       payload,
//       reliable: true,
//     );
//   }

//   // ============================================================
//   // RELEASE
//   // ============================================================

//   Future<void> sendRelease(
//     int reportId,
//   ) async {
//     _checkConnected();

//     _validateReportId(reportId);

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//       ...HidCodec.u32(reportId),
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceRelease,
//       payload,
//       reliable: true,
//     );

//     _grabbedReportIds.remove(reportId);
//   }

//   // ============================================================
//   // RECEPTION RUDP / HID
//   // ============================================================

//   void processPacket(RudpPacket packet) {
//     if (packet.command < rudpCommandApp) {
//       return;
//     }

//     final appCommand =
//         packet.command - rudpCommandApp;

//     switch (appCommand) {
//       case HidCommands.deviceDropped:
//         _processDeviceDropped(packet);
//         break;

//       case HidCommands.deviceCreated:
//         _processDeviceCreated(packet);
//         break;

//       case HidCommands.deviceClose:
//         _processDeviceClose(packet);
//         break;

//       case HidCommands.deviceFeature:
//         _processFeature(packet);
//         break;

//       case HidCommands.deviceData:
//         _processData(packet);
//         break;

//       case HidCommands.deviceGrab:
//         _processGrab(packet);
//         break;

//       case HidCommands.deviceRelease:
//         _processRelease(packet);
//         break;

//       case HidCommands.deviceSolicit:
//         _processSolicit(packet);
//         break;

//       default:
//         print(
//           'HID commande inconnue : '
//           '0x${appCommand.toRadixString(16).padLeft(2, '0')}',
//         );
//         break;
//     }
//   }

//   // ============================================================
//   // DEVICE_DROPPED
//   // ============================================================

//   void _processDeviceDropped(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 4) {
//       print(
//         'DEVICE_DROPPED invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     print('');
//     print('========================================');
//     print('          HID DEVICE_DROPPED');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_DROPPED ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     reset();

//     print('HID supprimé.');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_CREATED
//   // ============================================================

//   void _processDeviceCreated(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'DEVICE_CREATED invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final receivedValue =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     print('');
//     print('========================================');
//     print('          DEVICE_CREATED');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Value     : $receivedValue');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_CREATED ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     if (_isRegistered) {
//       print('DEVICE_CREATED déjà enregistré.');
//       print('Retransmission ignorée.');
//       print('========================================');
//       return;
//     }

//     _isRegistered = true;

//     print('HID enregistré : true');
//     print('========================================');
//   }

//   // ============================================================
//   // DEVICE_CLOSE
//   // ============================================================

//   void _processDeviceClose(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 4) {
//       print(
//         'DEVICE_CLOSE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     print('');
//     print('========================================');
//     print('           HID DEVICE_CLOSE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DEVICE_CLOSE ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     reset();

//     print('HID fermé par le Player.');
//     print('========================================');
//   }

//   // ============================================================
//   // FEATURE
//   // ============================================================

//   void _processFeature(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'FEATURE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final reportId =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     if (receivedDeviceId != deviceId) {
//       print(
//         'FEATURE ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     final data =
//         packet.payload.sublist(8);

//     print('');
//     print('========================================');
//     print('             HID FEATURE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print(
//       'Data      : '
//       '${data.length} octets',
//     );
//     print(
//       'Hex       : '
//       '${HidCodec.hex(data)}',
//     );
//     print('========================================');
//   }

//   // ============================================================
//   // DATA
//   // ============================================================

//   void _processData(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'DATA invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final reportId =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     if (receivedDeviceId != deviceId) {
//       print(
//         'DATA ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     final report =
//         packet.payload.sublist(8);

//     print('');
//     print('========================================');
//     print('               HID DATA');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print(
//       'Data      : '
//       '${HidCodec.hex(report)}',
//     );
//     print('========================================');
//   }

//   // ============================================================
//   // GRAB
//   // ============================================================

//   void _processGrab(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'GRAB invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final reportId =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     print('');
//     print('========================================');
//     print('             HID GRAB');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');

//     if (receivedDeviceId != deviceId) {
//       print(
//         'GRAB ignoré : '
//         'device ID inattendu.',
//       );
//       print('========================================');
//       return;
//     }

//     switch (reportId) {
//       case HidCommands.reportUnicode:
//       case HidCommands.reportKeyboard:
//       case HidCommands.reportConsumer:
//       case HidCommands.reportDesktop:
//         _grabbedReportIds.add(reportId);

//         print(
//           'Report ID enregistré : '
//           '$reportId',
//         );

//         final reports =
//             _grabbedReportIds.toList()..sort();

//         print(
//           'Reports HID reçus : '
//           '$reports',
//         );

//         print(
//           'HID prêt : '
//           '$isReady',
//         );
//         break;

//       default:
//         print(
//           'GRAB ignoré : '
//           'Report ID inconnu ($reportId).',
//         );
//         break;
//     }

//     print('========================================');

//     if (isReady) {
//       _printReady();
//     }
//   }

//   // ============================================================
//   // RELEASE
//   // ============================================================

//   void _processRelease(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'RELEASE invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final reportId =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     if (receivedDeviceId != deviceId) {
//       print(
//         'RELEASE ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     _grabbedReportIds.remove(reportId);

//     print('');
//     print('========================================');
//     print('            HID RELEASE');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print('========================================');
//   }

//   // ============================================================
//   // FEATURE_SOLLICIT
//   // ============================================================

//   void _processSolicit(
//     RudpPacket packet,
//   ) {
//     if (packet.payload.length < 8) {
//       print(
//         'FEATURE_SOLLICIT invalide : '
//         'payload trop court.',
//       );
//       return;
//     }

//     final receivedDeviceId =
//         HidCodec.readU32(
//       packet.payload,
//       0,
//     );

//     final reportId =
//         HidCodec.readU32(
//       packet.payload,
//       4,
//     );

//     if (receivedDeviceId != deviceId) {
//       print(
//         'FEATURE_SOLLICIT ignoré : '
//         'device ID inattendu.',
//       );
//       return;
//     }

//     print('');
//     print('========================================');
//     print('        HID FEATURE_SOLLICIT');
//     print('========================================');
//     print('Device ID : $receivedDeviceId');
//     print('Report ID : $reportId');
//     print('========================================');
//   }

//   // ============================================================
//   // HID DATA
//   // ============================================================

//   Future<void> _sendData(
//     int reportId,
//     List<int> report,
//   ) async {
//     if (!rudp.isConnected) {
//       throw StateError(
//         'RUDP non connecté.',
//       );
//     }

//     if (!_isRegistered) {
//       throw StateError(
//         'HID non enregistré.',
//       );
//     }

//     if (!_grabbedReportIds.contains(reportId)) {
//       throw StateError(
//         'Report HID $reportId non disponible.',
//       );
//     }

//     if (report.length != 2) {
//       throw ArgumentError(
//         'Un report HID doit contenir '
//         'exactement 2 octets.',
//       );
//     }

//     final payload = <int>[
//       ...HidCodec.u32(deviceId),
//       ...HidCodec.u32(reportId),
//       report[0],
//       report[1],
//     ];

//     await _sendHidCommand(
//       HidCommands.deviceData,
//       payload,
//       reliable: true,
//     );
//   }

//   // ============================================================
//   // KEYBOARD
//   // ============================================================

//   Future<void> sendKeyboard(
//     int keyCode,
//   ) async {
//     final report = <int>[
//       keyCode & 0xFF,
//       0x00,
//     ];

//     await _sendData(
//       HidCommands.reportKeyboard,
//       report,
//     );

//     await Future<void>.delayed(
//       const Duration(milliseconds: 100),
//     );

//     await _sendData(
//       HidCommands.reportKeyboard,
//       const <int>[
//         0x00,
//         0x00,
//       ],
//     );
//   }

//   // ============================================================
//   // CONSUMER
//   // ============================================================

//   Future<void> sendConsumer(
//     int usage,
//   ) async {
//     final report = Uint8List(2);

//     final data =
//         ByteData.sublistView(report);

//     data.setUint16(
//       0,
//       usage,
//       Endian.little,
//     );

//     await _sendData(
//       HidCommands.reportConsumer,
//       report,
//     );

//     await Future<void>.delayed(
//       const Duration(milliseconds: 100),
//     );

//     await _sendData(
//       HidCommands.reportConsumer,
//       const <int>[
//         0x00,
//         0x00,
//       ],
//     );
//   }

//   // ============================================================
//   // DESKTOP / SYSTEM
//   // ============================================================

//   Future<void> sendDesktop(
//     int usage,
//   ) async {
//     final report = Uint8List(2);

//     final data =
//         ByteData.sublistView(report);

//     data.setUint16(
//       0,
//       usage,
//       Endian.little,
//     );

//     await _sendData(
//       HidCommands.reportDesktop,
//       report,
//     );

//     await Future<void>.delayed(
//       const Duration(milliseconds: 100),
//     );

//     await _sendData(
//       HidCommands.reportDesktop,
//       const <int>[
//         0x00,
//         0x00,
//       ],
//     );
//   }

//   // ============================================================
//   // ENVOI COMMANDE HID GENERIQUE
//   // ============================================================

//   Future<void> _sendHidCommand(
//     int command,
//     List<int> payload, {
//     required bool reliable,
//   }) async {
//     _checkConnected();

//     print('');
//     print('========================================');
//     print('             HID TX');
//     print('========================================');

//     print(
//       'Command : '
//       '0x${command.toRadixString(16).padLeft(2, '0')}',
//     );

//     print(
//       'Payload : '
//       '${payload.length} octets',
//     );

//     print(
//       'Data    : '
//       '${HidCodec.hex(payload)}',
//     );

//     print('========================================');

//     await rudp.sendApp(
//       command,
//       payload,
//       reliable: reliable,
//     );
//   }

//   // ============================================================
//   // AFFICHAGE HID READY
//   // ============================================================

//   void _printReady() {
//     print('');
//     print('========================================');
//     print('       HID COMPLETEMENT INITIALISE');
//     print('========================================');

//     print(
//       'Unicode : '
//       '$unicodeGrabbed '
//       '(Report ID ${HidCommands.reportUnicode})',
//     );

//     print(
//       'Keyboard: '
//       '$keyboardGrabbed '
//       '(Report ID ${HidCommands.reportKeyboard})',
//     );

//     print(
//       'Consumer: '
//       '$consumerGrabbed '
//       '(Report ID ${HidCommands.reportConsumer})',
//     );

//     print(
//       'System  : '
//       '$desktopGrabbed '
//       '(Report ID ${HidCommands.reportDesktop})',
//     );

//     print('========================================');
//   }

//   // ============================================================
//   // VALIDATION
//   // ============================================================

//   void _checkConnected() {
//     if (!rudp.isConnected) {
//       throw StateError(
//         'RUDP non connecté.',
//       );
//     }
//   }

//   void _checkHidReadyForReport(
//     int reportId,
//   ) {
//     _checkConnected();

//     if (!_isRegistered) {
//       throw StateError(
//         'HID non enregistré.',
//       );
//     }

//     _validateReportId(reportId);

//     if (!_grabbedReportIds.contains(reportId)) {
//       throw StateError(
//         'Report HID $reportId non disponible.',
//       );
//     }
//   }

//   static void _validateReportId(
//     int reportId,
//   ) {
//     if (!HidCommands.isValidReportId(
//       reportId,
//     )) {
//       throw ArgumentError(
//         'Report HID invalide : $reportId',
//       );
//     }
//   }
// }
