import 'package:flutter/material.dart';

import '../models/tv_channel.dart';

class ChannelLogo extends StatelessWidget {
  final TvChannel channel;

  const ChannelLogo({super.key, required this.channel});

  String? get logoUrl {
    final logoPath = channel.logoUrl;

    if (logoPath == null || logoPath.isEmpty) {
      return null;
    }

    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return logoPath;
    }

    return 'http://mafreebox.freebox.fr$logoPath';
  }

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;

    return Container(
      width: 68,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(Icons.tv, color: Colors.white54, size: 30)
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.tv, color: Colors.white54, size: 30);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
    );
  }
}
