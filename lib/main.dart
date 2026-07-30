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
  final String coverUrl;

  const GameModel({
    required this.id,
    required this.title,
    required this.system,
    required this.sizeMb,
    required this.isHeavy,
    required this.badgeColor,
    required this.ejsCore,
    required this.demoRomUrl,
    required this.coverUrl,
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
          return 'psx';
        case 'N64':
          return 'n64';
        case 'PSP':
          return 'psp';
        case 'MEGADRIVE':
          return 'segaMD';
        default:
          return 'snes';
      }
    }

    return GameModel(
      id: json['id'] ?? 'snes-mario-world',
      title: json['title'] ?? 'Jogo Retrô',
      system: json['system'] ?? 'SNES',
      sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 1.2,
      isHeavy: json['isHeavy'] ?? false,
      badgeColor: getSystemColor(json['system'] ?? ''),
      ejsCore: json['ejsCore'] ?? getEjsCore(json['system'] ?? ''),
      demoRomUrl: json['demoRomUrl'] ?? 'https://archive.org/download/super-mario-world-usa/Super%20Mario%20World%20%28USA%29.sfc',
      coverUrl: json['coverUrl'] ?? 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x7d.jpg',
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
    } catch (e, stack) {
      debugPrint('[SESSION CHECK ERROR]: $e');
      debugPrint(stack.toString());
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
    } catch (e, stack) {
      debugPrint('[FETCH GAMES ERROR]: $e');
      debugPrint(stack.toString());
      setState(() {
        _isLoadingGames = false;
        _isServerConnected = false;
      });
    }
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
    } catch (e, stack) {
      debugPrint('[REWARD AD ERROR]: $e');
      debugPrint(stack.toString());
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
                    _isServerConnected ? 'ONLINE' : 'OFFLINE',
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
              onPressed: () => setState(() => _isVipUser = true),
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
                    hintText: 'Buscar Super Mario, Donkey Kong, RE, Zelda...',
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
                      _buildSystemFilterTab('N64', 'Nintendo 64'),
                      _buildSystemFilterTab('PS1', 'PlayStation 1'),
                      _buildSystemFilterTab('PSP', 'PSP'),
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
                          maxCrossAxisExtent: 210,
                          childAspectRatio: 0.68,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
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
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(
                      game.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.gamepad_rounded, size: 48, color: game.badgeColor.withOpacity(0.5)),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: game.badgeColor,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
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
                        color: Colors.black.withOpacity(0.85),
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
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Core: ${game.ejsCore}',
                  style: const TextStyle(fontSize: 9, color: Color(0xFFA09CB0)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF).withOpacity(0.15),
                      side: const BorderSide(color: Color(0xFF00F0FF)),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF00F0FF), size: 14),
                    label: const Text(
                      'JOGAR AGORA',
                      style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                    onPressed: () => _startGameAndLaunch(context, game),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startGameAndLaunch(BuildContext context, GameModel game) async {
    if (!_isVipUser) {
      bool adWatched = await AdService.showRewardedAd(
        context,
        'Iniciar ${game.title}',
        seconds: 5,
      );
      if (!adWatched) return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealEmulatorScreen(
          gameId: game.id,
          gameTitle: game.title,
          systemName: game.system,
          ejsCore: game.ejsCore,
          romUrl: game.demoRomUrl,
          isVipUser: _isVipUser,
        ),
      ),
    );
  }
}

class RealEmulatorScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final String systemName;
  final String ejsCore;
  final String romUrl;
  final bool isVipUser;

  const RealEmulatorScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.systemName,
    required this.ejsCore,
    required this.romUrl,
    this.isVipUser = false,
  });

  @override
  State<RealEmulatorScreen> createState() => _RealEmulatorScreenState();
}

class _RealEmulatorScreenState extends State<RealEmulatorScreen> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Previne o erro "ViewFactory already registered" gerando ID único com timestamp
    _viewId = 'emulatorjs-view-${widget.gameId}-${DateTime.now().microsecondsSinceEpoch}';

    final String encodedRomUrl = Uri.encodeComponent(widget.romUrl);
    final String finalRomUrl = '$kApiBaseUrl/proxy-rom?url=$encodedRomUrl';

    debugPrint('=== RETROPLAY EMULATOR LAUNCH ===');
    debugPrint('Game: ${widget.gameTitle}');
    debugPrint('Original ROM URL: ${widget.romUrl}');
    debugPrint('Final Proxy URL: $finalRomUrl');

    if (kIsWeb) {
      final String safeGameTitle = widget.gameTitle.replaceAll("'", "\\'");
      final String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html { margin:0; padding:0; width:100%; height:100%; overflow:hidden; background:#000; }
            #emulator { width:100%; height:100%; }
          </style>
        </head>
        <body>
          <div id="emulator"></div>
          <script type="text/javascript">
            EJS_player = '#emulator';
            EJS_core = '${widget.ejsCore}';
            EJS_gameName = '$safeGameTitle';
            EJS_color = '#00F0FF';
            EJS_startOnLoaded = true;
            EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/';
            EJS_gameUrl = '$finalRomUrl';
          </script>
          <script src="https://cdn.emulatorjs.org/stable/data/loader.js"></script>
        </body>
        </html>
      ''';

      final blob = html.Blob([htmlContent], 'text/html');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allow', 'autoplay; gamepad; fullscreen; accelerometer; gyroscope')
          ..src = blobUrl;
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141024),
        title: Text('${widget.gameTitle} (${widget.systemName})', style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: kIsWeb
            ? HtmlElementView(viewType: _viewId)
            : const Text('Disponível no Web App!', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}