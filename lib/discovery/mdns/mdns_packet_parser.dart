import 'dart:io';
import 'dart:typed_data';

import 'mdns_record.dart';

class MdnsPacketParser {
  DnsPacket? parse(List<int> data, InternetAddress sourceAddress) {
    if (data.length < 12) {
      return null;
    }

    final bytes = Uint8List.fromList(data);
    final view = ByteData.sublistView(bytes);

    final questions = view.getUint16(4);
    final answers = view.getUint16(6);
    final authorities = view.getUint16(8);
    final additionals = view.getUint16(10);

    var offset = 12;

    // -------------------------------------------------------------------------
    // Questions
    // -------------------------------------------------------------------------

    for (var i = 0; i < questions; i++) {
      final result = readDnsName(bytes, offset);

      if (result == null) {
        return null;
      }

      offset = result.nextOffset;

      if (offset + 4 > bytes.length) {
        return null;
      }

      // TYPE + CLASS
      offset += 4;
    }

    // -------------------------------------------------------------------------
    // Resource records
    // -------------------------------------------------------------------------

    final records = <DnsRecord>[];

    final recordCount = answers + authorities + additionals;

    for (var i = 0; i < recordCount; i++) {
      final result = _readRecord(bytes, offset);

      if (result == null) {
        return null;
      }

      records.add(result.record);
      offset = result.nextOffset;
    }

    return DnsPacket(
      bytes: bytes,
      sourceAddress: sourceAddress,
      records: records,
    );
  }

  // ===========================================================================
  // DNS RECORD
  // ===========================================================================

  DnsRecordResult? _readRecord(Uint8List bytes, int offset) {
    final nameResult = readDnsName(bytes, offset);

    if (nameResult == null) {
      return null;
    }

    offset = nameResult.nextOffset;

    if (offset + 10 > bytes.length) {
      return null;
    }

    final view = ByteData.sublistView(bytes);

    final type = view.getUint16(offset);
    final clazz = view.getUint16(offset + 2);
    final ttl = view.getUint32(offset + 4);
    final dataLength = view.getUint16(offset + 8);

    offset += 10;

    if (offset + dataLength > bytes.length) {
      return null;
    }

    final record = DnsRecord(
      name: nameResult.name,
      type: type,
      clazz: clazz,
      ttl: ttl,
      dataOffset: offset,
      dataLength: dataLength,
    );

    return DnsRecordResult(record: record, nextOffset: offset + dataLength);
  }

  // ===========================================================================
  // DNS NAME
  // ===========================================================================

  DnsNameResult? readDnsName(Uint8List bytes, int offset) {
    if (offset >= bytes.length) {
      return null;
    }

    final labels = <String>[];

    var currentOffset = offset;
    var nextOffset = offset;
    var jumped = false;

    var iterations = 0;

    while (true) {
      if (++iterations > 128) {
        return null;
      }

      if (currentOffset >= bytes.length) {
        return null;
      }

      final length = bytes[currentOffset];

      // -----------------------------------------------------------------------
      // Fin du nom
      // -----------------------------------------------------------------------

      if (length == 0) {
        if (!jumped) {
          nextOffset = currentOffset + 1;
        }

        break;
      }

      // -----------------------------------------------------------------------
      // Compression DNS
      // -----------------------------------------------------------------------

      if ((length & 0xC0) == 0xC0) {
        if (currentOffset + 1 >= bytes.length) {
          return null;
        }

        final pointer = ((length & 0x3F) << 8) | bytes[currentOffset + 1];

        if (!jumped) {
          nextOffset = currentOffset + 2;
        }

        if (pointer >= bytes.length) {
          return null;
        }

        currentOffset = pointer;
        jumped = true;
        continue;
      }

      // -----------------------------------------------------------------------
      // Longueur invalide
      // -----------------------------------------------------------------------

      if (length > 63) {
        return null;
      }

      final start = currentOffset + 1;
      final end = start + length;

      if (end > bytes.length) {
        return null;
      }

      labels.add(String.fromCharCodes(bytes.sublist(start, end)));

      currentOffset = end;

      if (!jumped) {
        nextOffset = currentOffset;
      }
    }

    return DnsNameResult(name: labels.join('.'), nextOffset: nextOffset);
  }
}
