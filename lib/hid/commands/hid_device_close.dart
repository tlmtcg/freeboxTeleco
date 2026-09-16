import '../hid_codec.dart';

/// Décodage de DEVICE_CLOSE.
///
/// DEVICE_CLOSE est une commande serveur -> client.
/// Le Player envoie un foils_hid_header.
abstract final class HidDeviceClose {
  static int readDeviceId(List<int> payload) {
    if (payload.length < 8) {
      throw FormatException(
        'DEVICE_CLOSE payload trop court: ${payload.length} octets',
      );
    }

    return HidCodec.readU32(payload, 0);
  }

  static int readReportId(List<int> payload) {
    if (payload.length < 8) {
      throw FormatException(
        'DEVICE_CLOSE payload trop court: ${payload.length} octets',
      );
    }

    return HidCodec.readU32(payload, 4);
  }
}
