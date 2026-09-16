import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'core/freebox_player.dart';
import 'discovery/freebox_discovery.dart';
import 'network/freebox_socket.dart';
import 'rudp/rudp_client.dart';
import 'hid/hid_client.dart';

import 'freebox_os.dart';
import 'channels_page.dart';
import 'rudp/rudp_client.dart';
import 'rudp/rudp_packet.dart';

// Télécommandes
import 'remote/remote_pop.dart';
import 'remote/remote_delta.dart';
import 'remote/remote_revolution.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  runApp(const FreeboxRemoteApp());
}

class AppConfig {
  String remoteType = "delta"; // "delta" | "pop" | "revolution"
}

final appConfig = AppConfig();

class FreeboxRemoteApp extends StatelessWidget {
  const FreeboxRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Télécommande Freebox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B8CFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080B12),
        fontFamily: 'sans',
        useMaterial3: true,
      ),
      home: const RemoteHomePage(),
    );
  }
}

class RemoteHomePage extends StatefulWidget {
  const RemoteHomePage({super.key});

  @override
  State<RemoteHomePage> createState() => _RemoteHomePageState();
}

class _RemoteHomePageState extends State<RemoteHomePage> {
  // ============================================================
  // ÉTAT UI
  // ============================================================

  int _selectedTab = 0;

  bool _isConnected = false;
  bool _isCheckingConnection = true;

  String _connectionMessage =
      'Recherche de la Freebox sur le réseau local...';

  // ============================================================
  // FREEBOX OS
  // ============================================================

  final FreeboxOS freebox = FreeboxOS('mafreebox.freebox.fr');

  // ============================================================
  // NOUVELLE ARCHITECTURE
  // ============================================================

  final FreeboxDiscovery _discovery = FreeboxDiscovery();

  FreeboxSocket? _socket;
  RudpClient? _rudp;
  HidClient? _hid;
  FreeboxPlayer? _player;

  StreamSubscription<RudpPacket>? _rudpSubscription;

  @override
  void initState() {
    super.initState();

    _connectPlayer();
  }

  // ============================================================
  // CONNEXION PLAYER
  // ============================================================

