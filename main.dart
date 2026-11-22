import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game.dart';
import 'pixel.dart';
import 'progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await PlayerProgress.load();
  runApp(PixelOrbitApp(progress: progress));
}

class PixelOrbitApp extends StatelessWidget {
  final PlayerProgress progress;
  const PixelOrbitApp({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Orbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PO.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PO.accent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MainMenu(progress: progress),
    );
  }
}

// ───────────────────────── MENU ─────────────────────────

class MainMenu extends StatefulWidget {
  final PlayerProgress progress;
  const MainMenu({super.key, required this.progress});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      setState(() => _t = d.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  PlayerProgress get p => widget.progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // animated starfield
            CustomPaint(
              painter: _MenuBgPainter(_t),
              size: Size.infinite,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('PIXEL ORBIT', style: pixText(size: 28, color: PO.gold, weight: FontWeight.w800)),
                  Text('16-BIT EVOLUTION', style: pixText(size: 11, color: PO.muted)),
                  const SizedBox(height: 12),
                  // pilot showcase
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      painter: _ShipShowcasePainter(_t),
                      size: const Size(double.infinity, 120),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _chip('🪙 ${p.coins}'),
                      const SizedBox(width: 10),
                      _chip('💎 ${p.gems}'),
                      const SizedBox(width: 10),
                      _chip('★ ${p.highScore}'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _menuBtn('▶  ИГРАТЬ', PO.accent, () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GameScreen(progress: p),
                    )).then((_) => setState(() {}));
                  }),
                  const SizedBox(height: 10),
                  _menuBtn('🎖  СЕЗОННЫЙ ПРОПУСК', const Color(0xFF6A4AFF), () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SeasonScreen(progress: p),
                    )).then((_) => setState(() {}));
                  }),
                  const SizedBox(height: 10),
                  _menuBtn('ℹ  ОБ ИГРЕ', PO.border, () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: PO.panel,
                        title: Text('Pixel Orbit v1', style: pixText(size: 16, color: PO.gold)),
                        content: Text(
                          'Пиксельный космический шутер.\n'
                          'Волны врагов, боссы каждые 5 волн.\n'
                          'Очки → монеты и XP сезона.\n\n'
                          'Управление: води пальцем — корабль следует.\n'
                          'Стрельба автоматическая.',
                          style: pixText(size: 13, color: PO.text),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: pixText(color: PO.accent)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    'S${p.seasonLevel}  ·  XP ${p.xpIntoLevel}/${PlayerProgress.xpPerLevel}'
                    '${p.premium ? '  ·  PREMIUM' : ''}',
                    style: pixText(size: 11, color: PO.muted),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PO.panel,
          border: Border.all(color: PO.border, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t, style: pixText(size: 12, color: PO.text)),
      );

  Widget _menuBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: color.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color, width: 2),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: Center(child: Text(label, style: pixText(size: 16, color: PO.text))),
        ),
      ),
    );
  }
}

