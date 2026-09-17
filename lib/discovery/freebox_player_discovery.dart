import 'dart:io';
import 'dart:typed_data';

import '../core/freebox_player.dart';
import 'mdns/mdns_client.dart';
import 'mdns/mdns_packet_parser.dart';
import 'mdns/mdns_record.dart';

class FreeboxPlayerDiscovery {
  static const String serviceName = '_hid._udp.local';

  final MdnsClient mdnsClient;
  final MdnsPacketParser parser;

  FreeboxPlayerDiscovery({MdnsClient? mdnsClient, MdnsPacketParser? parser})
    : mdnsClient = mdnsClient ?? MdnsClient(),
      parser = parser ?? MdnsPacketParser();

  // ===========================================================================
  // DISCOVERY
  // ===========================================================================

  Future<FreeboxPlayer?> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final packet = await mdnsClient.discover(serviceName, timeout: timeout);

    if (packet == null) {
      return null;
    }

    return _findPlayer(packet);
  }

  // ===========================================================================
  // FIND PLAYER
  // ===========================================================================

  FreeboxPlayer? _findPlayer(DnsPacket packet) {
    final bytes = packet.bytes;
    final records = packet.records;
    final sourceAddress = packet.sourceAddress;

    String? serviceInstance;
    String? targetHost;
    int? port;

    // =========================================================================
    // PTR
    // =========================================================================

    for (final record in records) {
      if (record.type != 12) {
        continue;
      }

      if (!_sameName(record.name, serviceName)) {
        continue;
      }

      final result = parser.readDnsName(bytes, record.dataOffset);

      if (result != null) {
        serviceInstance = result.name;
        break;
      }
    }

    if (serviceInstance == null) {
      return null;
    }

    // =========================================================================
    // SRV
    // =========================================================================

    for (final record in records) {
      if (record.type != 33) {
        continue;
      }

      if (!_sameName(record.name, serviceInstance)) {
        continue;
      }

      if (record.dataLength < 6) {
        continue;
      }

      final view = ByteData.sublistView(bytes);

      // SRV :
      //
      // priority : 2 octets
      // weight   : 2 octets
      // port     : 2 octets
      //
      port = view.getUint16(record.dataOffset + 4);

      final targetResult = parser.readDnsName(bytes, record.dataOffset + 6);

      if (targetResult != null) {
        targetHost = targetResult.name;
      }

      break;
    }

    if (port == null) {
      return null;
    }

    // =========================================================================
    // A
    // =========================================================================

    InternetAddress? address;

    if (targetHost != null) {
      for (final record in records) {
        if (record.type != 1) {
          continue;
        }

        if (!_sameName(record.name, targetHost)) {
          continue;
        }

        if (record.dataLength != 4) {
          continue;
        }

        final offset = record.dataOffset;

        address = InternetAddress(
          '${bytes[offset]}.'
          '${bytes[offset + 1]}.'
          '${bytes[offset + 2]}.'
          '${bytes[offset + 3]}',
        );

        break;
      }
    }

    // =========================================================================
    // FALLBACK
    // =========================================================================

    address ??= sourceAddress;

    return FreeboxPlayer(address: address, port: port);
  }

  // ===========================================================================
  // NAME COMPARISON
  // ===========================================================================

  bool _sameName(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }
}
