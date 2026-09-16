import '../hid_codec.dart';

/// Commande HID DATA.
///
/// Peut être envoyée dans les deux directions.
///
/// Format:
///   u32 device_id   BE
///   u32 report_id   BE
///   data...
abstract final class HidData {
  static List<int> build({
    required int deviceId,
    required int reportId,
    required List<int> data,
  }) {
    return <int>[...HidCodec.u32(deviceId), ...HidCodec.u32(reportId), ...data];
  }

  static int readDeviceId(List<int> payload) {
    _checkHeader(payload);
    return HidCodec.readU32(payload, 0);
  }

  static int readReportId(List<int> payload) {
    _checkHeader(payload);
    return HidCodec.readU32(payload, 4);
  }

  static List<int> readData(List<int> payload) {
    _checkHeader(payload);

    return List<int>.from(payload.sublist(8));
  }

  static void _checkHeader(List<int> payload) {
    if (payload.length < 8) {
      throw FormatException(
        'DATA payload trop court: ${payload.length} octets',
      );
    }
  }
}
