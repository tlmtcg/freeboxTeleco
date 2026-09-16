import '../hid_codec.dart';

abstract final class HidDeviceDropped {
  // ============================================================
  // DEVICE_DROPPED
  //
  // Client -> Player
  //
  // Payload :
  //   uint32 device_id
  //   uint32 report_id = 0
  // ============================================================

  static List<int> build({
    required int deviceId,
  }) {
    return <int>[
      ...HidCodec.u32(deviceId),
      ...HidCodec.u32(0),
    ];
  }

  // ============================================================
  // LECTURE DEVICE_ID
  // ============================================================

  static int readDeviceId(
    List<int> payload,
  ) {
    if (payload.length < 8) {
      throw FormatException(
        'DEVICE_DROPPED payload trop court: '
        '${payload.length} octets',
      );
    }

    return HidCodec.readU32(
      payload,
      0,
    );
  }

  // ============================================================
  // LECTURE REPORT_ID
  // ============================================================

  static int readReportId(
    List<int> payload,
  ) {
    if (payload.length < 8) {
      throw FormatException(
        'DEVICE_DROPPED payload trop court: '
        '${payload.length} octets',
      );
    }

    return HidCodec.readU32(
      payload,
      4,
    );
  }
}
