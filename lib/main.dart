// Metro Widget IDF - écran "afficheur RATP" : 2 prochains passages autour de ma position
// Créé par : Omar Pérez - 2026-11-09 08:10
// Lancement : flutter run --dart-define=PRIM_API_KEY=xxxx  (ou saisir la clé dans l'appli)
import 'dart:async';

import 'package:flutter/material.dart';

import 'background.dart';
import 'board_service.dart';
import 'config.dart';
import 'models.dart';

const kNavy = Color(0xFF0B1442);
const kNavyRow = Color(0xFF16205A);
const kAmber = Color(0xFFFFC72C);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackground();
  runApp(const MetroApp());
}

class MetroApp extends StatelessWidget {
  const MetroApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Prochains passages',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kNavy,
      colorScheme: const ColorScheme.dark(primary: kAmber, surface: kNavy),
    ),
    home: const BoardPage(),
  );
}

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> with WidgetsBindingObserver {
  Board? _board;
  bool _loading = false;
  bool _askedKey = false;
  Timer? _refresh;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refresh = Timer.periodic(AppConfig.autoRefresh, (_) => _load());
    _tick = Timer.periodic(
      const Duration(seconds: 10),
      (_) => setState(() {}),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    final b = await BoardService.refreshAndPush();
    if (!mounted) return;
    setState(() {
      _board = b;
      _loading = false;
    });
    if (b.error == 'Clé API PRIM manquante' && !_askedKey) {
      _askedKey = true;
      _askKey();
    }
  }

  Future<void> _askKey() async {
    final ctl = TextEditingController(text: await BoardService.apiKey());
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: kNavyRow,
        title: const Text('Clé API PRIM'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(
            hintText: 'prim.iledefrance-mobilites.fr > Mon jeton',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await BoardService.setApiKey(ctl.text);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _board;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: kAmber,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              _Header(board: b, loading: _loading, onSettings: _askKey),
              const SizedBox(height: 10),
              if (b == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (b.rows.isEmpty)
                _Message(b.error ?? 'Aucun passage')
              else
                ...b.rows.map((r) => _Row(row: r)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Board? board;
  final bool loading;
  final VoidCallback onSettings;

  const _Header({
    required this.board,
    required this.loading,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now().format(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  board?.station ?? 'Recherche…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (board != null && board!.error == null)
                  Text(
                    'à ${board!.distance} m',
                    style: const TextStyle(color: kNavy, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: kNavy),
            ),
          const SizedBox(width: 10),
          Text(
            now,
            style: const TextStyle(
              color: kNavy,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.key, color: kNavy),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final BoardRow row;
  const _Row({required this.row});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: kNavyRow,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        LineBadge(row: row),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                row.stop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
        for (var i = 0; i < AppConfig.timesPerRow; i++)
          _TimeCell(i < row.times.length ? row.times[i] : null),
      ],
    ),
  );
}

class _TimeCell extends StatelessWidget {
  final DateTime? t;
  const _TimeCell(this.t);

  @override
  Widget build(BuildContext context) {
    final m = t == null ? null : t!.difference(DateTime.now()).inMinutes;
    return Container(
      width: 58,
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            m == null ? '--' : (m <= 0 ? '0' : '$m'),
            style: const TextStyle(
              color: kAmber,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            m == null ? '' : (m <= 0 ? 'à quai' : 'min'),
            style: const TextStyle(color: kAmber, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class LineBadge extends StatelessWidget {
  final BoardRow row;
  const LineBadge({super.key, required this.row});

  static Color hex(String h) =>
      Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final bg = hex(row.bg);
    final fg = hex(row.fg);
    final mode = row.mode.toLowerCase();
    final circle = mode.contains('metro');
    final tram = mode.contains('tram');
    final rail = mode.contains('rail');
    final label = Text(
      row.line,
      maxLines: 1,
      style: TextStyle(
        color: circle || rail ? fg : (tram ? Colors.black : fg),
        fontWeight: FontWeight.w900,
        fontSize: row.line.length > 3 ? 12 : 17,
      ),
    );
    final prefix = circle
        ? 'M'
        : rail
        ? (RegExp(r'^[A-E]$').hasMatch(row.line) ? 'RER' : 'TRAIN')
        : tram
        ? 'TRAM'
        : 'BUS';
    return SizedBox(
      width: 54,
      child: Column(
        children: [
          Text(
            prefix,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: circle ? 36 : 50,
            height: 36,
            alignment: Alignment.center,
            decoration: tram
                ? BoxDecoration(
                    color: Colors.white,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: bg, width: 4),
                    ),
                  )
                : BoxDecoration(
                    color: bg,
                    shape: circle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: circle
                        ? null
                        : BorderRadius.circular(rail ? 8 : 3),
                  ),
            child: label,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: kAmber, fontSize: 18),
    ),
  );
}
