import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String kApiBaseUrl = 'https://retroplay-backend-t5z1.onrender.com/api';

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
      demoRomUrl: json['demoRomUrl'] ?? '',
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

  Future<void> _fetchGamesCatalog() async {
    try {
      final response = await http.get(Uri.parse('$kApiBaseUrl/games'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catalogRaw = data['catalog'] ?? [];
        final parsedList = catalogRaw.map((e) => GameModel.fromJson(e)).toList();
        setState(() {
          _allGames = parsedList;
          _applyFilters();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[FETCH CATALOG ERROR]: $e');
    }

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
          id: 'md-aladdin',
          title: 'Disney\'s Aladdin',
          fullTitle: 'Aladdin (USA)',
          system: 'MEGADRIVE',
          ejsCore: 'segaMD',
          demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/ROMS/Aladdin%20(USA).md',
          coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/CAPA/Aladdin.png',
        ),
      ];
      _applyFilters();
      _isLoading = false;
    });
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
                    hintText: 'Buscar jogo por nome (ex: Mario, Sonic, Tekken, Aladdin)...',
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
                          builder: (context) => SingleEmulatorView(game: game),
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

class SingleEmulatorView extends StatefulWidget {
  final GameModel game;

  const SingleEmulatorView({super.key, required this.game});

  @override
  State<SingleEmulatorView> createState() => _SingleEmulatorViewState();
}

class _SingleEmulatorViewState extends State<SingleEmulatorView> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'emulator-view-${DateTime.now().millisecondsSinceEpoch}';

    // PS2 is handled via dedicated notice UI below to avoid EmulatorJS CDN 404 core errors
    if (widget.game.system != 'PS2') {
      final String romProxyUrl = '$kApiBaseUrl/proxy-rom/game-rom?url=${Uri.encodeComponent(widget.game.demoRomUrl)}';

      final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body, html { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
        #game { width: 100%; height: 100%; }
    </style>
</head>
<body>
    <div id="game"></div>
    <script type="text/javascript">
        EJS_player = '#game';
        EJS_core = ${jsonEncode(widget.game.ejsCore)};
        EJS_gameName = ${jsonEncode(widget.game.title)};
        EJS_gameUrl = ${jsonEncode(romProxyUrl)};
        EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/';
    </script>
    <script src="https://cdn.emulatorjs.org/stable/data/loader.js"></script>
</body>
</html>
''';

      if (kIsWeb) {
        ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
          final iframe = html.IFrameElement()
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none'
            ..allowFullscreen = true
            ..srcdoc = htmlContent;
          return iframe;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141024),
        title: Text(widget.game.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: widget.game.system == 'PS2'
          ? _buildPS2NoticeScreen()
          : (kIsWeb
              ? HtmlElementView(viewType: _viewId)
              : const Center(
                  child: Text(
                    'Emulação Web disponível no navegador.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )),
    );
  }

  Widget _buildPS2NoticeScreen() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: const Color(0xFF0F0C1B),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141024),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withOpacity(0.2),
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
                  color: const Color(0xFFFF007F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videogame_asset_rounded, color: Color(0xFFFF007F), size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                widget.game.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5)),
                ),
                child: const Text(
                  'PLAYSTATION 2 - REQUISITOS DE HARDWARE',
                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A emulação de PlayStation 2 exige processamento gráfico 3D avançado e alocação de memória RAM (>4GB em WebAssembly).\n\nPara executar este jogo no navegador de Smart TV ou celular sem travamentos, utilize o nosso aplicativo nativo ou cliente dedicado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('VOLTAR AO CATÁLOGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}