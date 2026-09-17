import 'package:flutter/material.dart';
import 'package:freebox_teleco/tv/models/channel_filter.dart';

import '../models/tv_channel.dart';


class ChannelFilterBar extends StatelessWidget {
  final List<TvChannel> channels;

  final ChannelFilter filter;

  final ValueChanged<ChannelFilter> onFilterChanged;

  const ChannelFilterBar({
    super.key,
    required this.channels,
    required this.filter,
    required this.onFilterChanged,
  });

  // ============================================================
  // COUNTS
  // ============================================================

  int get allCount {
    return channels.length;
  }

int get freeCount {
    return channels.where((channel) => channel.isFree).length;
  }

  int get paidCount {
    return channels.where((channel) => channel.isPaid).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Gratuites',
              icon: Icons.check_circle_outline,
              filter: ChannelFilter.free,
              count: freeCount,
            ),

            const SizedBox(width: 8),

            _buildFilterChip(
              label: 'Toutes',
              icon: Icons.tv,
              filter: ChannelFilter.all,
              count: allCount,
            ),

            const SizedBox(width: 8),

            _buildFilterChip(
              label: 'Payantes',
              icon: Icons.lock_outline,
              filter: ChannelFilter.paid,
              count: paidCount,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required ChannelFilter filter,
    required int count,
  }) {
    final selected = this.filter == filter;

    return FilterChip(
      selected: selected,
      onSelected: (_) {
        onFilterChanged(filter);
      },
      avatar: Icon(icon, size: 18),
      label: Text('$label ($count)'),
    );
  }
}
