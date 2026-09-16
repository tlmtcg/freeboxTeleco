import '../hid_codec.dart';

/// Décodage de HID GRAB.
///
/// GRAB est une commande serveur -> client.
///
/// Format:
///   u32 device_id   BE
///   u32 report_id   BE
abstract final class HidGrab {
  static int readDeviceId(List<int> payload) {
    _checkHeader(payload);
    return HidCodec.readU32(payload, 0);
  }

  static int readReportId(List<int> payload) {
    _checkHeader(payload);
    return HidCodec.readU32(payload, 4);
  }

  static void _checkHeader(List<int> payload) {
    if (payload.length < 8) {
      throw FormatException(
        'GRAB payload trop court: ${payload.length} octets',
      );
    }
  }
}

