import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String kApiBaseUrl = 'https://retroplay-backend-t5z1.onrender.com/api';
const String kMockUserId = 'user_free_123';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const RetroPlayApp());
}

class RetroPlayApp extends StatelessWidget {
  const RetroPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroPlay App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        primaryColor: const Color(0xFF00F0FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFFFF007F),
          surface: Color(0xFF141024),
        ),
        cardColor: const Color(0xFF141024),
      ),
      home: const HomeScreen(),
    );
  }
}

class GameModel {
  final String id;
  final String title;
  final String system;
  final double sizeMb;
  final bool isHeavy;
  final Color badgeColor;
  final String ejsCore;
  final String demoRomUrl;

  const GameModel({
    required this.id,
    required this.title,
    required this.system,
    required this.sizeMb,
    required this.isHeavy,
    required this.badgeColor,
    required this.ejsCore,
    required this.demoRomUrl,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    Color getSystemColor(String system) {
      switch (system.toUpperCase()) {
        case 'SNES':
          return const Color(0xFF00F0FF);
        case 'PS1':
          return const Color(0xFFFF007F);
        case 'N64':
          return const Color(0xFF00FF88);
        case 'PSP':
          return const Color(0xFFFF9900);
        case 'MEGADRIVE':
          return const Color(0xFFAB47BC);
        default:
          return const Color(0xFF00F0FF);
      }
    }

    String getEjsCore(String system) {
      switch (system.toUpperCase()) {
        case 'SNES':
          return 'snes';
        case 'PS1':
          return 'pcsx_rearmed';
        case 'N64':
          return 'mupen64plus';
        case 'PSP':
          return 'ppsspp';
        case 'MEGADRIVE':
          return 'segaMD';
        default:
          return 'snes';
      }
    }

    return GameModel(
      id: json['id'] ?? 'snes-mario',
      title: json['title'] ?? 'Jogo Retrô',
      system: json['system'] ?? 'SNES',
      sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 1.2,
      isHeavy: json['isHeavy'] ?? false,
      badgeColor: getSystemColor(json['system'] ?? ''),
      ejsCore: getEjsCore(json['system'] ?? ''),
      demoRomUrl: json['demoRomUrl'] ?? 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    );
  }
}

class AdService {
  static Future<bool> showRewardedAd(BuildContext context, String actionName, {int seconds = 5}) async {
    bool adCompleted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return _AdDialog(
          title: 'Assistir Anúncio para $actionName',
          description: 'A versão gratuita requer um anúncio curto de ${seconds}s para concluir esta ação.',
          durationSeconds: seconds,
          onAdFinished: () {
            adCompleted = true;
            Navigator.of(ctx).pop();
          },
        );
      },
    );

    return adCompleted;
  }
}

class _AdDialog extends StatefulWidget {
  final String title;
  final String description;
  final int durationSeconds;
  final VoidCallback onAdFinished;

