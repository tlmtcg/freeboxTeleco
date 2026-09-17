import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String connectionMessage;
  final bool isConnected;
  final bool isCheckingConnection;
  final VoidCallback? onReconnect;

  const HomeHeader({
    super.key,
    required this.connectionMessage,
    required this.isConnected,
    required this.isCheckingConnection,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF17233F),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.satellite_alt_rounded,
              color: Color(0xFF8EAEFF),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Télécommande Freebox',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 2),

                Text(
                  connectionMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF81899B),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Changer de Freebox',
            onPressed: isCheckingConnection ? null : onReconnect,
            icon: isCheckingConnection
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  ),
            color: isConnected
                ? const Color(0xFF73E0B1)
                : const Color(0xFFFFB86B),
          ),
        ],
      ),
    );
  }
}
