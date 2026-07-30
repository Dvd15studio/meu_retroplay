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
  final String system;
  final String ejsCore;
  final String demoRomUrl;
  final String coverUrl;

  const GameModel({
    required this.id,
    required this.title,
    required this.system,
    required this.ejsCore,
    required this.demoRomUrl,
    required this.coverUrl,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Jogo Sem Título',
      system: json['system'] ?? 'SNES',
      ejsCore: json['ejsCore'] ?? 'snes',
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
          _filteredGames = parsedList;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[FETCH CATALOG ERROR]: $e');
    }

    // Fallback caso a API esteja indisponível
    setState(() {
      _allGames = const [
        GameModel(
          id: 'nes-mario-25th',
          title: '25th Anniversary Super Mario Bros.',
          system: 'NES',
          ejsCore: 'nes',
          demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/ROMS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe)%20(Promo%2C%20Virtual%20Console).nes',
          coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/CAPAS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe)%20(Promo%2C%20Virtual%20Console).png',
        ),
        GameModel(
          id: 'md-aladdin',
          title: 'Disney\'s Aladdin (Mega Drive)',
          system: 'MEGADRIVE',
          ejsCore: 'segaMD',
          demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/ROMS/Aladdin%20(USA).md',
          coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/CAPA/Aladdin.png',
        ),
      ];
      _filteredGames = List.from(_allGames);
      _isLoading = false;
    });
  }

  void _filterSystem(String system) {
    setState(() {
      _selectedSystem = system;
      if (system == 'ALL') {
        _filteredGames = List.from(_allGames);
      } else {
        _filteredGames = _allGames.where((game) => game.system == system).toList();
      }
    });
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
            child: const Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Color(0xFF00F0FF), size: 16),
                SizedBox(width: 6),
                Text('R2 Conectado', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'Todos os Jogos', Icons.apps_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('NES', 'Nintendo (NES)', Icons.tv_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('MEGADRIVE', 'Mega Drive', Icons.disc_full_rounded),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : _filteredGames.isEmpty
                    ? const Center(child: Text('Nenhum jogo encontrado nesta categoria.'))
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
    // Passa a capa pelo proxy do backend para bypass de CORS
    final String proxiedCoverUrl = '$kApiBaseUrl/proxy-rom?url=${Uri.encodeComponent(game.coverUrl)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141024),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF231C3D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
              children: [
                Positioned.fill(
                  child: Image.network(
                    proxiedCoverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1F1A35),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videogame_asset_rounded, size: 48, color: Color(0xFF00F0FF)),
                          SizedBox(height: 6),
                          Text('Capa do Jogo', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                    label: const Text(
                      'JOGAR',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleEmulatorView(game: game),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
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
    _viewId = 'emulator-r2-${DateTime.now().microsecondsSinceEpoch}';

    final String encodedRomUrl = Uri.encodeComponent(widget.game.demoRomUrl);
    final String proxyUrl = '$kApiBaseUrl/proxy-rom?url=$encodedRomUrl';

    if (kIsWeb) {
      final String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>body, html { margin:0; padding:0; width:100%; height:100%; background:#000; }</style>
        </head>
        <body>
          <div id="emulator" style="width:100%;height:100%;"></div>
          <script type="text/javascript">
            EJS_player = '#emulator';
            EJS_core = '${widget.game.ejsCore}';
            EJS_gameName = '${widget.game.title}';
            EJS_color = '#00F0FF';
            EJS_startOnLoaded = true;
            EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/';
            EJS_gameUrl = '$proxyUrl';
          </script>
          <script src="https://cdn.emulatorjs.org/stable/data/loader.js"></script>
        </body>
        </html>
      ''';

      final blob = html.Blob([htmlContent], 'text/html');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        return html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allow', 'autoplay; gamepad; fullscreen')
          ..src = blobUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.game.title),
        backgroundColor: const Color(0xFF141024),
      ),
      body: HtmlElementView(viewType: _viewId),
    );
  }
}