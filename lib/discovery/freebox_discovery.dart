// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import '../core/freebox_player.dart';

// class FreeboxDiscovery {
//   static const String _serviceName = '_hid._udp.local';

//   /// Recherche un Player Freebox sur le réseau local.
//   Future<FreeboxPlayer?> discover({
//     Duration timeout = const Duration(seconds: 5),
//   }) async {
//     final socket = await RawDatagramSocket.bind(
//       InternetAddress.anyIPv4,
//       0,
//       reuseAddress: true,
//     );

//     try {
//       final completer = Completer<FreeboxPlayer?>();

//       final query = _buildMdnsQuery(_serviceName);

//       socket.send(query, InternetAddress('224.0.0.251'), 5353);

//       late final StreamSubscription<RawSocketEvent> subscription;

//       subscription = socket.listen((event) {
//         if (event != RawSocketEvent.read) {
//           return;
//         }

//         final datagram = socket.receive();

//         if (datagram == null) {
//           return;
//         }

//         final player = _parseResponse(datagram.data, datagram.address);

//         if (player != null && !completer.isCompleted) {
//           completer.complete(player);
//         }
//       });

//       final player = await completer.future.timeout(
//         timeout,
//         onTimeout: () => null,
//       );

//       await subscription.cancel();

//       return player;
//     } finally {
//       socket.close();
//     }
//   }

//   // ============================================================
//   // mDNS QUERY
//   // ============================================================

//   List<int> _buildMdnsQuery(String name) {
//     final packet = <int>[
//       // Transaction ID
//       0x00,
//       0x00,

//       // Flags
//       0x00,
//       0x00,

//       // Questions = 1
//       0x00,
//       0x01,

//       // Answers = 0
//       0x00,
//       0x00,

//       // Authority = 0
//       0x00,
//       0x00,

//       // Additional = 0
//       0x00,
//       0x00,
//     ];

//     for (final part in name.split('.')) {
//       packet.add(part.length);
//       packet.addAll(part.codeUnits);
//     }

//     // Fin du nom DNS.
//     packet.add(0x00);

//     // Type PTR.
//     packet.addAll([0x00, 0x0C]);

//     // Classe IN.
//     packet.addAll([0x00, 0x01]);

//     return packet;
//   }

//   // ============================================================
//   // mDNS PARSER
//   // ============================================================

//   FreeboxPlayer? _parseResponse(List<int> data, InternetAddress sourceAddress) {
//     if (data.length < 12) {
//       return null;
//     }

//     final bytes = Uint8List.fromList(data);
//     final view = ByteData.sublistView(bytes);

//     final questions = view.getUint16(4);
//     final answers = view.getUint16(6);
//     final authorities = view.getUint16(8);
//     final additionals = view.getUint16(10);

//     var offset = 12;

//     // ----------------------------------------------------------
//     // Questions
//     // ----------------------------------------------------------

//     for (var i = 0; i < questions; i++) {
//       final result = _readDnsName(bytes, offset);

//       if (result == null) {
//         return null;
//       }

//       offset = result.nextOffset;

//       if (offset + 4 > bytes.length) {
//         return null;
//       }

//       // TYPE + CLASS
//       offset += 4;
//     }

//     // ----------------------------------------------------------
//     // Resource records
//     // ----------------------------------------------------------

//     final records = <_DnsRecord>[];

//     final recordCount = answers + authorities + additionals;

//     for (var i = 0; i < recordCount; i++) {
//       final result = _readRecord(bytes, offset);

//       if (result == null) {
//         return null;
//       }

//       records.add(result.record);
//       offset = result.nextOffset;
//     }

//     return _findPlayer(bytes, records, sourceAddress);
//   }

//   // ============================================================
//   // DNS RECORD
//   // ============================================================

//   _DnsRecordResult? _readRecord(Uint8List bytes, int offset) {
//     final nameResult = _readDnsName(bytes, offset);

//     if (nameResult == null) {
//       return null;
//     }

//     offset = nameResult.nextOffset;

//     if (offset + 10 > bytes.length) {
//       return null;
//     }

//     final view = ByteData.sublistView(bytes);

//     final type = view.getUint16(offset);
//     final clazz = view.getUint16(offset + 2);
//     final ttl = view.getUint32(offset + 4);
//     final dataLength = view.getUint16(offset + 8);

//     offset += 10;

//     if (offset + dataLength > bytes.length) {
//       return null;
//     }

//     final record = _DnsRecord(
//       name: nameResult.name,
//       type: type,
//       clazz: clazz,
//       ttl: ttl,
//       dataOffset: offset,
//       dataLength: dataLength,
//     );

//     return _DnsRecordResult(record: record, nextOffset: offset + dataLength);
//   }

//   // ============================================================
//   // DNS NAME
//   // ============================================================

//   _DnsNameResult? _readDnsName(Uint8List bytes, int offset) {
//     if (offset >= bytes.length) {
//       return null;
//     }

//     final labels = <String>[];

//     var currentOffset = offset;
//     var nextOffset = offset;
//     var jumped = false;

//     var iterations = 0;

