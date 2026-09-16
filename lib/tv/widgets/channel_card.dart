import 'package:flutter/material.dart';

import '../models/tv_channel.dart';
import 'channel_badge.dart';
import 'channel_logo.dart';
import 'program_info.dart';

class ChannelCard extends StatelessWidget {
  final TvChannel channel;

  final VoidCallback onTap;
  final VoidCallback onLogoPress;
  final VoidCallback onSelect;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    required this.onLogoPress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = channel.isPaid;
    final isAvailable = channel.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF111722),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // LOGO
              // --------------------------------------------------

              GestureDetector(
                onTap: onSelect,
                onLongPress: onLogoPress,
                child: ChannelLogo(channel: channel),
              ),

              const SizedBox(width: 12),

              // --------------------------------------------------
              // INFORMATIONS
              // --------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --------------------------------------------
                    // NUMERO + NOM
                    // --------------------------------------------

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Text(
                            '${channel.number}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            channel.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // --------------------------------------------
                    // BADGES
                    // --------------------------------------------
                    Row(
                      children: [
                        if (isPaid)
                          ChannelBadge(
                            icon: Icons.lock_outline,
                            label: isAvailable ? 'PAYANTE' : '🔒 PAYANTE',
                            highlighted: !isAvailable,
                          ),

                        if (isPaid && !isAvailable) const SizedBox(width: 6),

                        if (!isPaid && isAvailable)
                          const ChannelBadge(
                            icon: Icons.check_circle_outline,
                            label: 'DISPONIBLE',
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // --------------------------------------------
                    // PROGRAMME
                    // --------------------------------------------
                    ProgramInfo(channel: channel),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // --------------------------------------------------
              // ACTION
              // --------------------------------------------------
              Icon(
                isAvailable ? Icons.play_circle_outline : Icons.lock_outline,
                color: isAvailable ? Colors.white70 : Colors.orangeAccent,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
