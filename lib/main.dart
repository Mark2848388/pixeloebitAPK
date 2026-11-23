import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'content.dart';
import 'game.dart';
import 'online.dart';
import 'pixel.dart';
import 'progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await OnlineService.init();
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
        colorScheme: ColorScheme.fromSeed(seedColor: PO.accent, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: MainMenu(progress: progress),
    );
  }
}

// ════════════════ PIXEL MAIN MENU ════════════════

class MainMenu extends StatefulWidget {
  final PlayerProgress progress;
  const MainMenu({super.key, required this.progress});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  int _sel = 0;
  PlayerProgress get p => widget.progress;

  static const _items = [
    ('КАМПАНИЯ', '10 миров', 0xFF5B8CFF),
    ('КЛАССИКА', 'волны', 0xFF4A7AFF),
    ('ENDLESS', 'без конца', 0xFFFF6A4A),
    ('АРЕНА', 'дуэль', 0xFFFFB040),
    ('ГЕРОИ', 'навыки', 0xFF40C070),
    ('АНГАР', 'прокачка', 0xFF9B4DFF),
    ('БАЗА', 'стройка', 0xFF40C0A0),
    ('СУНДУКИ', 'лут', 0xFFFFD34A),
    ('ИВЕНТЫ', 'награды', 0xFFFF80D0),
    ('ДРУЗЬЯ', 'локально', 0xFF8A96B0),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _t = d.inMilliseconds / 1000.0))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _open(int i) {
    HapticFeedback.selectionClick();
    switch (i) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignScreen(progress: p))).then((_) => setState(() {}));
      case 1:
        _play('classic');
      case 2:
        _play('endless');
      case 3:
        _play('arena');
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HeroesScreen(progress: p))).then((_) => setState(() {}));
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HangarScreen(progress: p))).then((_) => setState(() {}));
      case 6:
        Navigator.push(context, MaterialPageRoute(builder: (_) => BaseScreen(progress: p))).then((_) => setState(() {}));
      case 7:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChestScreen(progress: p))).then((_) => setState(() {}));
      case 8:
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen(progress: p))).then((_) => setState(() {}));
      case 9:
        Navigator.push(context, MaterialPageRoute(builder: (_) => FriendsScreen(progress: p))).then((_) => setState(() {}));
    }
  }

  void _play(String mode, {int worldId = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: mode, worldId: worldId)),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, box) {
          return GestureDetector(
            onTapUp: (d) {
              // hit test menu cells roughly
            },
            child: CustomPaint(
              painter: _MenuPainter(
                t: _t,
                sel: _sel,
                items: _items,
                coins: p.coins,
                gems: p.gems,
                scrap: p.scrap,
                heroId: p.activeHero,
                world: p.campaignWorld,
                name: p.playerName,
              ),
              child: Stack(children: [
                // invisible grid for taps
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 160, 16, 24),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() => _sel = i);
                              _open(i);
                            },
                            onHighlightChanged: (h) {
                              if (h) setState(() => _sel = i);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  final double t;
  final int sel;
  final List<(String, String, int)> items;
  final int coins, gems, scrap, world;
  final String heroId, name;
  _MenuPainter({
    required this.t,
    required this.sel,
    required this.items,
    required this.coins,
    required this.gems,
    required this.scrap,
    required this.heroId,
    required this.world,
    required this.name,
  });

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = PO.bg);
    // stars
    final sp = Paint()..color = const Color(0xFF6A7A9A);
    for (var i = 0; i < 60; i++) {
      final x = (i * 73 + t * (6 + i % 4)) % (size.width + 8);
      final y = (i * 91 + t * (2 + i % 3)) % size.height;
      c.drawRect(Rect.fromLTWH(x, y, 2, 2), sp);
    }
    // title panel
    final titleR = Rect.fromLTWH(16, 12, size.width - 32, 52);
    drawPanel(c, titleR, border: PO.gold);
    _t(c, 'PIXEL ORBIT', size.width / 2 - 54, 22, size: 18, color: PO.gold);
    _t(c, '16-BIT  ·  $name  ·  W$world', size.width / 2 - 70, 44, size: 10, color: PO.muted);

    // hero showcase
    final hx = size.width / 2;
    final hy = 110.0 + 4 * ((t * 1.3) % 1 - 0.5).abs();
    c.drawCircle(Offset(hx, hy + 6), 28, Paint()..color = PO.accent.withOpacity(0.12));
    heroSprite(heroId).paint(c, Offset(hx, hy), 3.4);
    enemySprite.paint(c, Offset(hx - 70, hy + 4), 1.6);
    bossPhase1.paint(c, Offset(hx + 72, hy), 1.3);

    // resources
    final resY = 148.0;
    drawPanel(c, Rect.fromLTWH(16, resY, size.width - 32, 28), fill: PO.panel2);
    _t(c, 'C $coins   G $gems   S $scrap', 28, resY + 7, size: 12, color: PO.text);

    // draw pixel tiles (visual only — taps via grid)
    const top = 168.0;
    final tileW = (size.width - 16 * 2 - 10) / 2;
    const tileH = 52.0;
    for (var i = 0; i < items.length; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      final r = Rect.fromLTWH(16 + col * (tileW + 10), top + row * (tileH + 10), tileW, tileH);
      final hot = i == sel;
      final colr = Color(items[i].$3);
      drawPanel(c, r, fill: hot ? colr.withOpacity(0.28) : PO.panel, border: hot ? colr : PO.border, thick: hot ? 2.5 : 2);
      // left pixel accent bar
      c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 6, 4, r.height - 12), Paint()..color = colr);
      _t(c, items[i].$1, r.left + 14, r.top + 12, size: 13, color: hot ? PO.gold : PO.text);
      _t(c, items[i].$2, r.left + 14, r.top + 30, size: 10, color: PO.muted);
    }
  }

  void _t(Canvas c, String s, double x, double y, {double size = 12, Color color = PO.text}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: pixText(size: size, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _MenuPainter old) => true;
}