//     while (true) {
//       if (++iterations > 128) {
//         return null;
//       }

//       if (currentOffset >= bytes.length) {
//         return null;
//       }

//       final length = bytes[currentOffset];

//       // Fin du nom.
//       if (length == 0) {
//         if (!jumped) {
//           nextOffset = currentOffset + 1;
//         }

//         break;
//       }

//       // Compression DNS.
//       if ((length & 0xC0) == 0xC0) {
//         if (currentOffset + 1 >= bytes.length) {
//           return null;
//         }

//         final pointer = ((length & 0x3F) << 8) | bytes[currentOffset + 1];

//         if (!jumped) {
//           nextOffset = currentOffset + 2;
//         }

//         if (pointer >= bytes.length) {
//           return null;
//         }

//         currentOffset = pointer;
//         jumped = true;
//         continue;
//       }

//       if (length > 63) {
//         return null;
//       }

//       final start = currentOffset + 1;
//       final end = start + length;

//       if (end > bytes.length) {
//         return null;
//       }

//       labels.add(String.fromCharCodes(bytes.sublist(start, end)));

//       currentOffset = end;

//       if (!jumped) {
//         nextOffset = currentOffset;
//       }
//     }

//     return _DnsNameResult(name: labels.join('.'), nextOffset: nextOffset);
//   }

//   // ============================================================
//   // FIND PLAYER
//   // ============================================================

//   FreeboxPlayer? _findPlayer(
//     Uint8List bytes,
//     List<_DnsRecord> records,
//     InternetAddress sourceAddress,
//   ) {
//     String? serviceInstance;
//     String? targetHost;
//     int? port;

//     // ----------------------------------------------------------
//     // PTR
//     // ----------------------------------------------------------

//     for (final record in records) {
//       if (record.type != 12) {
//         continue;
//       }

//       if (record.name.toLowerCase() != _serviceName.toLowerCase()) {
//         continue;
//       }

//       final result = _readDnsName(bytes, record.dataOffset);

//       if (result != null) {
//         serviceInstance = result.name;
//         break;
//       }
//     }

//     if (serviceInstance == null) {
//       return null;
//     }

//     // ----------------------------------------------------------
//     // SRV
//     // ----------------------------------------------------------

//     for (final record in records) {
//       if (record.type != 33) {
//         continue;
//       }

//       if (record.name.toLowerCase() != serviceInstance.toLowerCase()) {
//         continue;
//       }

//       if (record.dataLength < 6) {
//         continue;
//       }

//       final view = ByteData.sublistView(bytes);

//       // SRV :
//       //
//       // priority  : 2 octets
//       // weight    : 2 octets
//       // port      : 2 octets
//       //
//       port = view.getUint16(record.dataOffset + 4);

//       final targetResult = _readDnsName(bytes, record.dataOffset + 6);

//       if (targetResult != null) {
//         targetHost = targetResult.name;
//       }

//       break;
//     }

//     if (port == null) {
//       return null;
//     }

//     // ----------------------------------------------------------
//     // A
//     // ----------------------------------------------------------

//     InternetAddress? address;

//     if (targetHost != null) {
//       for (final record in records) {
//         if (record.type != 1) {
//           continue;
//         }

//         if (record.name.toLowerCase() != targetHost.toLowerCase()) {
//           continue;
//         }

//         if (record.dataLength != 4) {
//           continue;
//         }

//         final offset = record.dataOffset;

//         address = InternetAddress(
//           '${bytes[offset]}.'
//           '${bytes[offset + 1]}.'
//           '${bytes[offset + 2]}.'
//           '${bytes[offset + 3]}',
//         );

//         break;
//       }
//     }

//     // ----------------------------------------------------------
//     // Fallback
//     // ----------------------------------------------------------

//     address ??= sourceAddress;

//     return FreeboxPlayer(address: address, port: port);
//   }
// }

// // ================================================================
// // DNS INTERNAL TYPES
// // ================================================================

// class _DnsRecord {
//   const _DnsRecord({
//     required this.name,
//     required this.type,
//     required this.clazz,
//     required this.ttl,
//     required this.dataOffset,
//     required this.dataLength,
//   });

//   final String name;
//   final int type;
//   final int clazz;
//   final int ttl;

//   /// Position des données dans le paquet DNS complet.
//   final int dataOffset;

//   final int dataLength;
// }

// class _DnsRecordResult {
//   const _DnsRecordResult({required this.record, required this.nextOffset});

//   final _DnsRecord record;
//   final int nextOffset;
// }

// class _DnsNameResult {
//   const _DnsNameResult({required this.name, required this.nextOffset});

//   final String name;
//   final int nextOffset;
// }

import '../core/freebox_player.dart';
import 'freebox_player_discovery.dart';

class FreeboxDiscovery {
  final FreeboxPlayerDiscovery playerDiscovery;

  FreeboxDiscovery({FreeboxPlayerDiscovery? playerDiscovery})
    : playerDiscovery = playerDiscovery ?? FreeboxPlayerDiscovery();

  Future<FreeboxPlayer?> discover({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return playerDiscovery.discover(timeout: timeout);
  }
}