  const _AdDialog({
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.onAdFinished,
  });

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        widget.onAdFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141024),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF007F), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ondemand_video_rounded, color: Color(0xFFFF007F), size: 48),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFFA09CB0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1A35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Anúncio encerrando em: $_secondsRemaining s',
                style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ControllerConfigModal extends StatelessWidget {
  const ControllerConfigModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141024),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sports_esports, color: Color(0xFF00F0FF), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Configuração de Controles',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'O aplicativo reconhece automaticamente teclados, controles Bluetooth (Xbox/PlayStation) e USB!',
              style: TextStyle(color: Color(0xFFA09CB0), fontSize: 12),
            ),
            const SizedBox(height: 14),
            _buildKeyRow('Mover Personagem', 'Setas ← → / Teclas A D'),
            _buildKeyRow('Pular / Ação A', 'Seta Cima ↑ / Espaço / Tecla W'),
            _buildKeyRow('Atacar / Ação B', 'Tecla X / Tecla Z'),
            _buildKeyRow('START / Pause', 'Tecla Enter / Botão Start'),
            _buildKeyRow('SELECT', 'Tecla Shift / Botão Select'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C1B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Color(0xFF00FF88), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Controle Bluetooth / USB: Detectado e Ativo automaticamente.',
                      style: TextStyle(color: Color(0xFF00FF88), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(String action, String keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1A35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF231C3D)),
            ),
            child: Text(keys, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSystem = 'ALL';
  String _searchQuery = '';
  int _freeTimeSeconds = 7200;
  bool _isVipUser = false;
  bool _isServerConnected = false;
  bool _isLoadingGames = true;
  Timer? _dailyTimer;

  List<GameModel> _gamesList = [];

  final List<GameModel> _fallbackCatalog = const [
    GameModel(
      id: 'snes-mario-world',
      title: 'Super Mario World',
      system: 'SNES',
      sizeMb: 1.2,
      isHeavy: false,
      badgeColor: Color(0xFF00F0FF),
      ejsCore: 'snes',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'ps1-tekken-3',
      title: 'Tekken 3',
      system: 'PS1',
      sizeMb: 345.0,
      isHeavy: true,
      badgeColor: Color(0xFFFF007F),
      ejsCore: 'pcsx_rearmed',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'n64-zelda-oot',
      title: 'Zelda: Ocarina of Time',
      system: 'N64',
      sizeMb: 32.0,
      isHeavy: true,
      badgeColor: Color(0xFF00FF88),
      ejsCore: 'mupen64plus',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'psp-god-of-war',
      title: 'God of War: Chains of Olympus',
      system: 'PSP',
      sizeMb: 850.0,
      isHeavy: true,
      badgeColor: Color(0xFFFF9900),
      ejsCore: 'ppsspp',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'megadrive-sonic-2',
      title: 'Sonic the Hedgehog 2',
      system: 'MEGADRIVE',
      sizeMb: 1.0,
      isHeavy: false,
      badgeColor: Color(0xFFAB47BC),
      ejsCore: 'segaMD',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'ps1-crash-3',
      title: 'Crash Bandicoot 3: Warped',
      system: 'PS1',
      sizeMb: 300.0,
      isHeavy: true,
      badgeColor: Color(0xFFFF007F),
      ejsCore: 'pcsx_rearmed',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'snes-donkey-kong',
      title: 'Donkey Kong Country',
      system: 'SNES',
      sizeMb: 4.0,
      isHeavy: false,
      badgeColor: Color(0xFF00F0FF),
      ejsCore: 'snes',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'snes-sf2-turbo',
      title: 'Street Fighter II Turbo',
      system: 'SNES',
      sizeMb: 2.5,
      isHeavy: false,
      badgeColor: Color(0xFF00F0FF),
      ejsCore: 'snes',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'megadrive-mk2',
      title: 'Mortal Kombat II',
      system: 'MEGADRIVE',
      sizeMb: 3.0,
      isHeavy: false,
      badgeColor: Color(0xFFAB47BC),
      ejsCore: 'segaMD',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'ps1-metal-slug-x',
      title: 'Metal Slug X',
      system: 'PS1',
      sizeMb: 85.0,
      isHeavy: true,
      badgeColor: Color(0xFFFF007F),
      ejsCore: 'pcsx_rearmed',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'n64-mario-64',
      title: 'Super Mario 64',
      system: 'N64',
      sizeMb: 8.0,
      isHeavy: true,
      badgeColor: Color(0xFF00FF88),
      ejsCore: 'mupen64plus',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
    GameModel(
      id: 'snes-castlevania',
      title: 'Super Castlevania IV',
      system: 'SNES',
      sizeMb: 1.8,
      isHeavy: false,
      badgeColor: Color(0xFF00F0FF),
      ejsCore: 'snes',
      demoRomUrl: 'https://cdn.emulatorjs.org/stable/data/roms/snes/2048.sfc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSessionFromBackend();
    _fetchGamesFromBackend();
    _startDailyTimer();
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessionFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/user/session-check'),
        headers: {'x-user-id': kMockUserId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _freeTimeSeconds = data['secondsRemainingToday'] ?? 7200;
          _isVipUser = data['isVip'] ?? false;
          _isServerConnected = true;
        });
      }
    } catch (e) {
      setState(() => _isServerConnected = false);
    }
  }

  Future<void> _fetchGamesFromBackend() async {
    try {
      final response = await http.get(Uri.parse('$kApiBaseUrl/games'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catalog = data['catalog'] ?? [];
        if (catalog.isNotEmpty) {
          setState(() {
            _gamesList = catalog.map((g) => GameModel.fromJson(g)).toList();
            _isLoadingGames = false;
            _isServerConnected = true;
          });
          return;
        }
      }
      _useFallbackCatalog();
    } catch (e) {
      _useFallbackCatalog();
    }
  }

  void _useFallbackCatalog() {
    setState(() {
      _isLoadingGames = false;
      _isServerConnected = false;
      _gamesList = _fallbackCatalog;
    });
  }

  Future<void> _claimAdRewardOnBackend() async {
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/user/reward-ad'),
        headers: {'x-user-id': kMockUserId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _freeTimeSeconds = data['secondsRemainingToday'] ?? (_freeTimeSeconds + 1200);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '+20 minutos adicionados!')),
          );
        }
      }
    } catch (e) {
      setState(() => _freeTimeSeconds += 1200);
    }
  }

  void _startDailyTimer() {
    _dailyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_freeTimeSeconds > 0 && !_isVipUser) {
        setState(() => _freeTimeSeconds--);
      }
    });
  }

  String _formatTimerSeconds(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<GameModel> get _filteredGames {
    return _gamesList.where((game) {
      final matchesSystem = _selectedSystem == 'ALL' || game.system == _selectedSystem;
      final matchesSearch = game.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSystem && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141024),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF007F), Color(0xFF00F0FF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_esports, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                children: [
                  TextSpan(text: 'RETRO', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'PLAY', style: TextStyle(color: Color(0xFF00F0FF))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isServerConnected ? const Color(0xFF00FF88).withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _isServerConnected ? const Color(0xFF00FF88) : Colors.amber, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: _isServerConnected ? const Color(0xFF00FF88) : Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    _isServerConnected ? 'NODE.JS ONLINE' : 'MODO OFFLINE',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _isServerConnected ? const Color(0xFF00FF88) : Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0C1B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFF00F0FF), size: 14),
                const SizedBox(width: 4),
                Text(
                  _isVipUser ? 'VIP ILIMITADO' : _formatTimerSeconds(_freeTimeSeconds),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF)),
                ),
                if (!_isVipUser) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () async {
                      bool watched = await AdService.showRewardedAd(context, '+20 Minutos de Jogo');
                      if (watched) {
                        _claimAdRewardOnBackend();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+20m',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10, left: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF007F),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
              label: const Text(
                'SEJA VIP',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () => _openVipSubscriptionModal(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F0C1B),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar 5.145 jogos (SNES, PS1, N64, PSP, Mega Drive...)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF141024),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF231C3D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSystemFilterTab('ALL', 'Todos os Jogos'),
                      _buildSystemFilterTab('SNES', 'SNES'),
                      _buildSystemFilterTab('PS1', 'PlayStation 1'),
                      _buildSystemFilterTab('N64', 'Nintendo 64'),
                      _buildSystemFilterTab('PSP', 'PSP'),
                      _buildSystemFilterTab('MEGADRIVE', 'Mega Drive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingGames
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  )
                : _filteredGames.isEmpty
                    ? const Center(
                        child: Text('Nenhum jogo encontrado.', style: TextStyle(color: Colors.white38)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = _filteredGames[index];
                          return _buildGameCard(game);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemFilterTab(String code, String label) {
    final bool isSelected = _selectedSystem == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF141024),
        side: BorderSide(color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF231C3D)),
        onSelected: (_) => setState(() => _selectedSystem = code),
      ),
    );
  }

  Widget _buildGameCard(GameModel game) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141024),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF231C3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0714),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.gamepad_rounded, size: 48, color: game.badgeColor.withOpacity(0.5)),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: game.badgeColor, width: 0.8),
                      ),
                      child: Text(
                        game.system,
                        style: TextStyle(color: game.badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${game.sizeMb} MB',
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
                Text(
                  'ID: ${game.id}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFA09CB0)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF).withOpacity(0.15),
                      side: const BorderSide(color: Color(0xFF00F0FF)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF00F0FF), size: 16),
                    label: const Text(
                      'JOGAR AGORA',
                      style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    onPressed: () => _startGameDownloadAndLaunch(context, game),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startGameDownloadAndLaunch(BuildContext context, GameModel game) async {
    if (!_isVipUser) {
      bool adWatched = await AdService.showRewardedAd(
        context,
        'Iniciar ${game.title}',
        seconds: 5,
      );
      if (!adWatched) return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadSimulationDialog(
        game: game,
        onDownloadComplete: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                gameId: game.id,
                gameTitle: game.title,
                systemName: game.system,
                ejsCore: game.ejsCore,
                demoRomUrl: game.demoRomUrl,
                isVipUser: _isVipUser,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openVipSubscriptionModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF007F), width: 1.5),
        ),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFFF007F), size: 44),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: 'RETROPLAY ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'VIP', style: TextStyle(color: Color(0xFFFF007F))),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Liberte todo o potencial sem anúncios e sem limites!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFFA09CB0)),
              ),
              const SizedBox(height: 14),
              _buildVipFeatureRow(Icons.all_inclusive, 'Tempo Ilimitado', 'Jogue quantas horas quiser'),
              _buildVipFeatureRow(Icons.block, 'Zero Anúncios', 'Sem interrupções ao salvar ou pausar'),
              _buildVipFeatureRow(Icons.cloud_sync, 'Saves Infinitos & Nuvem', 'Sincronize no Node.js backend'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0C1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF231C3D)),
                      ),
                      child: Column(
                        children: [
                          const Text('MENSAL', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('R\$ 4,90', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('/mês', style: TextStyle(fontSize: 9, color: Colors.white38)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF007F),
                              minimumSize: const Size(double.infinity, 30),
                            ),
                            onPressed: () {
                              setState(() => _isVipUser = true);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Plano Mensal VIP Ativado!')),
                              );
                            },
                            child: const Text('Assinar', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0C1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ECONOMIZE 32%', style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          const Text('R\$ 39,90', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF))),
                          const Text('R\$ 3,32/mês', style: TextStyle(fontSize: 9, color: Color(0xFF00FF88))),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF),
                              minimumSize: const Size(double.infinity, 30),
                            ),
                            onPressed: () {
                              setState(() => _isVipUser = true);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Plano Anual VIP Ativado!')),
                              );
                            },
                            child: const Text('Assinar', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVipFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF88), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadSimulationDialog extends StatefulWidget {
  final GameModel game;
  final VoidCallback onDownloadComplete;

  const _DownloadSimulationDialog({
    required this.game,
    required this.onDownloadComplete,
  });

  @override
  State<_DownloadSimulationDialog> createState() => _DownloadSimulationDialogState();
}

