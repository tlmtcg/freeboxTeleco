import 'package:flutter/material.dart';

class VideoSettingsPage extends StatefulWidget {
  const VideoSettingsPage({super.key});

  @override
  State<VideoSettingsPage> createState() => _VideoSettingsPageState();
}

class _VideoSettingsPageState extends State<VideoSettingsPage> {
  String _rtspTransport = 'udp';
  String _videoQuality = 'hd';
  String _audioLanguage = 'fra';
  bool _fullscreenOnStart = false;
  bool _showControlsOnStart = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B12),
        surfaceTintColor: Colors.transparent,
        title: const Text('Configuration vidéo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSectionTitle(context, 'Lecture'),

          _buildCard(
            children: [
              _buildDropdownTile<String>(
                icon: Icons.high_quality_outlined,
                title: 'Qualité préférée',
                subtitle: _qualityLabel(_videoQuality),
                value: _videoQuality,
                items: const [
                  DropdownMenuItem(value: 'hd', child: Text('HD')),
                  DropdownMenuItem(value: 'auto', child: Text('Automatique')),
                  DropdownMenuItem(value: 'sd', child: Text('SD')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _videoQuality = value;
                  });
                },
              ),

              const Divider(height: 1),

              _buildDropdownTile<String>(
                icon: Icons.swap_horiz,
                title: 'Transport RTSP',
                subtitle: _transportLabel(_rtspTransport),
                value: _rtspTransport,
                items: const [
                  DropdownMenuItem(value: 'udp', child: Text('UDP')),
                  DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _rtspTransport = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Audio'),

          _buildCard(
            children: [
              _buildDropdownTile<String>(
                icon: Icons.language,
                title: 'Langue audio',
                subtitle: _audioLanguageLabel(_audioLanguage),
                value: _audioLanguage,
                items: const [
                  DropdownMenuItem(value: 'fra', child: Text('Français')),
                  DropdownMenuItem(value: 'eng', child: Text('Anglais')),
                  DropdownMenuItem(value: 'deu', child: Text('Allemand')),
                  DropdownMenuItem(value: 'spa', child: Text('Espagnol')),
                  DropdownMenuItem(value: 'ita', child: Text('Italien')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _audioLanguage = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Affichage'),

          _buildCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fullscreen),
                title: const Text('Plein écran au démarrage'),
                subtitle: const Text(
                  'Masque automatiquement les éléments de l’interface',
                ),
                value: _fullscreenOnStart,
                onChanged: (value) {
                  setState(() {
                    _fullscreenOnStart = value;
                  });
                },
              ),

              const Divider(height: 1),

              SwitchListTile(
                secondary: const Icon(Icons.tune),
                title: const Text('Afficher les contrôles'),
                subtitle: const Text(
                  'Afficher la barre de contrôle au démarrage',
                ),
                value: _showControlsOnStart,
                onChanged: (value) {
                  setState(() {
                    _showControlsOnStart = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'À propos'),

          _buildCard(
            children: [
              const ListTile(
                leading: Icon(Icons.tv),
                title: Text('Lecteur TV Freebox'),
                subtitle: Text('Lecture des flux TV de la Freebox'),
              ),

              const Divider(height: 1),

              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFF111722),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF1A202C),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  String _qualityLabel(String value) {
    switch (value) {
      case 'hd':
        return 'HD';
      case 'sd':
        return 'SD';
      case 'auto':
        return 'Automatique';
      default:
        return value;
    }
  }

  String _transportLabel(String value) {
    switch (value) {
      case 'udp':
        return 'UDP';
      case 'tcp':
        return 'TCP';
      default:
        return value;
    }
  }

  String _audioLanguageLabel(String value) {
    switch (value) {
      case 'fra':
        return 'Français';
      case 'eng':
        return 'Anglais';
      case 'deu':
        return 'Allemand';
      case 'spa':
        return 'Espagnol';
      case 'ita':
        return 'Italien';
      default:
        return value;
    }
  }
}