class _MenuBgPainter extends CustomPainter {
  final double t;
  _MenuBgPainter(this.t);

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = PO.bg);
    final p = Paint()..color = const Color(0xFF6A7A9A);
    for (var i = 0; i < 50; i++) {
      final x = (i * 67 + t * (8 + i % 5)) % (size.width + 10);
      final y = (i * 97 + t * (3 + i % 3)) % size.height;
      c.drawRect(Rect.fromLTWH(x, y, 2, 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBgPainter old) => true;
}

class _ShipShowcasePainter extends CustomPainter {
  final double t;
  _ShipShowcasePainter(this.t);

  @override
  void paint(Canvas c, Size size) {
    final cx = size.width / 2 + 12 * (t % 2 > 1 ? 2 - (t % 2) : t % 2).toDouble();
    // bob
    final cy = size.height / 2 + 6 * (0.5 - ((t * 1.5) % 1 - 0.5).abs() * 2);
    // glow
    c.drawCircle(Offset(cx, cy + 10), 28, Paint()..color = PO.accent.withOpacity(0.12));
    shipSprite.paint(c, Offset(cx, cy), 4.5);
    enemySprite.paint(c, Offset(cx - 90, cy - 10 + 4 * (t % 1)), 2.5);
    enemy2Sprite.paint(c, Offset(cx + 90, cy + 6), 2.5);
  }

  @override
  bool shouldRepaint(covariant _ShipShowcasePainter old) => true;
}

// ───────────────────────── GAME ─────────────────────────

class GameScreen extends StatefulWidget {
  final PlayerProgress progress;
  const GameScreen({super.key, required this.progress});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameWorld world;
  late Ticker ticker;
  Duration _last = Duration.zero;
  bool _saved = false;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    world = GameWorld(w: 360, h: 640);
    ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    world.update(dt);
    if (world.gameOver && !_saved) {
      _saved = true;
      widget.progress.addScore(world.score);
      widget.progress.save();
    }
    setState(() {});
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _pointer(Offset global) {
    final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final x = local.dx / box.size.width * world.w;
    world.targetX = x.clamp(20, world.w - 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          world.resize(constraints.maxHeight / (constraints.maxWidth / 360));
          return GestureDetector(
            onPanStart: (d) => _pointer(d.globalPosition),
            onPanUpdate: (d) => _pointer(d.globalPosition),
            onTapDown: (d) {
              if (world.gameOver) {
                Navigator.pop(context);
                return;
              }
              _pointer(d.globalPosition);
            },
            child: CustomPaint(
              key: _paintKey,
              painter: _GamePainter(world),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          );
        },
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final GameWorld world;
  _GamePainter(this.world);

  @override
  void paint(Canvas canvas, Size size) => world.paint(canvas, size);

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}

// ───────────────────────── SEASON PASS ─────────────────────────

class SeasonScreen extends StatefulWidget {
  final PlayerProgress progress;
  const SeasonScreen({super.key, required this.progress});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  PlayerProgress get p => widget.progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('СЕЗОННЫЙ ПРОПУСК', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PO.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: PO.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Уровень ${p.seasonLevel} / 20',
                  style: pixText(size: 18, color: PO.text),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.levelProgress,
                    minHeight: 10,
                    backgroundColor: PO.border,
                    color: PO.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'XP ${p.xpIntoLevel} / ${PlayerProgress.xpPerLevel}',
                  style: pixText(size: 12, color: PO.muted),
                ),
                const SizedBox(height: 10),
                if (!p.premium)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PO.gold,
                        side: const BorderSide(color: PO.gold, width: 2),
                      ),
                      onPressed: () async {
                        final ok = p.buyPremium();
                        if (ok) {
                          await p.save();
                          setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Premium открыт!', style: pixText()),
                                backgroundColor: PO.panel,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Нужно 600 💎 или 600 🪙 (сейчас ${p.gems}💎 / ${p.coins}🪙)',
                                  style: pixText(size: 12),
                                ),
                                backgroundColor: PO.panel,
                              ),
                            );
                          }
                        }
                      },
                      child: Text('Открыть PREMIUM — 600 💎/🪙', style: pixText(size: 13, color: PO.gold)),
                    ),
                  )
                else
                  Text('★ PREMIUM АКТИВЕН', style: pixText(size: 14, color: PO.gold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: seasonRewards.length,
              itemBuilder: (ctx, i) {
                final r = seasonRewards[i];
                final unlocked = r.level <= p.seasonLevel;
                final freeTaken = p.claimedFree.contains(r.level);
                final premTaken = p.claimedPremium.contains(r.level);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PO.panel,
                    border: Border.all(
                      color: unlocked ? PO.accent : PO.border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${r.level}',
                          style: pixText(
                            size: 16,
                            color: unlocked ? PO.gold : PO.muted,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FREE: ${r.freeName}', style: pixText(size: 12, color: PO.text)),
                            Text(
                              'PREM: ${r.premiumName}',
                              style: pixText(
                                size: 12,
                                color: p.premium ? PO.gold : PO.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _claimBtn(
                            freeTaken ? '✓' : 'FREE',
                            unlocked && !freeTaken,
                            () async {
                              if (p.claimFree(r.level)) {
                                await p.save();
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 4),
                          _claimBtn(
                            premTaken ? '✓' : 'PREM',
                            p.premium && unlocked && !premTaken,
                            () async {
                              if (p.claimPremium(r.level)) {
                                await p.save();
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimBtn(String label, bool enabled, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      width: 64,
      child: Material(
        color: enabled ? PO.accent.withOpacity(0.3) : PO.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              label,
              style: pixText(
                size: 11,
                color: enabled ? PO.text : PO.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
