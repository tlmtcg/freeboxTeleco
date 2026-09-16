import 'package:flutter/material.dart';

class ChannelBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const ChannelBadge({
    super.key,
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: highlighted
            ? Colors.orange.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: highlighted
              ? Colors.orange.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
