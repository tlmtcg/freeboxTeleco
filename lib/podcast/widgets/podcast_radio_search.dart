import 'package:flutter/material.dart';

class PodcastRadioSearch extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PodcastRadioSearch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un podcast',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    onChanged('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
