import 'package:flutter/material.dart';

import '../models/tv_channel.dart';

class ProgramInfo extends StatelessWidget {
  final TvChannel channel;

  const ProgramInfo({super.key, required this.channel});

  Map<String, dynamic>? get program {
    return channel.epg;
  }

  String _readTitle(Map<String, dynamic> program) {
    return program['title']?.toString() ?? 'Programme indisponible';
  }

  String? _readDescription(Map<String, dynamic> program) {
    final value = program['desc'];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  int? _readDate(Map<String, dynamic> program) {
    final value = program['date'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  int? _readDuration(Map<String, dynamic> program) {
    final value = program['duration'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final currentProgram = program;

    if (currentProgram == null) {
      return Text(
        'Programme en cours indisponible',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 13,
        ),
      );
    }

    final title = _readTitle(currentProgram);

    final description = _readDescription(currentProgram);

    final start = _readDate(currentProgram);

    final duration = _readDuration(currentProgram);

    int? end;

    if (start != null && duration != null) {
      end = start + duration;
    }

    double progress = 0;

    if (start != null && end != null && end > start) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      progress = ((now - start) / (end - start)).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),

        if (description != null) ...[
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],

        if (start != null && end != null) ...[
          const SizedBox(height: 5),

          Row(
            children: [
              Text(
                '${_formatTime(start)} → ${_formatTime(end)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ],
    );
  }
}
