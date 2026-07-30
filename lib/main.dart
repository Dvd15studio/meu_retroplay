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
      title: 'RetroPlay Teste R2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        primaryColor: const Color(0xFF00F0FF),
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
      id: json['id'] ?? 'snes-mario-world',
      title: json['title'] ?? 'Super Mario World',
      system: json['system'] ?? 'SNES',
      ejsCore: json['ejsCore'] ?? 'snes',
      demoRomUrl: json['demoRomUrl'] ?? 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/Super%20Mario%20World%20(U)%20%5B!%5D.smc',
      coverUrl: json['coverUrl'] ?? 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/super-mario-world.jpg',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameModel? _testGame;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    try {
      final response = await http.get(Uri.parse('$kApiBaseUrl/games'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catalog = data['catalog'] ?? [];
        if (catalog.isNotEmpty) {
          setState(() {
            _testGame = GameModel.fromJson(catalog.first);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[FETCH GAME ERROR]: $e');
    }
    
    // Fallback local se o backend demorar para dar wake-up no Render
    setState(() {
      _testGame = const GameModel(
        id: 'snes-mario-world',
        title: 'Super Mario World',
        system: 'SNES',
        ejsCore: 'snes',
        demoRomUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/Super%20Mario%20World%20(U)%20%5B!%5D.smc',
        coverUrl: 'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/super-mario-world.jpg',
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RetroPlay - Teste Cloudflare R2 Próprio'),
        backgroundColor: const Color(0xFF141024),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF00F0FF))
            : _testGame == null
                ? const Text('Erro ao carregar jogo.')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _testGame!.coverUrl,
                          width: 220,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220,
                            height: 150,
                            color: const Color(0xFF141024),
                            child: const Icon(Icons.gamepad, size: 64, color: Color(0xFF00F0FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _testGame!.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '☁️ Servidor R2 Próprio Activo (.smc + JPG)',
                        style: TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F0FF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                        label: const Text(
                          'JOGAR AGORA (R2)',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SingleEmulatorView(game: _testGame!),
                            ),
                          );
                        },
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