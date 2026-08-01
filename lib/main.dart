import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


/// Backend API Endpoint
const String kApiBaseUrl = 'https://retroplay-backend-t5z1.onrender.com/api';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for retro gaming (landscape & portrait)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(const RetroPlayApp());
}

/// Main Application Widget
class RetroPlayApp extends StatelessWidget {
  const RetroPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroPlay Cloud R2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        primaryColor: const Color(0xFF00F0FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFFFF007F),
          surface: Color(0xFF141024),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}


/// Game Model representing catalog items from Cloudflare R2
class GameModel {
  final String id;
  final String title;
  final String fullTitle;
  final String system;
  final String ejsCore;
  final String demoRomUrl;
  final String coverUrl;

  const GameModel({
    required this.id,
    required this.title,
    required this.fullTitle,
    required this.system,
    required this.ejsCore,
    required this.demoRomUrl,
    required this.coverUrl,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Jogo Sem Título',
      fullTitle: json['fullTitle'] ?? json['title'] ?? '',
      system: json['system'] ?? 'NES',
      ejsCore: json['ejsCore'] ?? 'nes',
      demoRomUrl: json['demoRomUrl'] ?? json['romUrl'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GameModel> _allGames = [];
  List<GameModel> _filteredGames = [];
  String _selectedSystem = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGamesCatalog();
  }

  /// Fetches game list from Node.js Express backend API
  Future<void> _fetchGamesCatalog() async {
    try {
      final response = await http.get(Uri.parse('$kApiBaseUrl/games'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catalogRaw = data['catalog'] ?? [];
        final parsedList = catalogRaw.map((e) => GameModel.fromJson(e)).toList();
        
        if (mounted) {
          setState(() {
            _allGames = parsedList;
            _applyFilters();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('[RETROPLAY API FETCH ERROR]: $e');
    }

    // Fallback Offline Catalog
    if (mounted) {
      setState(() {
        _allGames = const [
          GameModel(
            id: 'nes-mario-25th',
            title: '25th Anniversary Super Mario Bros.',
            fullTitle: '25th Anniversary Super Mario Bros. (Europe)',
            system: 'NES',
            ejsCore: 'nes',
            demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/NES/ROMS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe).nes',
            coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/NES/CAPAS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe).png',
          ),
          GameModel(
            id: 'snes-mario-world',
            title: 'Super Mario World',
            fullTitle: 'Super Mario World (USA)',
            system: 'SNES',
            ejsCore: 'snes',
            demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/ROMS/Super%20Mario%20World.sfc',
            coverUrl: '',
          ),
          GameModel(
            id: 'md-aladdin',
            title: 'Disney\'s Aladdin',
            fullTitle: 'Aladdin (USA)',
            system: 'MEGADRIVE',
            ejsCore: 'segaMD',
            demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/ROMS/Aladdin%20(USA).md',
            coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/CAPA/Aladdin.png',
          ),
          GameModel(
            id: 'ps2-black',
            title: 'Black',
            fullTitle: 'Black (USA)',
            system: 'PS2',
            ejsCore: 'play',
            demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/PS2/ROMS/Black.iso',
            coverUrl: '',
          ),
        ];
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredGames = _allGames.where((game) {
        final matchesSystem = _selectedSystem == 'ALL' || game.system == _selectedSystem;
        final matchesSearch = _searchQuery.isEmpty || 
            game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            game.fullTitle.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSystem && matchesSearch;
      }).toList();
    });
  }

  void _filterSystem(String system) {
    _selectedSystem = system;
    _applyFilters();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_esports, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('RETROPLAY CLOUD R2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF141024),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0C1B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Color(0xFF00F0FF), size: 16),
                const SizedBox(width: 6),
                Text('${_filteredGames.length} Jogos', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF141024),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar jogo por nome (ex: Mario, Sonic, Tekken, Black)...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F0FF)),
                    filled: true,
                    fillColor: const Color(0xFF0F0C1B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'Todos os Jogos', Icons.apps_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('NES', 'Nintendo (NES)', Icons.tv_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('SNES', 'Super Nintendo', Icons.gamepad_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('MEGADRIVE', 'Mega Drive', Icons.disc_full_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('PS1', 'PlayStation 1', Icons.album_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('PS2', 'PlayStation 2', Icons.videogame_asset_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : _filteredGames.isEmpty
                    ? const Center(child: Text('Nenhum jogo encontrado.', style: TextStyle(color: Colors.white54)))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = _filteredGames[index];
                            return _buildGameCard(game);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String systemCode, String label, IconData icon) {
    final bool isSelected = _selectedSystem == systemCode;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : const Color(0xFF00F0FF)),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF1F1A35),
      onSelected: (_) => _filterSystem(systemCode),
    );
  }

  Widget _buildGameCard(GameModel game) {
    final String proxiedCoverUrl = game.coverUrl.isNotEmpty
        ? '$kApiBaseUrl/proxy-rom/cover.png?url=${Uri.encodeComponent(game.coverUrl)}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141024),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF231C3D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                proxiedCoverUrl.isNotEmpty
                    ? Image.network(
                        proxiedCoverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackCardHeader(game),
                      )
                    : _buildFallbackCardHeader(game),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.6)),
                    ),
                    child: Text(
                      game.system,
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('JOGAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmulatorScreen(game: game),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCardHeader(GameModel game) {
    return Container(
      color: const Color(0xFF1F1A35),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports_rounded, color: Color(0xFF00F0FF), size: 38),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                game.system,
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Emulator Gameplay View supporting touch controls, save/load states, and hardware checks
class EmulatorScreen extends StatefulWidget {
  final GameModel game;
  final bool isVipUser;

  const EmulatorScreen({
    super.key,
    required this.game,
    this.isVipUser = false,
  });

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> with WidgetsBindingObserver {
  bool _isPaused = false;
  bool _isGamepadConnected = false;
  int _freeTimeSeconds = 7200; // 2 hours initial limit
  Timer? _sessionTimer;
  DateTime? _timeWhenPaused;

  final List<String?> _saveSlots = ['Slot 1: World 1-2 (12:40)', null, null];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSessionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timeWhenPaused = DateTime.now();
      setState(() => _isPaused = true);
    } else if (state == AppLifecycleState.resumed) {
      if (_timeWhenPaused != null) {
        final minutesAway = DateTime.now().difference(_timeWhenPaused!).inMinutes;
        if (minutesAway >= 10) {
          _closeSessionDueToInactivity();
          return;
        }
      }
      setState(() => _isPaused = false);
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_freeTimeSeconds > 0 && !_isPaused) {
        if (mounted) setState(() => _freeTimeSeconds--);
      } else if (_freeTimeSeconds == 0) {
        _timerExpiredDialog();
        timer.cancel();
      }
    });
  }

  void _closeSessionDueToInactivity() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141024),
        title: const Text('Sessão Encerrada por Inatividade', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Você ficou mais de 10 minutos fora do app. Seu progresso foi salvo e seu tempo diário permaneceu congelado!',
          style: TextStyle(color: Color(0xFFA09CB0)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF)),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isPaused = false);
            },
            child: const Text('Continuar Jogando', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _timerExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141024),
        title: const Text('Tempo Gratuito Esgotado!', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Você atingiu o limite de 2h hoje. Assista a um vídeo para ganhar +20 min (Máx 3x) ou torne-se VIP Ilimitado.',
          style: TextStyle(color: Color(0xFFA09CB0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _freeTimeSeconds += 1200);
            },
            child: const Text('Assistir Anúncio (+20 min)', style: TextStyle(color: Color(0xFF00F0FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF007F)),
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Seja VIP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSaveMode ? 'Salvar Progresso (Save State)' : 'Carregar Progresso (Load State)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isVipUser
                        ? 'VIP: Salvamento e carregamento instantâneos e ilimitados.'
                        : 'Grátis: Limite de 3 Slots. Requer exibição de 1 anúncio curto.',
                    style: TextStyle(color: widget.isVipUser ? const Color(0xFF00F0FF) : const Color(0xFFFF007F), fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final slotData = _saveSlots[index];
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
                              style: TextStyle(color: slotData != null ? Colors.white : Colors.white38),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSaveMode ? const Color(0xFF00F0FF) : const Color(0xFFFF007F),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _executeSaveLoadAction(isSaveMode, index);
                              },
                              child: Text(
                                isSaveMode ? 'Salvar' : 'Carregar',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      },
    );
  }

  void _executeSaveLoadAction(bool isSaveMode, int slotIndex) {
    setState(() {
      if (isSaveMode) {
        _saveSlots[slotIndex] = 'Slot ${slotIndex + 1}: Salvo às ${_formatTime(DateTime.now())}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Progresso salvo no Slot ${slotIndex + 1}!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jogo carregado do Slot ${slotIndex + 1}!')),
        );
      }
    });
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
          'Escolha uma ação antes de retornar ao menu principal:',
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
                'SALVAR PROGRESSO E SAIR',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExitAction(saved: true);
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
                style: TextStyle(color: Color(0xFFFF007F), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _executeExitAction(saved: false);
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

  void _executeExitAction({required bool saved}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: saved ? const Color(0xFF00F0FF) : const Color(0xFFFF007F),
        content: Text(
          saved ? 'Progresso salvo! Retornando...' : 'Saindo do jogo sem salvar...',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
    Navigator.pop(context);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimerSeconds(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.game.system == 'PS2') {
      return _buildPS2NoticeScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game Screen Simulation / Player Area
          Center(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: const Color(0xFF0A0814),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_esports_rounded, size: 70, color: Color(0xFF00F0FF)),
                        const SizedBox(height: 12),
                        Text(
                          widget.game.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CONSOLE: ${widget.game.system} • 60 FPS',
                          style: const TextStyle(color: Color(0xFFFF007F), letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_isPaused)
                      Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Text('EMULAÇÃO PAUSADA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Top Overlay Bar
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
                    color: const Color(0xFF141024).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF00F0FF), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.isVipUser ? 'VIP ILIMITADO' : _formatTimerSeconds(_freeTimeSeconds),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isGamepadConnected ? Icons.sports_esports : Icons.sports_esports_outlined,
                        color: _isGamepadConnected ? const Color(0xFF00F0FF) : Colors.white38,
                      ),
                      tooltip: 'Simular Controle Bluetooth',
                      onPressed: () {
                        setState(() => _isGamepadConnected = !_isGamepadConnected);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141024),
                        side: const BorderSide(color: Color(0xFF00F0FF)),
                      ),
                      icon: const Icon(Icons.save_rounded, color: Color(0xFF00F0FF), size: 16),
                      label: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () => _openSaveLoadModal(true),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141024),
                        side: const BorderSide(color: Color(0xFFFF007F)),
                      ),
                      icon: const Icon(Icons.file_upload_rounded, color: Color(0xFFFF007F), size: 16),
                      label: const Text('Carregar', style: TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () => _openSaveLoadModal(false),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF330818),
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 16),
                      label: const Text('Sair', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _openExitPauseDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),


          // Touch Gamepad Overlay
          if (!_isGamepadConnected) ...[
            Positioned(
              bottom: 25,
              left: 25,
              child: _buildVirtualDPad(),
            ),
            Positioned(
              bottom: 25,
              right: 25,
              child: _buildActionButtons(),
            ),
            Positioned(
              bottom: 15,
              left: MediaQuery.of(context).size.width / 2 - 70,
              child: Row(
                children: [
                  _buildPillButton('SELECT'),
                  const SizedBox(width: 15),
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
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 4, child: _dPadArrow(Icons.arrow_drop_up_rounded)),
          Positioned(bottom: 4, child: _dPadArrow(Icons.arrow_drop_down_rounded)),
          Positioned(left: 4, child: _dPadArrow(Icons.arrow_left_rounded)),
          Positioned(right: 4, child: _dPadArrow(Icons.arrow_right_rounded)),
        ],
      ),
    );
  }

