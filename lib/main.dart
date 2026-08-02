import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

/// Backend API Endpoint
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

/// Game Model
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
State createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
List _allGames = [];
List _filteredGames = [];
String _selectedSystem = 'ALL';
String _searchQuery = '';
bool _isLoading = true;
String _statusMessage = 'Conectando ao servidor Cloud R2...';

@override
void initState() {
super.initState();
_fetchGamesCatalog();
}

Future _fetchGamesCatalog({int retries = 3}) async {
setState(() {
_isLoading = true;
_statusMessage = 'Carregando acervo do servidor...';
});

for (int attempt = 1; attempt <= retries; attempt++) {
  try {
    final response = await http
        .get(Uri.parse('$kApiBaseUrl/games'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List catalogRaw = data['catalog'] ?? [];
      final parsedList = catalogRaw.map((e) => GameModel.fromJson(e)).toList();

      if (parsedList.isNotEmpty && mounted) {
        setState(() {
          _allGames = parsedList;
          _applyFilters();
          _isLoading = false;
        });
        return;
      }
    }
  } catch (e) {
    debugPrint('[RETROPLAY API FETCH ATTEMPT $attempt ERROR]: $e');
    if (attempt < retries && mounted) {
      setState(() {
        _statusMessage = 'Acordando servidor... (Tentativa $attempt/$retries)';
      });
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}

// Fallback Catalog
if (mounted) {
  setState(() {
    _allGames = const [
      GameModel(
        id: 'nes-mario-25th',
        title: '25th Anniversary Super Mario Bros.',
        fullTitle: '25th Anniversary Super Mario Bros. (Europe)',
        system: 'NES',
        ejsCore: 'nes',
        demoRomUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/NES/ROMS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe).nes',
        coverUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/NES/CAPAS/25th%20Anniversary%20Super%20Mario%20Bros.%20(Europe).png',
      ),
      GameModel(
        id: 'snes-mario-world',
        title: 'Super Mario World',
        fullTitle: 'Super Mario World (USA)',
        system: 'SNES',
        ejsCore: 'snes',
        demoRomUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/SNES/ROMS/Super%20Mario%20World.sfc',
        coverUrl: '',
      ),
      GameModel(
        id: 'md-aladdin',
        title: 'Disney\'s Aladdin',
        fullTitle: 'Aladdin (USA)',
        system: 'MEGADRIVE',
        ejsCore: 'segaMD',
        demoRomUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/ROMS/Aladdin%20(USA).md',
        coverUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/MEGA/CAPA/Aladdin.png',
      ),
      GameModel(
        id: 'ps2-black',
        title: 'Black',
        fullTitle: 'Black (USA)',
        system: 'PS2',
        ejsCore: 'play',
        demoRomUrl:
            'https://pub-9cc5ba1ca4464cfea78f3f53ccebd465.r2.dev/PS2/ROMS/Black%20(USA).chd',
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
final matchesSystem =
_selectedSystem == 'ALL' || game.system == _selectedSystem;
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
const Text('RETROPLAY CLOUD R2',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
],
),
backgroundColor: const Color(0xFF141024),
actions: [
IconButton(
icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00F0FF)),
tooltip: 'Recarregar Catálogo',
onPressed: _fetchGamesCatalog,
),
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
Text('${_filteredGames.length} Jogos',
style: const TextStyle(
color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
? Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const CircularProgressIndicator(color: Color(0xFF00F0FF)),
const SizedBox(height: 16),
Text(_statusMessage,
style: const TextStyle(color: Colors.white70, fontSize: 13)),
],
),
)
: _filteredGames.isEmpty
? const Center(
child: Text('Nenhum jogo encontrado.',
style: TextStyle(color: Colors.white54)))
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
final bool isSelected = selectedSystem == systemCode;
return ChoiceChip(
showCheckmark: false,
avatar: Icon(icon,
size: 16, color: isSelected ? Colors.black : const Color(0xFF00F0FF)),
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
onSelected: () => _filterSystem(systemCode),
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
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackCardHeader(game),
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
                  border: Border.all(
                      color: const Color(0xFF00F0FF).withOpacity(0.6)),
                ),
                child: Text(
                  game.system,
                  style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: game.system == 'PS2'
                      ? const Color(0xFFFF007F)
                      : const Color(0xFF00F0FF),
                  foregroundColor: game.system == 'PS2'
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                    game.system == 'PS2'
                        ? Icons.download_for_offline_rounded
                        : Icons.play_arrow_rounded,
                    size: 18),
                label: Text(
                    game.system == 'PS2' ? 'JOGAR PS2' : 'JOGAR',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  if (game.system == 'PS2') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PS2GameLauncherScreen(game: game),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmulatorScreen(game: game),
                      ),
                    );
                  }
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
Icon(
game.system == 'PS2'
? Icons.videogame_asset_rounded
: Icons.sports_esports_rounded,
color: game.system == 'PS2'
? const Color(0xFFFF007F)
: const Color(0xFF00F0FF),
size: 38,
),
const SizedBox(height: 6),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 8.0),
child: Text(
game.system,
style: const TextStyle(
color: Colors.white54,
fontSize: 11,
fontWeight: FontWeight.bold),
),
),
],
),
),
);
}
}

