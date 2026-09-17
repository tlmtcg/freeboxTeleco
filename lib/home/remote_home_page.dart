import 'package:flutter/material.dart';

import '../connection/freebox_connection_controller.dart';
import '../freebox_os.dart';
import '../podcast/api/podcast_api.dart';
import '../podcast/pages/podcast_page.dart';
import '../podcast/repository/podcast_repository.dart';
import '../remote/remote_delta.dart';
import '../remote/remote_pop.dart';
import '../remote/remote_revolution.dart';
import '../tv/pages/channels_page.dart';
import '../app/app_config.dart';

import 'widgets/connection_placeholder.dart';
import 'widgets/home_header.dart';
import 'widgets/home_navigation_bar.dart';
import 'widgets/settings_page.dart';

class RemoteHomePage extends StatefulWidget {
  final PodcastRepository repository;
  final PodcastApi podcastApi;

  const RemoteHomePage({
    super.key,
    required this.repository,
    required this.podcastApi,
  });

  @override
  State<RemoteHomePage> createState() => _RemoteHomePageState();
}

class _RemoteHomePageState extends State<RemoteHomePage> {
  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  int _selectedTab = 0;

  // ===========================================================================
  // FREEBOX OS
  // ===========================================================================

  final FreeboxOS freebox = FreeboxOS('mafreebox.freebox.fr');

  // ===========================================================================
  // CONNEXION
  // ===========================================================================

  late final FreeboxConnectionController _connection;

  @override
  void initState() {
    super.initState();

    _connection = FreeboxConnectionController();

    _connection.onStateChanged = _onConnectionChanged;

    _connection.connect();
  }

  // ===========================================================================
  // CONNECTION STATE
  // ===========================================================================

  void _onConnectionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _connectPlayer() async {
    await _connection.connect();
  }

  // ===========================================================================
  // COMMAND
  // ===========================================================================

  Future<void> _sendCommand(
    String label,
    Future<void> Function() command,
  ) async {
    if (!_connection.isConnected || _connection.hid == null) {
      _showMessage('Connectez d’abord le Player Delta');
      return;
    }

    try {
      await _connection.sendCommand(command);

      _showMessage(label);
    } catch (error) {
      debugPrint('Erreur commande "$label" : $error');

      _showMessage('Échec de l’envoi de $label');
    }
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  // ===========================================================================
  // REMOTE
  // ===========================================================================

  Widget _buildRemotePage() {
    final hid = _connection.hid;

    if (hid == null) {
      return ConnectionPlaceholder(
        isCheckingConnection: _connection.isCheckingConnection,
        connectionMessage: _connection.connectionMessage,
        onReconnect: _connectPlayer,
      );
    }

    switch (appConfig.remoteType) {
      case 'delta':
        return RemoteDelta(client: hid, send: _sendCommand);

      case 'pop':
        return RemotePop(client: hid, send: _sendCommand);

      case 'revolution':
        return RemoteRevolution(client: hid, send: _sendCommand);

      default:
        return RemoteDelta(client: hid, send: _sendCommand);
    }
  }

  // ===========================================================================
  // TV
  // ===========================================================================

  Widget _buildChannelsPage() {
    final hid = _connection.hid;

    if (hid == null) {
      return ConnectionPlaceholder(
        isCheckingConnection: _connection.isCheckingConnection,
        connectionMessage: _connection.connectionMessage,
        onReconnect: _connectPlayer,
      );
    }

    return ChannelsPage(freebox: freebox, player: hid);
  }

  // ===========================================================================
  // PODCAST / APPS
  // ===========================================================================

  Widget _buildAppsPage() {
    return PodcastPage(
      repository: widget.repository,
      podcastApi: widget.podcastApi,
    );
  }

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  Widget _buildContent() {
    return switch (_selectedTab) {
      0 => _buildRemotePage(),
      1 => _buildAppsPage(),
      2 => _buildChannelsPage(),
      3 => const SettingsPage(),
      _ => _buildRemotePage(),
    };
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _connection.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              connectionMessage: _connection.connectionMessage,
              isConnected: _connection.isConnected,
              isCheckingConnection: _connection.isCheckingConnection,
              onReconnect: _connectPlayer,
            ),

            Expanded(child: _buildContent()),
          ],
        ),
      ),

      bottomNavigationBar: HomeNavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }
}