  Future<void> _connectPlayer() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingConnection = true;
      _isConnected = false;
      _connectionMessage =
          'Recherche du Player Delta sur le réseau local...';
    });

    try {
      // ----------------------------------------------------------
      // Nettoyage d'une éventuelle ancienne connexion.
      // ----------------------------------------------------------

      await _disconnectPlayer();

      // ----------------------------------------------------------
      // DISCOVERY
      // ----------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('       RECHERCHE FREEBOX PLAYER');
      debugPrint('========================================');

      final player = await _discovery.discover();

      if (player == null) {
        throw StateError('Player Freebox introuvable.');
      }

      debugPrint(
        'Player trouvé : '
        '${player.address.address}:${player.port}',
      );

      // ----------------------------------------------------------
      // SOCKET
      // ----------------------------------------------------------

      final socket = FreeboxSocket();

      // ----------------------------------------------------------
      // RUDP
      // ----------------------------------------------------------

      final rudp = RudpClient(
        player: player,
        socket: socket,
      );

      // ----------------------------------------------------------
      // HID
      // ----------------------------------------------------------

      final hid = HidClient(rudp: rudp);

      _socket = socket;
      _rudp = rudp;
      _hid = hid;
      _player = player;

      // ----------------------------------------------------------
      // RÉCEPTION RUDP
      //
      // Le RUDP reçoit tous les paquets et les transmet sur
      // son Stream "received".
      // ----------------------------------------------------------

      _rudpSubscription = rudp.received.listen(
        (packet) {
          debugPrint(
            'MAIN <- RUDP '
            'cmd=0x${packet.command.toRadixString(16).padLeft(2, '0')}',
          );

          // ------------------------------------------------------
          // CONN_RSP
          // ------------------------------------------------------

          if (packet.command == RudpClient.rudpCmdConnRsp) {
            rudp.processConnectionResponse(packet);
          }

          // ------------------------------------------------------
          // HID
          //
          // HidClient filtre lui-même les commandes HID.
          // ------------------------------------------------------

          hid.processPacket(packet);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erreur stream RUDP : $error');
        },
      );

      // ----------------------------------------------------------
      // CONNEXION RUDP
      // ----------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('             CONNEXION RUDP');
      debugPrint('========================================');

      await rudp.connect();

      // ----------------------------------------------------------
      // CONN_REQ
      // ----------------------------------------------------------

      var reliableSequence = DateTime.now().millisecondsSinceEpoch & 0xFFFF;

      if (reliableSequence == 0) {
        reliableSequence = 1;
      }

      await rudp.sendConnectionRequest(
        reliableSequence: reliableSequence,
      );

      // ----------------------------------------------------------
      // ATTENTE CONN_RSP
      // ----------------------------------------------------------

      final connected = await _waitForRudpConnection(
        rudp,
        timeout: const Duration(seconds: 3),
      );

      if (!connected) {
        throw StateError(
          'Timeout ou refus de la connexion RUDP.',
        );
      }

      debugPrint('RUDP connecté.');

      // ----------------------------------------------------------
      // DEVICE_NEW
      // ----------------------------------------------------------

      debugPrint('');
      debugPrint('========================================');
      debugPrint('             HID DEVICE_NEW');
      debugPrint('========================================');

      await hid.sendDeviceNew();

      // ----------------------------------------------------------
      // ATTENTE HID READY
      // ----------------------------------------------------------

      final hidReady = await _waitForHidReady(
        hid,
        timeout: const Duration(seconds: 5),
      );

      if (!hidReady) {
        throw StateError(
          'Le Player n\'a pas activé les rapports HID nécessaires.',
        );
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('       HID CONNECTE AU FREEBOX PLAYER');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _isConnected = true;
        _isCheckingConnection = false;
        _connectionMessage =
            'Player Delta connecté '
            '(${player.address.address}:${player.port})';
      });
    } catch (error, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('         ERREUR CONNEXION');
      debugPrint('========================================');
      debugPrint('$error');
      debugPrint('$stackTrace');

      await _disconnectPlayer();

      if (!mounted) {
        return;
      }

      setState(() {
        _isConnected = false;
        _isCheckingConnection = false;
        _connectionMessage =
            'Player introuvable ou appairage refusé. '
            'Vérifiez le même Wi-Fi.';
      });
    }
  }

  // ============================================================
  // ATTENTE CONNEXION RUDP
  // ============================================================

  Future<bool> _waitForRudpConnection(
    RudpClient rudp, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (rudp.isConnected) {
        return true;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }

    return rudp.isConnected;
  }

  // ============================================================
  // ATTENTE HID
  // ============================================================

  Future<bool> _waitForHidReady(
    HidClient hid, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (hid.isReady) {
        return true;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }

    return hid.isReady;
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<void> _disconnectPlayer() async {
    await _rudpSubscription?.cancel();
    _rudpSubscription = null;

    _hid = null;

    _rudp?.disconnect();

    _rudp?.dispose();

    _rudp = null;
    _socket = null;
    _player = null;
  }

  // ============================================================
  // COMMANDE
  // ============================================================

  Future<void> _sendCommand(
    String label,
    Future<void> Function() command,
  ) async {
    if (!_isConnected || _hid == null) {
      _showMessage('Connectez d’abord le Player Delta');
      return;
    }

    try {
      await command();

      _showMessage(label);
    } catch (error) {
      debugPrint('Erreur commande "$label" : $error');

      _showMessage('Échec de l’envoi de $label');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String label) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(label),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disconnectPlayer();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: switch (_selectedTab) {
                0 => _buildRemoteByType(),
                1 => _buildAppsPage(),
                2 => _buildChannelsPage(),
                3 => _buildSettingsPage(),
                _ => _buildRemoteByType(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF17233F),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.satellite_alt_rounded,
              color: Color(0xFF8EAEFF),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Télécommande Freebox',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _connectionMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF81899B),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Changer de Freebox',
            onPressed: _isCheckingConnection
                ? null
                : _connectPlayer,
            icon: _isCheckingConnection
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isConnected
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                  ),
            color: _isConnected
                ? const Color(0xFF73E0B1)
                : const Color(0xFFFFB86B),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TÉLÉCOMMANDE
  // ============================================================

  Widget _buildRemoteByType() {
    final hid = _hid;

    if (hid == null) {
      return _buildConnectionPlaceholder();
    }

    switch (appConfig.remoteType) {
      case 'delta':
        return RemoteDelta(
          client: hid,
          send: _sendCommand,
        );

      case 'pop':
        return RemotePop(
          client: hid,
          send: _sendCommand,
        );

      case 'revolution':
        return RemoteRevolution(
          client: hid,
          send: _sendCommand,
        );

      default:
        return RemoteDelta(
          client: hid,
          send: _sendCommand,
        );
    }
  }

  // ============================================================
  // PAGE TV
  // ============================================================

  Widget _buildChannelsPage() {
    final hid = _hid;

    if (hid == null) {
      return _buildConnectionPlaceholder();
    }

    return ChannelsPage(
      freebox: freebox,
      player: hid,
    );
  }

  // ============================================================
  // PLACEHOLDER CONNEXION
  // ============================================================

  Widget _buildConnectionPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCheckingConnection
                  ? Icons.wifi_find_rounded
                  : Icons.wifi_off_rounded,
              size: 52,
              color: const Color(0xFF5B8CFF),
            ),

            const SizedBox(height: 18),

            Text(
              _isCheckingConnection
                  ? 'Connexion au Player Delta...'
                  : 'Player Delta non connecté',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _connectionMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF81899B),
              ),
            ),

            const SizedBox(height: 24),

            if (!_isCheckingConnection)
              FilledButton.icon(
                onPressed: _connectPlayer,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reconnecter'),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RÉGLAGES
  // ============================================================

  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réglages',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Choisir la télécommande',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          DropdownButton<String>(
            value: appConfig.remoteType,
            dropdownColor: const Color(0xFF1A2233),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            items: const [
              DropdownMenuItem(
                value: 'delta',
                child: Text('Freebox Delta'),
              ),
              DropdownMenuItem(
                value: 'pop',
                child: Text('Freebox Pop'),
              ),
              DropdownMenuItem(
                value: 'revolution',
                child: Text('Freebox Révolution'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  appConfig.remoteType = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPLICATIONS
  // ============================================================

  Widget _buildAppsPage() {
    return const Center(
      child: Text('Vide'),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedTab,

      onDestinationSelected: (index) {
        setState(() {
          _selectedTab = index;
        });
      },

      backgroundColor: const Color(0xFF0D111A),
      indicatorColor: const Color(0xFF1D356D),

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.gamepad_outlined),
          selectedIcon: Icon(Icons.gamepad_rounded),
          label: 'Télécommande',
        ),

        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps_rounded),
          label: 'Apps',
        ),

        NavigationDestination(
          icon: Icon(Icons.tv),
          selectedIcon: Icon(Icons.tv_rounded),
          label: 'TV',
        ),

        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'Réglages',
        ),
      ],
    );
  }
}

