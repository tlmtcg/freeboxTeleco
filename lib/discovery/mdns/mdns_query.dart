class MdnsQuery {
  const MdnsQuery();

  List<int> build(String serviceName) {
    final packet = <int>[
      // Transaction ID
      0x00,
      0x00,

      // Flags
      0x00,
      0x00,

      // Questions = 1
      0x00,
      0x01,

      // Answers = 0
      0x00,
      0x00,

      // Authority = 0
      0x00,
      0x00,

      // Additional = 0
      0x00,
      0x00,
    ];

    for (final part in serviceName.split('.')) {
      packet.add(part.length);
      packet.addAll(part.codeUnits);
    }

    // Fin du nom DNS.
    packet.add(0x00);

    // TYPE PTR
    packet.addAll([0x00, 0x0C]);

    // CLASS IN
    packet.addAll([0x00, 0x01]);

    return packet;
  }
}