  Widget _dPadArrow(IconData icon) {
    return InkWell(
      onTap: () {},
      child: Icon(icon, size: 38, color: Colors.white70),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Positioned(top: 0, left: 46, child: _actionCircleButton('Y', const Color(0xFF00F0FF))),
          Positioned(bottom: 0, left: 46, child: _actionCircleButton('A', const Color(0xFFFF007F))),
          Positioned(left: 0, top: 46, child: _actionCircleButton('X', const Color(0xFF00FF88))),
          Positioned(right: 0, top: 46, child: _actionCircleButton('B', const Color(0xFFFF9900))),
        ],
      ),
    );
  }

  Widget _actionCircleButton(String label, Color color) {
    return GestureDetector(
      onTapDown: (_) {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPS2NoticeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141024),
        title: Text(widget.game.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF141024),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF007F).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videogame_asset_rounded, color: Color(0xFFFF007F), size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                widget.game.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4)),
                ),
                child: const Text(
                  'PLAYSTATION 2 - REQUISITOS DE HARDWARE',
                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'A emulação de PlayStation 2 exige processamento gráfico 3D avançado e suporte nativo ao sistema operacional.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para executar este jogo no celular ou Smart TV sem travamentos, utilize o nosso cliente dedicado no APK Android.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('VOLTAR AO CATÁLOGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}