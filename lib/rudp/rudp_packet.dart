import 'dart:typed_data';

class RudpPacket {
  const RudpPacket({
    required this.command,
    required this.options,
    required this.reliableAck,
    required this.reliable,
    required this.unreliable,
    this.payload = const <int>[],
  });

  /// Taille de l'en-tête RUDP.
  ///
  /// L'ancien FreeboxPlayerClient utilise bien un header de 8 octets :
  ///
  ///  byte 0-1 : command / options
  ///  byte 2-3 : reliable ACK
  ///  byte 4-5 : reliable sequence
  ///  byte 6-7 : unreliable sequence
  static const int headerSize = 8;

  final int command;
  final int options;
  final int reliableAck;
  final int reliable;
  final int unreliable;
  final List<int> payload;

  // ============================================================
  // ENCODAGE
  // ============================================================

  Uint8List encode() {
    final buffer = Uint8List(headerSize + payload.length);

    // ----------------------------------------------------------
    // Header
    // ----------------------------------------------------------

    buffer[0] = command & 0xFF;
    buffer[1] = options & 0xFF;

    // reliable ACK - Big Endian
    buffer[2] = (reliableAck >> 8) & 0xFF;
    buffer[3] = reliableAck & 0xFF;

    // reliable sequence - Big Endian
    buffer[4] = (reliable >> 8) & 0xFF;
    buffer[5] = reliable & 0xFF;

    // unreliable sequence - Big Endian
    buffer[6] = (unreliable >> 8) & 0xFF;
    buffer[7] = unreliable & 0xFF;

    // ----------------------------------------------------------
    // Payload
    // ----------------------------------------------------------

    if (payload.isNotEmpty) {
      buffer.setRange(headerSize, buffer.length, payload);
    }

    return buffer;
  }

  // ============================================================
  // DECODAGE
  // ============================================================

  static RudpPacket decode(Uint8List data) {
    if (data.length < headerSize) {
      throw const FormatException('Paquet RUDP trop court.');
    }

    // ----------------------------------------------------------
    // Header
    // ----------------------------------------------------------

    final command = data[0];

    final options = data[1];

    // Big Endian
    final reliableAck = (data[2] << 8) | data[3];

    // Big Endian
    final reliable = (data[4] << 8) | data[5];

    // Big Endian
    final unreliable = (data[6] << 8) | data[7];

    // ----------------------------------------------------------
    // Payload
    // ----------------------------------------------------------

    final payload = Uint8List.fromList(data.sublist(headerSize));

    return RudpPacket(
      command: command,
      options: options,
      reliableAck: reliableAck,
      reliable: reliable,
      unreliable: unreliable,
      payload: payload,
    );
  }

  // ============================================================
  // AFFICHAGE DEBUG
  // ============================================================

  @override
  String toString() {
    return 'RudpPacket('
        'command: 0x'
        '${command.toRadixString(16).padLeft(2, '0')}, '
        'options: 0x'
        '${options.toRadixString(16).padLeft(2, '0')}, '
        'reliableAck: $reliableAck, '
        'reliable: $reliable, '
        'unreliable: $unreliable, '
        'payloadLength: ${payload.length}'
        ')';
  }
}