// ════════════════ GAME SCREEN ════════════════

class GameScreen extends StatefulWidget {
  final PlayerProgress progress;
  final String mode;
  final int worldId;
  const GameScreen({super.key, required this.progress, this.mode = 'classic', this.worldId = 0});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameWorld world;
  late final Ticker ticker;
  Duration _last = Duration.zero;
  bool _saved = false;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    final h = widget.progress.hero;
    WorldInfo? winfo;
    if (widget.mode == 'campaign' && widget.worldId > 0) {
      winfo = worlds.firstWhere((w) => w.id == widget.worldId);
    }
    world = GameWorld(
      w: 360,
      h: 640,
      mode: widget.mode,
      worldId: widget.worldId,
      wavesGoal: winfo?.wavesToClear ?? 0,
      bossHpBonus: (winfo?.bossHp ?? 0).toDouble(),
      fireRateMul: h.fireRateMul,
      damageMul: h.damageMul * widget.progress.dmgMul,
      speedMul: h.speedMul,
      bonusLives: h.bonusLives + widget.progress.extraHull,
      heroId: h.id,
      weapon: h.weapon,
      dmgUpgrade: widget.progress.dmgMul,
      rateUpgrade: widget.progress.rateMul,
      dashCdMul: widget.progress.dashCdMul,
      ultCdMul: widget.progress.ultCdMul,
    );
    ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ticker.start();
    });
  }

  void _onTick(Duration elapsed) {
    try {
      var dt = _last == Duration.zero ? 1 / 60 : (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (dt <= 0 || dt > 1) dt = 1 / 60;
      world.update(dt);
      if (world.gameOver && !_saved) {
        _saved = true;
        final mul = 1.0;
        widget.progress.addScore(world.score, mode: widget.mode, rewardMul: mul);
        if (world.victory && widget.mode == 'campaign') {
          widget.progress.clearWorld(widget.worldId);
        }
        if (world.victory && widget.mode == 'arena') {
          widget.progress.arenaWins++;
        }
        // convert some score to scrap already in addScore
        widget.progress.save();
      }
    } catch (e, st) {
      debugPrint('$e\n$st');
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    world.dispose();
    super.dispose();
  }

  void _ptr(Offset g) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final l = box.globalToLocal(g);
    world.targetX = (l.dx / box.size.width * world.w).clamp(20.0, world.w - 20.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PO.bg,
      body: LayoutBuilder(builder: (_, cons) {
        world.resize(cons.maxHeight / (cons.maxWidth / 360.0));
        return Stack(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _ptr(d.globalPosition),
            onPanUpdate: (d) => _ptr(d.globalPosition),
            onTapDown: (d) {
              if (world.gameOver) {
                Navigator.pop(context);
                return;
              }
              _ptr(d.globalPosition);
            },
            onDoubleTap: () => world.tryDash(),
            child: AnimatedBuilder(
              animation: world,
              builder: (_, __) => CustomPaint(
                key: _key,
                painter: _GP(world),
                size: Size(cons.maxWidth, cons.maxHeight),
              ),
            ),
          ),
          // ability buttons
          Positioned(
            right: 12,
            bottom: 48,
            child: Column(children: [
              _abilBtn('УЛЬТА', () => world.tryUlt()),
              const SizedBox(height: 10),
              _abilBtn('РЫВОК', () => world.tryDash()),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _abilBtn(String t, VoidCallback fn) {
    return Material(
      color: PO.panel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: PO.accent, width: 2)),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          fn();
        },
        child: SizedBox(
          width: 72,
          height: 40,
          child: Center(child: Text(t, style: pixText(size: 11, color: PO.gold))),
        ),
      ),
    );
  }
}

class _GP extends CustomPainter {
  final GameWorld world;
  _GP(this.world) : super(repaint: world);
  @override
  void paint(Canvas canvas, Size size) {
    try {
      world.paint(canvas, size);
    } catch (e, st) {
      debugPrint('paint $e\n$st');
    }
  }
  @override
  bool shouldRepaint(covariant _GP old) => true;
}

// ════════════════ CAMPAIGN ════════════════

class CampaignScreen extends StatelessWidget {
  final PlayerProgress progress;
  const CampaignScreen({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'КАМПАНИЯ'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: worlds.length,
        itemBuilder: (_, i) {
          final w = worlds[i];
          final unlocked = progress.worldUnlocked(w.id);
          final cleared = progress.worldCleared(w.id);
          return _card(
            color: Color(w.color),
            active: unlocked,
            child: ListTile(
              enabled: unlocked,
              leading: _pixBadge('${w.id}', Color(w.color)),
              title: Text(w.name, style: pixText(size: 14, color: unlocked ? PO.text : PO.muted, weight: FontWeight.w700)),
              subtitle: Text(unlocked ? '${w.blurb} · ${w.wavesToClear} волн · босс 3 фазы' : 'Закрыто', style: pixText(size: 11, color: PO.muted)),
              trailing: Text(cleared ? 'CLEAR' : unlocked ? 'PLAY' : 'LOCK', style: pixText(size: 11, color: PO.gold)),
              onTap: !unlocked
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GameScreen(progress: progress, mode: 'campaign', worldId: w.id)),
                      ),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════ HEROES ════════════════

class HeroesScreen extends StatefulWidget {
  final PlayerProgress progress;
  const HeroesScreen({super.key, required this.progress});
  @override
  State<HeroesScreen> createState() => _HeroesScreenState();
}

class _HeroesScreenState extends State<HeroesScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ГЕРОИ'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: heroes.length,
        itemBuilder: (_, i) {
          final h = heroes[i];
          final owned = p.ownedHeroes.contains(h.id);
          final active = p.activeHero == h.id;
          return _card(
            color: Color(h.color),
            active: owned,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(painter: _HeroIconPainter(h.id)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${h.name} · ${h.role}', style: pixText(size: 14, weight: FontWeight.w700, color: owned ? PO.text : PO.muted)),
                    Text(h.desc, style: pixText(size: 11, color: PO.muted)),
                    Text('Ульта: ${h.ultName}  ·  Рывок: ${h.dashName}  ·  ${h.weapon}', style: pixText(size: 10, color: Color(h.color))),
                  ]),
                ),
                if (owned)
                  TextButton(
                    onPressed: () async {
                      p.selectHero(h.id);
                      await p.save();
                      setState(() {});
                    },
                    child: Text(active ? 'ACTIVE' : 'SELECT', style: pixText(size: 11, color: PO.gold)),
                  )
                else
                  Text('W${h.unlockWorld}+', style: pixText(size: 11, color: PO.muted)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _HeroIconPainter extends CustomPainter {
  final String id;
  _HeroIconPainter(this.id);
  @override
  void paint(Canvas c, Size s) {
    drawPanel(c, Offset.zero & s, fill: PO.panel2);
    heroSprite(id).paint(c, Offset(s.width / 2, s.height / 2), 2.2);
  }
  @override
  bool shouldRepaint(covariant _HeroIconPainter old) => old.id != id;
}

// ════════════════ HANGAR UPGRADES ════════════════

class HangarScreen extends StatefulWidget {
  final PlayerProgress progress;
  const HangarScreen({super.key, required this.progress});
  @override
  State<HangarScreen> createState() => _HangarScreenState();
}

class _HangarScreenState extends State<HangarScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'АНГАР · S ${p.scrap}'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: upgrades.map((u) {
          final lv = p.upgradeLv[u.id] ?? 0;
          final cost = u.baseCost * (lv + 1);
          return _card(
            color: PO.accent,
            active: true,
            child: ListTile(
              title: Text('${u.name}  Lv $lv/${u.maxLevel}', style: pixText(size: 14, weight: FontWeight.w700)),
              subtitle: Text('Стоимость: $cost scrap (или x2 монет)', style: pixText(size: 11, color: PO.muted)),
              trailing: TextButton(
                onPressed: lv >= u.maxLevel
                    ? null
                    : () async {
                        if (p.buyUpgrade(u.id)) {
                          await p.save();
                          setState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не хватает ресурсов', style: pixText(size: 12)), backgroundColor: PO.panel));
                        }
                      },
                child: Text(lv >= u.maxLevel ? 'MAX' : 'UP', style: pixText(color: PO.gold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════ BASE ════════════════

class BaseScreen extends StatefulWidget {
  final PlayerProgress progress;
  const BaseScreen({super.key, required this.progress});
  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  PlayerProgress get p => widget.progress;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _t = d.inMilliseconds / 1000.0))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'БАЗА'),
      body: Column(children: [
        Expanded(
          child: CustomPaint(
            painter: _BasePainter(_t, p.baseLevel),
            size: Size.infinite,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text('Уровень базы ${p.baseLevel}/10  ·  Мощность ${p.basePower}', style: pixText(size: 13)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.gold, width: 2)),
                onPressed: () async {
                  if (p.upgradeBase()) {
                    await p.save();
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Нужно ${150 * p.baseLevel} монет', style: pixText(size: 12)), backgroundColor: PO.panel));
                  }
                },
                child: Text('УЛУЧШИТЬ · ${150 * p.baseLevel} C', style: pixText(color: PO.gold)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _BasePainter extends CustomPainter {
  final double t;
  final int level;
  _BasePainter(this.t, this.level);
  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = PO.bg);
    final cx = size.width / 2;
    final cy = size.height * 0.55;
    // platform
    for (var i = 0; i < level + 2; i++) {
      final r = Rect.fromCenter(center: Offset(cx, cy - i * 18.0), width: 120 + i * 8.0, height: 16);
      drawPanel(c, r, fill: PO.panel2, border: i < level ? PO.accent : PO.border);
    }
    // antenna blink
    final on = (t * 3).floor() % 2 == 0;
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy - (level + 2) * 18.0), width: 6, height: 24), Paint()..color = on ? PO.ok : PO.muted);
    heroSprite('rex').paint(c, Offset(cx, cy - level * 10), 2.5);
  }
  @override
  bool shouldRepaint(covariant _BasePainter old) => true;
}

// ════════════════ CHESTS ════════════════

class ChestScreen extends StatefulWidget {
  final PlayerProgress progress;
  const ChestScreen({super.key, required this.progress});
  @override
  State<ChestScreen> createState() => _ChestScreenState();
}

class _ChestScreenState extends State<ChestScreen> {
  PlayerProgress get p => widget.progress;

  void _show(Map<String, int> r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PO.panel,
        title: Text('ЛУТ', style: pixText(color: PO.gold)),
        content: Text('+${r['coins']} C\n+${r['gems']} G\n+${r['scrap']} S', style: pixText(size: 14)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: pixText(color: PO.accent)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'СУНДУКИ · free ${p.freeChests}'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p.freeChests > 0)
            _card(
              color: PO.gold,
              active: true,
              child: ListTile(
                title: Text('ТРОФЕЙНЫЙ', style: pixText(size: 14, color: PO.gold, weight: FontWeight.w700)),
                subtitle: Text('За кампанию', style: pixText(size: 11, color: PO.muted)),
                trailing: TextButton(
                  onPressed: () async {
                    final r = p.openFreeChest();
                    if (r != null) {
                      await p.save();
                      setState(() {});
                      _show(r);
                    }
                  },
                  child: Text('OPEN', style: pixText(color: PO.gold)),
                ),
              ),
            ),
          ...[
            (80, 40, 120, 'ДЕРЕВО'),
            (200, 100, 280, 'ЖЕЛЕЗО'),
            (450, 220, 500, 'ЗОЛОТО'),
          ].map((e) => _card(
                color: PO.accent,
                active: true,
                child: ListTile(
                  title: Text(e.$4, style: pixText(size: 14, weight: FontWeight.w700)),
                  subtitle: Text('${e.$2}-${e.$3} C + scrap/gems', style: pixText(size: 11, color: PO.muted)),
                  trailing: TextButton(
                    onPressed: () async {
                      final r = p.buyChest(e.$1, e.$2, e.$3);
                      if (r != null) {
                        await p.save();
                        setState(() {});
                        _show(r);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Мало монет', style: pixText(size: 12)), backgroundColor: PO.panel));
                      }
                    },
                    child: Text('${e.$1} C', style: pixText(color: PO.accent)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ════════════════ EVENTS ════════════════

class EventsScreen extends StatelessWidget {
  final PlayerProgress progress;
  const EventsScreen({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ИВЕНТЫ'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: events
            .map((e) => _card(
                  color: PO.gold,
                  active: true,
                  child: ListTile(
                    title: Text(e.title, style: pixText(size: 14, weight: FontWeight.w700, color: PO.gold)),
                    subtitle: Text('${e.desc}\nРежим: ${e.mode}', style: pixText(size: 11, color: PO.muted)),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GameScreen(progress: progress, mode: e.mode == 'arena' ? 'arena' : e.mode)),
                        );
                      },
                      child: Text('GO', style: pixText(color: PO.accent)),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ════════════════ FRIENDS ════════════════

class FriendsScreen extends StatefulWidget {
  final PlayerProgress progress;
  const FriendsScreen({super.key, required this.progress});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  PlayerProgress get p => widget.progress;
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ДРУЗЬЯ'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Локальный список (онлайн-дуэли — позже)', style: pixText(size: 11, color: PO.muted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: pixText(),
                decoration: InputDecoration(
                  hintText: 'Имя друга',
                  hintStyle: pixText(color: PO.muted),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: PO.border, width: 2)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: PO.accent, width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                p.addFriend(_ctrl.text);
                _ctrl.clear();
                await p.save();
                setState(() {});
              },
              child: Text('ADD', style: pixText(color: PO.gold)),
            ),
          ]),
          const SizedBox(height: 12),
          ...p.friends.map((f) => _card(
                color: PO.accent,
                active: true,
                child: ListTile(
                  title: Text(f, style: pixText(size: 14)),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: 'arena')));
                    },
                    child: Text('ДУЭЛЬ', style: pixText(size: 11, color: PO.gold)),
                  ),
                ),
              )),
          if (p.friends.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text('Пока пусто — добавь имя и вызови на арену (AI-соперник).', style: pixText(color: PO.muted))),
        ],
      ),
    );
  }
}

// ════════════════ UI HELPERS ════════════════

PreferredSizeWidget _bar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: PO.panel,
    title: Text(title, style: pixText(size: 15, color: PO.gold)),
    leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
  );
}

Widget _card({required Color color, required bool active, required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: PO.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: active ? color : PO.border, width: 2),
    ),
    child: child,
  );
}

Widget _pixBadge(String t, Color c) {
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: c.withOpacity(0.25), border: Border.all(color: c, width: 2), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: pixText(size: 14, color: c, weight: FontWeight.w800)),
  );
}
