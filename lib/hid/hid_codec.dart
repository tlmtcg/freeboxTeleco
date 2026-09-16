import 'dart:typed_data';

abstract final class HidCodec {
  // ============================================================
  // U32 BIG ENDIAN
  // ============================================================

  static int readU32(
    List<int> data,
    int offset,
  ) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  static List<int> u32(int value) {
    return <int>[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static void writeU32(
    List<int> data,
    int value,
  ) {
    data.addAll(u32(value));
  }

  // ============================================================
  // U16 BIG ENDIAN
  // ============================================================

  static void writeU16At(
    Uint8List data,
    int offset,
    int value,
  ) {
    data[offset] = (value >> 8) & 0xFF;
    data[offset + 1] = value & 0xFF;
  }

  // ============================================================
  // STRING
  // ============================================================

  static void writeFixedString(
    Uint8List data,
    int offset,
    int length,
    String value,
  ) {
    final bytes = value.codeUnits;

    final count =
        bytes.length < length
            ? bytes.length
            : length;

    for (int i = 0; i < count; i++) {
      data[offset + i] = bytes[i] & 0xFF;
    }
  }

  // ============================================================
  // ALIGNEMENT
  // ============================================================

  static int roundUp4(int value) {
    return (value + 3) & ~3;
  }

  // ============================================================
  // HEX
  // ============================================================

  static String hex(List<int> data) {
    return data
        .map(
          (value) => value
              .toRadixString(16)
              .padLeft(2, '0')
              .toUpperCase(),
        )
        .join(' ');
  }
}

