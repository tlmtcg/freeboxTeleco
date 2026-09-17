import 'dart:io';
import 'dart:typed_data';

class DnsPacket {
  const DnsPacket({
    required this.bytes,
    required this.sourceAddress,
    required this.records,
  });

  /// Paquet DNS complet.
  final Uint8List bytes;

  /// Adresse IP du Player ayant envoyé la réponse mDNS.
  final InternetAddress sourceAddress;

  /// Tous les Resource Records du paquet.
  final List<DnsRecord> records;
}

class DnsRecord {
  const DnsRecord({
    required this.name,
    required this.type,
    required this.clazz,
    required this.ttl,
    required this.dataOffset,
    required this.dataLength,
  });

  final String name;
  final int type;
  final int clazz;
  final int ttl;

  /// Position des données dans le paquet DNS complet.
  final int dataOffset;

  final int dataLength;
}

class DnsRecordResult {
  const DnsRecordResult({required this.record, required this.nextOffset});

  final DnsRecord record;
  final int nextOffset;
}

class DnsNameResult {
  const DnsNameResult({required this.name, required this.nextOffset});

  final String name;
  final int nextOffset;
}
