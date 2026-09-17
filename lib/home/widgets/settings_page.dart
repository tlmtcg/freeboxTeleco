import 'package:flutter/material.dart';

import '../../app/app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réglages',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 30),

          const Text(
            'Choisir la télécommande',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 12),

          DropdownButton<String>(
            value: appConfig.remoteType,

            dropdownColor: const Color(0xFF1A2233),

            style: const TextStyle(color: Colors.white, fontSize: 18),

            items: const [
              DropdownMenuItem(value: 'delta', child: Text('Freebox Delta')),
              DropdownMenuItem(value: 'pop', child: Text('Freebox Pop')),
              DropdownMenuItem(
                value: 'revolution',
                child: Text('Freebox Révolution'),
              ),
            ],

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                appConfig.remoteType = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
