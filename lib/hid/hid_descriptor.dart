import 'dart:typed_data';

import 'hid_codec.dart';

abstract final class HidDescriptor {
  // ============================================================
  // DESCRIPTOR HID
  // ============================================================

  static const List<int> data = <int>[
    // ==========================================================
    // Report ID 1 : Unicode
    // ==========================================================

    0x05,
    0x01,
    0x09,
    0x06,
    0xA1,
    0x01,

    0x85,
    0x01,

    0x05,
    0x10,
    0x08,

    0x95,
    0x01,
    0x75,
    0x20,

    0x14,
    0x27,
    0xFF,
    0xFF,
    0xFF,

    0x81,
    0x62,

    0xC0,

    // ==========================================================
    // Report ID 2 : Keyboard
    // ==========================================================

    0xA1,
    0x01,

    0x85,
    0x02,

    0x95,
    0x01,
    0x75,
    0x08,

    0x15,
    0x00,
    0x26,
    0xFF,
    0x00,

    0x05,
    0x07,

    0x19,
    0x00,
    0x2A,
    0xFF,
    0x00,

    0x80,

    0xC0,

    // ==========================================================
    // Report ID 3 : Consumer Control
    // ==========================================================

    0x05,
    0x0C,
    0x09,
    0x01,

    0xA1,
    0x01,

    0x85,
    0x03,

    0x95,
    0x01,
    0x75,
    0x10,

    0x19,
    0x00,
    0x2A,
    0xB0,
    0x0F,

    0x15,
    0x00,
    0x26,
    0xB0,
    0x0F,

    0x80,

    0xC0,

    // ==========================================================
    // Report ID 4 : System Control
    // ==========================================================

    0x05,
    0x01,

    0x0A,
    0x80,
    0x00,

    0xA1,
    0x01,

    0x85,
    0x04,

    0x75,
    0x01,
    0x95,
    0x04,

    0x1A,
    0x81,
    0x00,

    0x2A,
    0x84,
    0x00,

    0x81,
    0x02,

    0x75,
    0x01,
    0x95,
    0x04,

    0x81,
    0x01,

    0xC0,
  ];

  // ============================================================
  // DEVICE_NEW
  // ============================================================

  static List<int> buildDeviceNewPayload({
    required int deviceId,
    required String deviceName,
  }) {
    const int hidHeaderSize = 8;
    const int deviceNewSize = 112;
    const int trailingSize = 8;

    final int descriptorSize = data.length;
    final int descriptorBlobSize =
        HidCodec.roundUp4(descriptorSize);

    final payload = <int>[];

    // ----------------------------------------------------------
    // HID HEADER
    // ----------------------------------------------------------

    HidCodec.writeU32(
      payload,
      deviceId,
    );

    HidCodec.writeU32(
      payload,
      0,
    );

    // ----------------------------------------------------------
    // DEVICE_NEW
    // ----------------------------------------------------------

    final deviceNew =
        Uint8List(deviceNewSize);

    HidCodec.writeFixedString(
      deviceNew,
      0,
      64,
      deviceName,
    );

    // serial[32] reste à zéro.

    deviceNew[96] = 0;
    deviceNew[97] = 0;

    // version = 0x0100
    deviceNew[98] = 0x01;
    deviceNew[99] = 0x00;

    // descriptor offset
    HidCodec.writeU16At(
      deviceNew,
      100,
      0x0070,
    );

    // descriptor size
    HidCodec.writeU16At(
      deviceNew,
      102,
      descriptorSize,
    );

    // physical offset
    HidCodec.writeU16At(
      deviceNew,
      104,
      0x0070 + descriptorBlobSize,
    );

    // physical size
    HidCodec.writeU16At(
      deviceNew,
      106,
      0,
    );

    // strings offset
    HidCodec.writeU16At(
      deviceNew,
      108,
      0x0070 + descriptorBlobSize,
    );

    // strings size
    HidCodec.writeU16At(
      deviceNew,
      110,
      0,
    );

    payload.addAll(deviceNew);

    // ----------------------------------------------------------
    // DESCRIPTOR
    // ----------------------------------------------------------

    payload.addAll(data);

    // ----------------------------------------------------------
    // PADDING
    // ----------------------------------------------------------

    while (payload.length <
        hidHeaderSize +
            deviceNewSize +
            descriptorBlobSize) {
      payload.add(0);
    }

    // ----------------------------------------------------------
    // TRAILING
    // ----------------------------------------------------------

    payload.addAll(
      List<int>.filled(
        trailingSize,
        0,
      ),
    );

    return payload;
  }
}