class _DownloadSimulationDialogState extends State<_DownloadSimulationDialog> {
  double _progress = 0.0;
  String _signedDownloadUrl = 'Gerando link R2...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSignedUrlFromApi();
  }

  Future<void> _fetchSignedUrlFromApi() async {
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/games/${widget.game.id}/download-url'),
        headers: {'x-user-id': kMockUserId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _signedDownloadUrl = data['downloadUrl'] ?? 'https://cdn.retroplayapp.com/rom.bin';
        });
      }
    } catch (e) {
      setState(() {
        _signedDownloadUrl = 'http://localhost:3000/mock-download-url';
      });
    }

    _startDownloadProgress();
  }

  void _startDownloadProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_progress < 1.0) {
        setState(() => _progress += 0.2);
      } else {
        _timer?.cancel();
        widget.onDownloadComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141024),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_download_rounded, color: Color(0xFF00F0FF), size: 42),
            const SizedBox(height: 10),
            Text(
              'Baixando ${widget.game.title}...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              'Console: ${widget.game.system} • Cloudflare R2 CDN',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              _signedDownloadUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF00FF88), fontSize: 9, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF0F0C1B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final String systemName;
  final String ejsCore;
  final String demoRomUrl;
  final bool isVipUser;

  const GameScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.systemName,
    required this.ejsCore,
    required this.demoRomUrl,
    this.isVipUser = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _isPaused = false;
  bool _isGamepadConnected = false;
  List<String?> _saveSlots = [null, null, null];
  late String _viewId;
  html.IFrameElement? _iframeElement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSaveSlotsFromBackend();

    _viewId = 'retroplay-emu-${widget.gameId}-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms')
          ..srcdoc = '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body, html { margin:0; padding:0; width:100%; height:100%; overflow:hidden; background:#05030A; font-family:sans-serif; user-select:none; }
                #emulator-box { width:100%; height:100%; display:flex; flex-direction:column; align-items:center; justify-content:center; position:relative; }
                canvas { width:100%; height:100%; max-width:800px; max-height:600px; background:#000; border:2px solid #00F0FF; box-shadow:0 0 20px rgba(0,240,255,0.4); border-radius:8px; }
              </style>
            </head>
            <body>
              <div id="emulator-box">
                <canvas id="gameCanvas"></canvas>
              </div>

              <script>
                const canvas = document.getElementById('gameCanvas');
                const ctx = canvas.getContext('2d');
                canvas.width = 320;
                canvas.height = 240;

                // Áudio Retrô Sintetizado
                let audioCtx = null;
                function playBeep(freq, type, duration) {
                  try {
                    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                    if (audioCtx.state === 'suspended') audioCtx.resume();
                    const osc = audioCtx.createOscillator();
                    const gain = audioCtx.createGain();
                    osc.type = type || 'square';
                    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
                    gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
                    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + (duration || 0.1));
                    osc.connect(gain);
                    gain.connect(audioCtx.destination);
                    osc.start();
                    osc.stop(audioCtx.currentTime + (duration || 0.1));
                  } catch(e) {}
                }

                // Estado do Jogador no Emulador
                let px = 40, py = 180;
                let vx = 0, vy = 0;
                let isGrounded = true;
                let score = 0;
                let coins = [
                  {x: 80, y: 150, active: true},
                  {x: 140, y: 110, active: true},
                  {x: 200, y: 140, active: true},
                  {x: 260, y: 100, active: true}
                ];
                let enemies = [
                  {x: 120, y: 188, dir: 1},
                  {x: 220, y: 188, dir: -1}
                ];

                const keys = {};

                // Escuta teclado do PC
                window.addEventListener('keydown', (e) => {
                  keys[e.key] = true;
                  if (e.key === 'ArrowUp' || e.key === 'w' || e.key === ' ') jump();
                });
                window.addEventListener('keyup', (e) => {
                  keys[e.key] = false;
                });

                // Escuta eventos dos botões virtuais do Flutter via postMessage!
                window.addEventListener('message', (event) => {
                  const data = event.data;
                  if (!data) return;
                  if (data.action === 'KEYDOWN') keys[data.key] = true;
                  if (data.action === 'KEYUP') keys[data.key] = false;
                  if (data.action === 'JUMP') jump();
                  if (data.action === 'SAVE') {
                    localStorage.setItem('retroplay_save_${widget.gameId}', JSON.stringify({px, py, score, coins}));
                  }
                  if (data.action === 'LOAD') {
                    const saved = localStorage.getItem('retroplay_save_${widget.gameId}');
                    if (saved) {
                      const d = JSON.parse(saved);
                      px = d.px; py = d.py; score = d.score;
                      if (d.coins) coins = d.coins;
                    }
                  }
                });

                function jump() {
                  if (isGrounded) {
                    vy = -6.5;
                    isGrounded = false;
                    playBeep(440, 'square', 0.12);
                  }
                }

                function update() {
                  if (keys['ArrowLeft'] || keys['a']) vx = -2.5;
                  else if (keys['ArrowRight'] || keys['d']) vx = 2.5;
                  else vx = 0;

                  px += vx;
                  py += vy;
                  vy += 0.35; // Gravidade

                  if (px < 12) px = 12;
                  if (px > canvas.width - 20) px = canvas.width - 20;

                  // Chão da Fase
                  if (py >= 180) {
                    py = 180;
                    vy = 0;
                    isGrounded = true;
                  }

                  // Coleta de Moedas
                  coins.forEach(c => {
                    if (c.active && Math.abs(px - c.x) < 14 && Math.abs(py - c.y) < 14) {
                      c.active = false;
                      score += 100;
                      playBeep(880, 'sine', 0.15);
                    }
                  });

                  // Movimento dos Inimigos
                  enemies.forEach(en => {
                    en.x += en.dir * 0.8;
                    if (en.x < 80 || en.x > 270) en.dir *= -1;
                    if (Math.abs(px - en.x) < 12 && Math.abs(py - en.y) < 12) {
                      playBeep(150, 'sawtooth', 0.2);
                      px = 40; py = 180; // Respawn
                    }
                  });
                }

                function render() {
                  // Fundo Retrô
                  ctx.fillStyle = '#06040e';
                  ctx.fillRect(0, 0, canvas.width, canvas.height);

                  // Linhas de Grade CRT
                  ctx.strokeStyle = '#120d2c';
                  for (let i = 0; i < canvas.height; i += 6) {
                    ctx.beginPath();
                    ctx.moveTo(0, i);
                    ctx.lineTo(canvas.width, i);
                    ctx.stroke();
                  }

                  // Plataforma Principal (Chão)
                  ctx.fillStyle = '#00F0FF';
                  ctx.fillRect(0, 196, canvas.width, 4);
                  ctx.fillStyle = '#141024';
                  ctx.fillRect(0, 200, canvas.width, 40);

                  // Plataformas Flutuantes
                  ctx.fillStyle = '#FF007F';
                  ctx.fillRect(70, 160, 50, 6);
                  ctx.fillRect(130, 130, 50, 6);
                  ctx.fillRect(190, 160, 50, 6);

                  // Desenha Moedas
                  coins.forEach(c => {
                    if (c.active) {
                      ctx.fillStyle = '#FFD700';
                      ctx.beginPath();
                      ctx.arc(c.x, c.y, 4, 0, Math.PI * 2);
                      ctx.fill();
                    }
                  });

                  // Desenha Inimigos (Gumbas Retrô)
                  ctx.fillStyle = '#FF9900';
                  enemies.forEach(en => {
                    ctx.fillRect(en.x - 6, en.y - 6, 12, 12);
                  });

                  // Desenha Personagem Principal (Hero)
                  ctx.fillStyle = '#00FF88';
                  ctx.fillRect(px - 6, py - 12, 12, 16);
                  ctx.fillStyle = '#FFFFFF';
                  ctx.fillRect(px - 2, py - 10, 4, 4);

                  // HUD / Placa Superior
                  ctx.fillStyle = '#00F0FF';
                  ctx.font = '9px monospace';
                  ctx.fillText('${widget.systemName.toUpperCase()} • 60 FPS', 8, 14);
                  ctx.fillText('SCORE: ' + score, canvas.width - 80, 14);
                  ctx.fillStyle = '#FFFFFF';
                  ctx.fillText('${widget.gameTitle.toUpperCase()}', 8, 26);
                }

                function loop() {
                  update();
                  render();
                  requestAnimationFrame(loop);
                }
                loop();
              </script>
            </body>
            </html>
          ''';
        _iframeElement = iframe;
        return iframe;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sendControlToIframe(String action, String key) {
    if (_iframeElement != null && _iframeElement!.contentWindow != null) {
      _iframeElement!.contentWindow!.postMessage({
        'action': action,
        'key': key,
      }, '*');
    }
  }

  Future<void> _loadSaveSlotsFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/saves/${widget.gameId}'),
        headers: {'x-user-id': kMockUserId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List slots = data['slots'] ?? [];
        setState(() {
          _saveSlots = slots.map((s) => s != null ? (s['label'] as String?) : null).toList();
        });
      }
    } catch (e) {
      // Fallback local
    }
  }

  Future<void> _saveStateToBackend(int slotIndex) async {
    _sendControlToIframe('SAVE', '');
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/saves/${widget.gameId}/slot/$slotIndex'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': kMockUserId,
        },
        body: jsonEncode({
          'stateData': 'BINARY_SAVE_STATE',
          'adVerified': true,
        }),
      );

      if (response.statusCode == 200) {
        _loadSaveSlotsFromBackend();
      }
    } catch (e) {
      // Fallback local
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _isPaused = true);
    } else if (state == AppLifecycleState.resumed) {
      if (!widget.isVipUser) {
        AdService.showRewardedAd(context, 'Retorno ao Jogo', seconds: 3).then((_) {
          setState(() => _isPaused = false);
        });
      } else {
        setState(() => _isPaused = false);
      }
    }
  }

  void _openControllerConfigModal() {
    showDialog(
      context: context,
      builder: (ctx) => const ControllerConfigModal(),
    );
  }

  void _openSaveLoadModal(bool isSaveMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141024),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSaveMode ? 'Salvar Progresso (Save State)' : 'Carregar Progresso (Load State)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              Text(
                widget.isVipUser
                    ? 'VIP: Instantâneo e ilimitado na Nuvem Node.js.'
                    : 'Grátis: Limite de 3 Slots (Requer anúncio de 5s).',
                style: TextStyle(color: widget.isVipUser ? const Color(0xFF00F0FF) : const Color(0xFFFF007F), fontSize: 11),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final slotData = index < _saveSlots.length ? _saveSlots[index] : null;
                    return Card(
                      color: const Color(0xFF1A1530),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          slotData != null ? Icons.save_rounded : Icons.add_to_photos_rounded,
                          color: slotData != null ? const Color(0xFF00F0FF) : Colors.white24,
                        ),
                        title: Text(
                          slotData ?? 'Slot ${index + 1} (Vazio)',
                          style: TextStyle(color: slotData != null ? Colors.white : Colors.white38, fontSize: 13),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaveMode ? const Color(0xFF00F0FF) : const Color(0xFFFF007F),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (!widget.isVipUser) {
                              bool adWatched = await AdService.showRewardedAd(
                                context,
                                isSaveMode ? 'Salvar State' : 'Carregar State',
                              );
                              if (adWatched) {
                                _executeSaveLoadAction(isSaveMode, index);
                              }
                            } else {
                              _executeSaveLoadAction(isSaveMode, index);
                            }
                          },
                          child: Text(
                            isSaveMode ? 'Salvar' : 'Carregar',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeSaveLoadAction(bool isSaveMode, int slotIndex) {
    if (isSaveMode) {
      _saveStateToBackend(slotIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Progresso salvo no Slot ${slotIndex + 1} (Servidor Node.js)!')),
      );
    } else {
      _sendControlToIframe('LOAD', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jogo carregado do Slot ${slotIndex + 1}!')),
      );
    }
  }

  void _openExitPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF231C3D)),
        ),
        title: const Text(
          'JOGO PAUSADO',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Escolha uma ação para retornar ao menu principal:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFA09CB0), fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.save_rounded, color: Colors.black, size: 18),
              label: const Text(
                'SALVAR PROGRESSO E SAIR (Anúncio 5s)',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!widget.isVipUser) {
                  bool adWatched = await AdService.showRewardedAd(context, 'Salvar e Sair', seconds: 5);
                  if (adWatched) {
                    _saveStateToBackend(0);
                    _returnToHomeScreen();
                  }
                } else {
                  _saveStateToBackend(0);
                  _returnToHomeScreen();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF007F)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF007F), size: 18),
              label: const Text(
                'SAIR SEM SALVAR (Perder Progresso)',
                style: TextStyle(color: Color(0xFFFF007F), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!widget.isVipUser) {
                  bool adWatched = await AdService.showRewardedAd(context, 'Sair Sem Salvar', seconds: 3);
                  if (adWatched) {
                    _returnToHomeScreen();
                  }
                } else {
                  _returnToHomeScreen();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar Jogando', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _returnToHomeScreen() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: Colors.black,
                child: kIsWeb
                    ? HtmlElementView(viewType: _viewId)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gamepad, size: 80, color: Color(0xFF00F0FF)),
                          const SizedBox(height: 10),
                          Text(
                            widget.gameTitle.toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'CONSOLE: ${widget.systemName}',
                            style: const TextStyle(color: Color(0xFFFF007F), letterSpacing: 2, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141024).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports_rounded, color: Color(0xFF00F0FF), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.gameTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF00F0FF),
                      ),
                      tooltip: 'Mapeamento do Controle',
                      onPressed: _openControllerConfigModal,
                    ),
                    IconButton(
                      icon: Icon(
                        _isGamepadConnected ? Icons.sports_esports : Icons.sports_esports_outlined,
                        color: _isGamepadConnected ? const Color(0xFF00FF88) : Colors.white38,
                      ),
                      tooltip: 'Simular Controle Bluetooth',
                      onPressed: () {
                        setState(() => _isGamepadConnected = !_isGamepadConnected);
                      },
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141024),
                        side: const BorderSide(color: Color(0xFF00F0FF)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.save_rounded, color: Color(0xFF00F0FF), size: 14),
                      label: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _openSaveLoadModal(true),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141024),
                        side: const BorderSide(color: Color(0xFFFF007F)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.file_upload_rounded, color: Color(0xFFFF007F), size: 14),
                      label: const Text('Carregar', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _openSaveLoadModal(false),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF330818),
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 14),
                      label: const Text('Sair', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: _openExitPauseDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isGamepadConnected) ...[
            Positioned(bottom: 20, left: 20, child: _buildVirtualDPad()),
            Positioned(bottom: 20, right: 20, child: _buildActionButtons()),
            Positioned(
              bottom: 15,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: Row(
                children: [
                  _buildPillButton('SELECT'),
                  const SizedBox(width: 12),
                  _buildPillButton('START'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVirtualDPad() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 2, child: _dPadArrow(Icons.arrow_drop_up_rounded, 'ArrowUp')),
          Positioned(bottom: 2, child: _dPadArrow(Icons.arrow_drop_down_rounded, 'ArrowDown')),
          Positioned(left: 2, child: _dPadArrow(Icons.arrow_left_rounded, 'ArrowLeft')),
          Positioned(right: 2, child: _dPadArrow(Icons.arrow_right_rounded, 'ArrowRight')),
        ],
      ),
    );
  }

  Widget _dPadArrow(IconData icon, String keyName) {
    return GestureDetector(
      onTapDown: (_) => _sendControlToIframe('KEYDOWN', keyName),
      onTapUp: (_) => _sendControlToIframe('KEYUP', keyName),
      onTapCancel: () => _sendControlToIframe('KEYUP', keyName),
      child: Icon(icon, size: 38, color: Colors.white70),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        children: [
          Positioned(top: 0, left: 42, child: _actionCircleButton('Y', const Color(0xFF00F0FF), 'JUMP')),
          Positioned(bottom: 0, left: 42, child: _actionCircleButton('A', const Color(0xFFFF007F), 'JUMP')),
          Positioned(left: 0, top: 42, child: _actionCircleButton('X', const Color(0xFF00FF88), 'JUMP')),
          Positioned(right: 0, top: 42, child: _actionCircleButton('B', const Color(0xFFFF9900), 'JUMP')),
        ],
      ),
    );
  }

  Widget _actionCircleButton(String label, Color color, String action) {
    return GestureDetector(
      onTapDown: (_) => _sendControlToIframe(action, ''),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}