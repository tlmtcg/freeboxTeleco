import 'package:flutter/material.dart';

class ConnectionPlaceholder extends StatelessWidget {
  final bool isCheckingConnection;
  final String connectionMessage;
  final VoidCallback onReconnect;

  const ConnectionPlaceholder({
    super.key,
    required this.isCheckingConnection,
    required this.connectionMessage,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCheckingConnection
                  ? Icons.wifi_find_rounded
                  : Icons.wifi_off_rounded,
              size: 52,
              color: const Color(0xFF5B8CFF),
            ),

            const SizedBox(height: 18),

            Text(
              isCheckingConnection
                  ? 'Connexion au Player Delta...'
                  : 'Player Delta non connecté',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Text(
              connectionMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF81899B)),
            ),

            const SizedBox(height: 24),

            if (!isCheckingConnection)
              FilledButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reconnecter'),
              ),
          ],
        ),
      ),
    );
  }
}
