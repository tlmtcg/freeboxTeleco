import 'package:flutter/material.dart';

class PodcastAddRadioSearch extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool searching;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  const PodcastAddRadioSearch({
    super.key,
    required this.controller,
    required this.enabled,
    required this.searching,
    required this.onSearch,
    required this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter une radio',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            'Recherchez le nom d’une radio ou d’un podcast.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: 'Nom de la radio ou du podcast',
              hintText: 'France Inter',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: enabled ? onSearch : null,
              icon: searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(searching ? 'Recherche...' : 'Rechercher'),
            ),
          ),
        ],
      ),
    );
  }
}
