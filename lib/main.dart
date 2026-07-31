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
          demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/ROMS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe)%20(Promo%2C%20Virtual%20Console).nes',
          coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/CAPAS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe)%20(Promo%2C%20Virtual%20Console).png',
        ),
        GameModel(
          id: 'md-aladdin',
          title: 'Disney\'s Aladdin (Mega Drive)',
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
                Text('${_allGames.length} Jogos', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    hintText: 'Buscar jogo por nome (ex: Mario, Sonic, Aladdin)...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00F0FF)),
                    filled: true,
                    fillColor: const Color(0xFF0F0F1B),
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
                      _buildFilterChip('MEGADRIVE', 'Mega Drive', Icons.disc_full_rounded),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videogame_asset_rounded, size: 44, color: Color(0xFF00F0FF)),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              game.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
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
                      color: Colors.black.withOpacity(0.85),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
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

    final String rawUrl = widget.game.demoRomUrl;
    String extension = widget.game.system == 'MEGADRIVE' ? 'md' : 'nes';
    if (rawUrl.contains('.')) {
      final String possibleExt = rawUrl.split('.').last.toLowerCase();
      if (possibleExt.contains('?')) {
        extension = possibleExt.split('?').first;
      } else {
        extension = possibleExt;
      }
    }

    final String encodedRomUrl = Uri.encodeComponent(rawUrl);
    final String proxyUrl = '$kApiBaseUrl/proxy-rom/game.$extension?url=$encodedRomUrl';

    if (kIsWeb) {
      final String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>body, html { margin:0; padding:0; width:100%; height:100%; background:#000; overflow:hidden; }</style>
        </head>
        <body>
          <div id="emulator" style="width:100%;height:100%;"></div>
          <script type="text/javascript">
            EJS_player = '#emulator';
            EJS_core = ${jsonEncode(widget.game.ejsCore)};
            EJS_gameName = ${jsonEncode(widget.game.title)};
            EJS_color = '#00F0FF';
            EJS_startOnLoaded = true;
            EJS_pathtodata = 'https://cdn.emulatorjs.org/stable/data/';
            EJS_gameUrl = ${jsonEncode(proxyUrl)};
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