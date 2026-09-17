import 'dart:async';
import 'dart:io';

import 'mdns_packet_parser.dart';
import 'mdns_query.dart';
import 'mdns_record.dart';

class MdnsClient {
  static const String multicastAddress = '224.0.0.251';
  static const int multicastPort = 5353;

  final MdnsQuery query;
  final MdnsPacketParser parser;

  MdnsClient({MdnsQuery? query, MdnsPacketParser? parser})
    : query = query ?? MdnsQuery(),
      parser = parser ?? MdnsPacketParser();

  // ===========================================================================
  // DISCOVERY
  // ===========================================================================

  Future<DnsPacket?> discover(
    String serviceName, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );

    try {
      final completer = Completer<DnsPacket?>();

      final packet = query.build(serviceName);

      socket.send(packet, InternetAddress(multicastAddress), multicastPort);

      late final StreamSubscription<RawSocketEvent> subscription;

      subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) {
          return;
        }

        final datagram = socket.receive();

        if (datagram == null) {
          return;
        }

        final result = parser.parse(datagram.data, datagram.address);

        if (result != null && !completer.isCompleted) {
          completer.complete(result);
        }
      });

      try {
        return await completer.future.timeout(timeout, onTimeout: () => null);
      } finally {
        await subscription.cancel();
      }
    } finally {
      socket.close();
    }
  }
}
