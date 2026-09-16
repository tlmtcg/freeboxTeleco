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

  // ============================================================
  // CONSTANTES
  // ============================================================

  /// Taille de l'en-tête RUDP.
  static const int headerSize = 12;

  // ============================================================
  // CHAMPS
  // ============================================================

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

    final data = ByteData.sublistView(buffer);

    // ----------------------------------------------------------
    // En-tête RUDP
    // ----------------------------------------------------------

    buffer[0] = command & 0xFF;
    buffer[1] = options & 0xFF;

    data.setUint16(2, reliableAck & 0xFFFF, Endian.little);

    data.setUint16(4, reliable & 0xFFFF, Endian.little);

    data.setUint16(6, unreliable & 0xFFFF, Endian.little);

    // Octets 8..11 réservés à l'en-tête.
    buffer[8] = 0;
    buffer[9] = 0;
    buffer[10] = 0;
    buffer[11] = 0;

    // ----------------------------------------------------------
    // Payload
    // ----------------------------------------------------------

    buffer.setRange(headerSize, buffer.length, payload);

    return buffer;
  }

  // ============================================================
  // DECODAGE
  // ============================================================

  static RudpPacket decode(Uint8List data) {
    if (data.length < headerSize) {
      throw const FormatException('Paquet RUDP trop court.');
    }

    final view = ByteData.sublistView(data);

    final command = data[0];
    final options = data[1];

    final reliableAck = view.getUint16(2, Endian.little);

    final reliable = view.getUint16(4, Endian.little);

    final unreliable = view.getUint16(6, Endian.little);

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
  // UTILITAIRE
  // ============================================================

  @override
  String toString() {
    return 'RudpPacket('
        'command: 0x${command.toRadixString(16).padLeft(2, '0')}, '
        'options: 0x${options.toRadixString(16).padLeft(2, '0')}, '
        'reliableAck: $reliableAck, '
        'reliable: $reliable, '
        'unreliable: $unreliable, '
        'payloadLength: ${payload.length}'
        ')';
  }
}