/// Cross-Platform Emulator Screen (Web & Android WebView Execution)
class EmulatorScreen extends StatefulWidget {
final GameModel game;

const EmulatorScreen({super.key, required this.game});

@override
State createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State {
WebViewController? _webViewController;
bool _isLoadingGame = true;

@override
void initState() {
super.initState();
_initWebViewEngine();
}

void _initWebViewEngine() {
final String proxiedRomUrl =
'$kApiBaseUrl/proxy-rom/game.rom?url=${Uri.encodeComponent(widget.game.demoRomUrl)}';

final String htmlContent = '''


_webViewController = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0xFF000000))
  ..setNavigationDelegate(
    NavigationDelegate(
      onPageFinished: (String url) {
        if (mounted) {
          setState(() => _isLoadingGame = false);
        }
      },
    ),
  )
  ..loadHtmlString(htmlContent, baseUrl: 'https://cdn.emulatorjs.org/');


}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,
body: SafeArea(
child: Stack(
children: [
if (_webViewController != null)
WebViewWidget(controller: _webViewController!),
if (_isLoadingGame)
Container(
color: const Color(0xFF0F0C1B),
child: Center(
child: Column(
mainAxisAlignment: ContainerAlignmentCenter(),
),
),
),
Positioned(
top: 10,
right: 10,
child: CircleAvatar(
backgroundColor: Colors.black87,
child: IconButton(
icon: const Icon(Icons.close_rounded, color: Colors.white),
onPressed: () => Navigator.pop(context),
),
),
),
],
),
),
);
}
}

class ContainerAlignmentCenter extends StatelessWidget {
const ContainerAlignmentCenter({super.key});

@override
Widget build(BuildContext context) {
return Column(
mainAxisAlignment: MainAxisAlignment.center,
children: const [
CircularProgressIndicator(color: Color(0xFF00F0FF)),
SizedBox(height: 16),
Text(
'Carregando jogo...',
style: TextStyle(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.bold),
),
SizedBox(height: 6),
Text(
'Conectando ao Servidor Cloud R2',
style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
),
],
);
}
}

/// PS2 Launcher Screen - Native Intent Support (Android) & Download Center (Web)
class PS2GameLauncherScreen extends StatefulWidget {
final GameModel game;

const PS2GameLauncherScreen({super.key, required this.game});

@override
State createState() => _PS2GameLauncherScreenState();
}

class _PS2GameLauncherScreenState extends State {
bool _isDownloading = false;
bool _isDownloaded = false;
double _downloadProgress = 0.0;
String _statusText = 'Pronto para baixar a ROM para o dispositivo.';
String? _localFilePath;

@override
void initState() {
super.initState();
_checkLocalFileExists();
}

Future _checkLocalFileExists() async {
if (kIsWeb) return;
try {
final dir = await getApplicationDocumentsDirectory();
final fileName = widget.game.demoRomUrl.split('/').last.split('?').first;
final file = File('${dir.path}/$fileName');

  if (await file.exists()) {
    final sizeMb = (await file.length()) / (1024 * 1024);
    setState(() {
      _isDownloaded = true;
      _localFilePath = file.path;
      _statusText =
          'ROM já disponível no dispositivo (${sizeMb.toStringAsFixed(1)} MB)';
    });
  }
} catch (e) {
  debugPrint('[PS2 CHECK FILE ERROR]: $e');
}


}

Future _downloadRomToDevice() async {
if (kIsWeb) {
final url = Uri.parse(widget.game.demoRomUrl);
if (await canLaunchUrl(url)) {
await launchUrl(url, mode: LaunchMode.externalApplication);
}
return;
}

setState(() {
  _isDownloading = true;
  _downloadProgress = 0.0;
  _statusText = 'Conectando ao Cloudflare R2...';
});

try {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = widget.game.demoRomUrl.split('/').last.split('?').first;
  final savePath = '${dir.path}/$fileName';
  final file = File(savePath);

  final proxiedUrl =
      '$kApiBaseUrl/proxy-rom/game.rom?url=${Uri.encodeComponent(widget.game.demoRomUrl)}';
  final request = http.Request('GET', Uri.parse(proxiedUrl));
  final response = await http.Client().send(request);

  final totalBytes = response.contentLength ?? 0;
  int receivedBytes = 0;

  final sink = file.openWrite();

  await response.stream.forEach((chunk) {
    sink.add(chunk);
    receivedBytes += chunk.length;
    if (mounted && totalBytes > 0) {
      setState(() {
        _downloadProgress = receivedBytes / totalBytes;
        final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
        final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
        _statusText = 'Baixando: $recMb MB / $totMb MB';
      });
    }
  });

  await sink.close();

  if (mounted) {
    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
      _localFilePath = savePath;
      _statusText = 'ROM salva no armazenamento com sucesso!';
    });
  }
} catch (e) {
  if (mounted) {
    setState(() {
      _isDownloading = false;
      _statusText = 'Erro no download: $e';
    });
  }
}


}

Future _launchNativePS2Emulator() async {
if (_localFilePath == null) return;

if (defaultTargetPlatform == TargetPlatform.android) {
  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: Uri.file(_localFilePath!).toString(),
      type: 'application/octet-stream',
    );
    await intent.launch();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Abra o NetherSX2/AetherSX2 e selecione a ROM em: $_localFilePath'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}


}

Future _openNetherSX2Download() async {
final url = Uri.parse(
'https://github.com/Trixarian/NetherSX2-builder/releases');
if (await canLaunchUrl(url)) {
await launchUrl(url, mode: LaunchMode.externalApplication);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF0F0C1B),
appBar: AppBar(
backgroundColor: const Color(0xFF141024),
title: Text(widget.game.title,
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
leading: IconButton(
icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
onPressed: () => Navigator.pop(context),
),
),
body: Center(
child: Container(
constraints: const BoxConstraints(maxWidth: 520),
margin: const EdgeInsets.all(20),
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: const Color(0xFF141024),
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: const Color(0xFFFF007F).withOpacity(0.6), width: 1.5),
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
child: const Icon(Icons.videogame_asset_rounded,
color: Color(0xFFFF007F), size: 44),
),
const SizedBox(height: 16),
Text(
widget.game.title,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
),
const SizedBox(height: 6),
Container(
padding:
const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
decoration: BoxDecoration(
color: const Color(0xFF00F0FF).withOpacity(0.15),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFF00F0FF).withOpacity(0.4)),
),
child: Text(
kIsWeb
? 'PLAYSTATION 2 • DOWNLOAD DA ROM'
: 'PLAYSTATION 2 • EXECUÇÃO NATIVA ANDROID',
style: const TextStyle(
color: Color(0xFF00F0FF),
fontSize: 11,
fontWeight: FontWeight.bold),
),
),
const SizedBox(height: 16),
Text(
_statusText,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white70, fontSize: 13, height: 1.4),
),
const SizedBox(height: 16),
if (_isDownloading) ...[
LinearProgressIndicator(
value: _downloadProgress > 0 ? _downloadProgress : null,
backgroundColor: const Color(0xFF0F0C1B),
color: const Color(0xFF00F0FF),
),
const SizedBox(height: 8),
Text(
'${(_downloadProgress * 100).toStringAsFixed(0)}%',
style: const TextStyle(
color: Color(0xFF00F0FF),
fontWeight: FontWeight.bold,
fontSize: 14),
),
const SizedBox(height: 16),
],
if (!_isDownloaded && !_isDownloading)
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF00F0FF),
foregroundColor: Colors.black,
padding: const EdgeInsets.symmetric(vertical: 14),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14)),
),
icon: const Icon(Icons.cloud_download_rounded, size: 20),
label: Text(
kIsWeb
? 'BAIXAR ROM DIRETO (NAVEGADOR)'
: 'BAIXAR ROM DO CLOUDFLARE R2',
style: const TextStyle(
fontWeight: FontWeight.bold, fontSize: 13)),
onPressed: _downloadRomToDevice,
),
),
if (_isDownloaded && !_isDownloading) ...[
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFFF007F),
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 14),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14)),
),
icon: const Icon(Icons.play_arrow_rounded, size: 22),
label: const Text('EXECUTAR NO NETHERSX2 / AETHERSX2',
style: TextStyle(
fontWeight: FontWeight.bold, fontSize: 13)),
onPressed: _launchNativePS2Emulator,
),
),
const SizedBox(height: 10),
SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
style: OutlinedButton.styleFrom(
side: BorderSide(
color: const Color(0xFF00F0FF).withOpacity(0.6)),
padding: const EdgeInsets.symmetric(vertical: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14)),
),
icon: const Icon(Icons.get_app_rounded,
color: Color(0xFF00F0FF), size: 18),
label: const Text('BAIXAR EMULADOR NETHERSX2 (APK)',
style: TextStyle(
color: Color(0xFF00F0FF),
fontWeight: FontWeight.bold,
fontSize: 12)),
onPressed: _openNetherSX2Download,
),
),
],
],
),
),
),
);
}
}