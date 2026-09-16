import 'package:flutter/material.dart';

import '../models/tv_channel.dart';

class ChannelDetails extends StatelessWidget {
  final TvChannel channel;
  final Map<String, dynamic>? program;

  final VoidCallback onPlay;
  final VoidCallback onSelect;

  /// Adresse de la Freebox, par exemple :
  /// http://192.168.0.254
  final String freeboxBaseUrl;

  const ChannelDetails({
    super.key,
    required this.channel,
    required this.program,
    required this.onPlay,
    required this.onSelect,
    required this.freeboxBaseUrl,
  });

  // ============================================================
  // CHANNEL
  // ============================================================

  String? _readChannelString(String key) {
    final value = channel.raw[key];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  // ============================================================
  // PROGRAM
  // ============================================================

  String? _readProgramString(String key) {
    final value = program?[key];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  // ============================================================
  // PROGRAM IMAGE
  // ============================================================

  String? _programImageUrl() {
    final pictureBig = _readProgramString('picture_big');

    if (pictureBig == null) {
      return null;
    }

    if (pictureBig.startsWith('http://') || pictureBig.startsWith('https://')) {
      return pictureBig;
    }

    return 'http://$freeboxBaseUrl$pictureBig';
  }

  @override
  Widget build(BuildContext context) {
    final description = _readChannelString('description');

    final category = _readChannelString('category');

    final programTitle = _readProgramString('title');

    final programSubTitle = _readProgramString('sub_title');

    final programDescription = _readProgramString('desc');

    final programCategory = _readProgramString('category_name');

    final imageUrl = _programImageUrl();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // HANDLE
            // ====================================================

            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // IMAGE PROGRAMME
            // ====================================================
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 168 / 130,
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    headers: const {'Accept': 'image/*'},
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: Colors.white38,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return Container(
                        color: Colors.white.withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],

            // ====================================================
            // CHANNEL HEADER
            // ====================================================
            Row(
              children: [
                Container(
                  width: 58,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${channel.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        channel.isAvailable
                            ? 'Disponible'
                            : 'Abonnement requis',
                        style: TextStyle(
                          color: channel.isAvailable
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ====================================================
            // CURRENT PROGRAM
            // ====================================================
            if (programTitle != null) ...[
              const SizedBox(height: 20),

              const Text(
                'Programme en cours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                programTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (programSubTitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  programSubTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 14,
                  ),
                ),
              ],

              if (programCategory != null) ...[
                const SizedBox(height: 6),
                Text(
                  programCategory,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
              ],

              if (programDescription != null) ...[
                const SizedBox(height: 8),
                Text(
                  programDescription,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    height: 1.35,
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],

            // ====================================================
            // CHANNEL DESCRIPTION
            // ====================================================
            if (description != null) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),
            ],

            // ====================================================
            // BUTTONS
            // ====================================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.dialpad),
                    label: const Text('Sélectionner'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: channel.isAvailable ? onPlay : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Regarder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DETAIL ROW
// ================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
