import 'dart:io';

class FreeboxPlayer {
  const FreeboxPlayer({required this.address, required this.port});

  final InternetAddress address;
  final int port;

  @override
  String toString() => '${address.address}:$port';
}
