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

// ════════════════════ MENU ════════════════════

class MainMenu extends StatefulWidget {
  final PlayerProgress progress;
  const MainMenu({super.key, required this.progress});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
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

  void _play(String mode, {int worldId = 0}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => GameScreen(progress: p, mode: mode, worldId: worldId),
        ))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          CustomPaint(painter: _MenuBgPainter(_t), size: Size.infinite),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              children: [
                Row(children: [
                  Text('PIXEL ORBIT', style: pixText(size: 20, color: PO.gold, weight: FontWeight.w800)),
                  const Spacer(),
                  Text(OnlineService.ready ? 'ONLINE' : 'OFFLINE',
                      style: pixText(size: 10, color: OnlineService.ready ? PO.ok : PO.muted)),
                ]),
                Text('Кампания · Сундуки · Герои', style: pixText(size: 10, color: PO.muted)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 72,
                  child: CustomPaint(painter: _ShipShowcasePainter(_t), size: const Size(double.infinity, 72)),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _chip('🪙 ${p.coins}'),
                  const SizedBox(width: 6),
                  _chip('💎 ${p.gems}'),
                  const SizedBox(width: 6),
                  _chip('📦 ${p.freeChests}'),
                  const SizedBox(width: 6),
                  _chip('W${p.campaignWorld}'),
                ]),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.65,
                    children: [
                      _tile('🗺 КАМПАНИЯ', '10 миров', const Color(0xFF5B8CFF), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignScreen(progress: p)))
                            .then((_) => setState(() {}));
                      }),
                      _tile('▶ КЛАССИКА', 'Волны', PO.accent, () => _play('classic')),
                      _tile('∞ ENDLESS', 'Без конца', const Color(0xFFFF6A4A), () => _play('endless')),
                      _tile('📦 СУНДУКИ', 'Награды', const Color(0xFFFFB040), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChestScreen(progress: p)))
                            .then((_) => setState(() {}));
                      }),
                      _tile('👤 ГЕРОИ', p.hero.name, const Color(0xFF40C070), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => HeroesScreen(progress: p)))
                            .then((_) => setState(() {}));
                      }),
                      _tile('🛒 МАГАЗИН', 'Скины', const Color(0xFFFF80D0), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(progress: p)))
                            .then((_) => setState(() {}));
                      }),
                      _tile('🎖 СЕЗОН', 'Пропуск', const Color(0xFF6A4AFF), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SeasonScreen(progress: p)))
                            .then((_) => setState(() {}));
                      }),
                      _tile('🏆 РЕЙТИНГ', 'Онлайн', const Color(0xFF40C0A0), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen()));
                      }),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final ctrl = TextEditingController(text: OnlineService.displayName);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: PO.panel,
                        title: Text('Пилот', style: pixText(color: PO.gold)),
                        content: TextField(controller: ctrl, maxLength: 16, style: pixText()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('OK', style: pixText(color: PO.accent))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await OnlineService.setName(ctrl.text);
                      setState(() {});
                    }
                  },
                  child: Text('${OnlineService.displayName} · S${p.seasonLevel}', style: pixText(size: 11, color: PO.muted)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: PO.panel, border: Border.all(color: PO.border, width: 2), borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: pixText(size: 11)),
      );

  Widget _tile(String title, String sub, Color c, VoidCallback onTap) {
    return Material(
      color: c.withOpacity(0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: c, width: 2)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: pixText(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(sub, style: pixText(size: 11, color: PO.muted)),
          ]),
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
  bool shouldRepaint(covariant _MenuBgPainter o) => true;
}

class _ShipShowcasePainter extends CustomPainter {
  final double t;
  _ShipShowcasePainter(this.t);
  @override
  void paint(Canvas c, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    shipSprite.paint(c, Offset(cx, cy), 3.2);
    enemySprite.paint(c, Offset(cx - 80, cy), 1.8);
    bossSprite.paint(c, Offset(cx + 85, cy), 1.5);
  }
  @override
  bool shouldRepaint(covariant _ShipShowcasePainter o) => true;
}

// ════════════════════ CAMPAIGN ════════════════════

class CampaignScreen extends StatefulWidget {
  final PlayerProgress progress;
  const CampaignScreen({super.key, required this.progress});
  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  PlayerProgress get p => widget.progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('КАМПАНИЯ', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: worlds.length,
        itemBuilder: (_, i) {
          final w = worlds[i];
          final unlocked = p.worldUnlocked(w.id);
          final cleared = p.worldCleared(w.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: PO.panel,
              border: Border.all(color: cleared ? PO.gold : unlocked ? Color(w.color) : PO.border, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              enabled: unlocked,
              leading: CircleAvatar(
                backgroundColor: Color(w.color).withOpacity(unlocked ? 0.35 : 0.1),
                child: Text('${w.id}', style: pixText(color: unlocked ? PO.text : PO.muted)),
              ),
              title: Text(w.name, style: pixText(size: 14, color: unlocked ? PO.text : PO.muted, weight: FontWeight.w700)),
              subtitle: Text(
                unlocked ? '${w.blurb} · ${w.wavesToClear} волн' : 'Пройди предыдущий мир',
                style: pixText(size: 11, color: PO.muted),
              ),
              trailing: Text(cleared ? '✓' : unlocked ? '▶' : '🔒', style: pixText(size: 16, color: PO.gold)),
              onTap: !unlocked
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(progress: p, mode: 'campaign', worldId: w.id),
                        ),
                      ).then((_) => setState(() {}));
                    },
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════ CHESTS ════════════════════

class ChestScreen extends StatefulWidget {
  final PlayerProgress progress;
  const ChestScreen({super.key, required this.progress});
  @override
  State<ChestScreen> createState() => _ChestScreenState();
}

class _ChestScreenState extends State<ChestScreen> {
  PlayerProgress get p => widget.progress;

  Future<void> _open(ChestDef def, {bool free = false}) async {
    final r = p.openChest(def, free: free);
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(free ? 'Нет бесплатных сундуков' : 'Не хватает монет', style: pixText(size: 12)),
        backgroundColor: PO.panel,
      ));
      return;
    }
    await p.save();
    setState(() {});
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PO.panel,
        title: Text('Сундук открыт!', style: pixText(size: 16, color: PO.gold)),
        content: Text(
          '+${r.coins} 🪙'
          '${r.gems > 0 ? '\n+${r.gems} 💎' : ''}'
          '${r.skinId != null ? '\nСкин: ${r.skinId}' : ''}',
          style: pixText(size: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: pixText(color: PO.accent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('СУНДУКИ', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('📦 ${p.freeChests}  🪙 ${p.coins}', style: pixText(size: 12, color: PO.gold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p.freeChests > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: PO.gold.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: PO.gold, width: 2)),
                child: InkWell(
                  onTap: () => _open(chests.first, free: true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Text('🎁', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Бесплатный сундук', style: pixText(size: 15, color: PO.gold, weight: FontWeight.w700)),
                          Text('За победы в кампании · осталось ${p.freeChests}', style: pixText(size: 12, color: PO.muted)),
                        ]),
                      ),
                      Text('Открыть', style: pixText(color: PO.gold)),
                    ]),
                  ),
                ),
              ),
            ),
          ...chests.map((def) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PO.panel,
                border: Border.all(color: PO.border, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Text('📦', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(def.name, style: pixText(size: 14, weight: FontWeight.w700)),
                    Text('${def.minCoins}–${def.maxCoins} 🪙 · гемы ${def.gemChance}% · скин ${def.skinChance}%',
                        style: pixText(size: 11, color: PO.muted)),
                  ]),
                ),
                TextButton(
                  onPressed: () => _open(def),
                  child: Text('🪙 ${def.priceCoins}', style: pixText(color: PO.accent)),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ════════════════════ HEROES ════════════════════

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
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('ГЕРОИ', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: heroes.length,
        itemBuilder: (_, i) {
          final h = heroes[i];
          final owned = p.ownedHeroes.contains(h.id);
          final active = p.activeHero == h.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PO.panel,
              border: Border.all(color: active ? PO.gold : owned ? Color(h.color) : PO.border, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(h.color).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(h.color), width: 2),
                ),
                child: Center(child: Text(h.name.characters.first, style: pixText(size: 18, color: Color(h.color)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${h.name} · ${h.role}', style: pixText(size: 14, weight: FontWeight.w700, color: owned ? PO.text : PO.muted)),
                  Text(owned ? h.desc : 'Мир ${h.unlockWorld}+', style: pixText(size: 11, color: PO.muted)),
                ]),
              ),
              if (owned)
                TextButton(
                  onPressed: () async {
                    p.selectHero(h.id);
                    await p.save();
                    setState(() {});
                  },
                  child: Text(active ? '✓' : 'Выбрать', style: pixText(color: PO.accent)),
                )
              else
                Text('🔒', style: pixText(size: 16)),
            ]),
          );
        },
      ),
    );
  }
}

// ════════════════════ GAME ════════════════════

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
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final skin = shopSkins.where((s) => s.id == widget.progress.activeSkin).firstOrNull ?? shopSkins.first;
    final hero = widget.progress.hero;
    WorldInfo? winfo;
    if (widget.mode == 'campaign' && widget.worldId > 0) {
      winfo = worlds.firstWhere((w) => w.id == widget.worldId);
    }
    world = GameWorld(
      w: 360,
      h: 640,
      mode: widget.mode,
      skinColor: skin.color,
      worldId: widget.worldId,
      wavesGoal: winfo?.wavesToClear ?? 0,
      bossHpBonus: winfo?.bossHp ?? 0,
      fireRateMul: hero.fireRateMul,
      damageMul: hero.damageMul,
      speedMul: hero.speedMul,
      bonusLives: hero.id == 'aegis' ? 1 : 0,
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
        final mode = widget.mode;
        widget.progress.addScore(world.score, mode: mode);
        if (world.victory && mode == 'campaign') {
          widget.progress.clearWorld(widget.worldId);
        }
        widget.progress.save();
        OnlineService.submitScore(score: world.score, wave: world.wave, mode: mode);
      }
    } catch (e, st) {
      debugPrint('tick: $e\n$st');
    }
  }

  @override
  void dispose() {
    ticker.dispose();
    world.dispose();
    super.dispose();
  }

  void _pointer(Offset global) {
    final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    world.targetX = (local.dx / box.size.width * world.w).clamp(20.0, world.w - 20.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PO.bg,
      body: LayoutBuilder(builder: (ctx, constraints) {
        world.resize(constraints.maxHeight / (constraints.maxWidth / 360.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _pointer(d.globalPosition),
          onPanUpdate: (d) => _pointer(d.globalPosition),
          onTapDown: (d) {
            if (world.gameOver) {
              Navigator.pop(context);
              return;
            }
            _pointer(d.globalPosition);
          },
          child: AnimatedBuilder(
            animation: world,
            builder: (_, __) => CustomPaint(
              key: _paintKey,
              painter: _GamePainter(world),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        );
      }),
    );
  }
}

class _GamePainter extends CustomPainter {
  final GameWorld world;
  _GamePainter(this.world) : super(repaint: world);
  @override
  void paint(Canvas canvas, Size size) {
    try {
      world.paint(canvas, size);
    } catch (e, st) {
      debugPrint('paint: $e\n$st');
    }
  }
  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}

// ════════════════════ SHOP ════════════════════

class ShopScreen extends StatefulWidget {
  final PlayerProgress progress;
  const ShopScreen({super.key, required this.progress});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('МАГАЗИН', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
        actions: [Padding(padding: const EdgeInsets.all(12), child: Text('🪙 ${p.coins}', style: pixText(color: PO.gold)))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: shopSkins.length,
        itemBuilder: (_, i) {
          final s = shopSkins[i];
          final owned = p.ownedSkins.contains(s.id);
          final active = p.activeSkin == s.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PO.panel,
              border: Border.all(color: active ? PO.gold : PO.border, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(s.color).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(s.color), width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: pixText(size: 14, weight: FontWeight.w700)),
                  Text(owned ? (active ? 'Выбран' : 'Куплен') : '🪙 ${s.price}', style: pixText(size: 12, color: PO.muted)),
                ]),
              ),
              TextButton(
                onPressed: () async {
                  if (p.buySkin(s.id)) {
                    await p.save();
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Мало монет', style: pixText(size: 12)), backgroundColor: PO.panel));
                  }
                },
                child: Text(active ? '✓' : owned ? 'Надеть' : 'Купить', style: pixText(color: PO.accent)),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ════════════════════ LEADERBOARD ════════════════════

class LeaderboardScreen extends StatefulWidget {
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String mode = 'classic';
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await OnlineService.topScores(mode: mode);
    setState(() {
      rows = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PO.panel,
        title: Text('РЕЙТИНГ', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => mode = mode == 'classic' ? 'endless' : 'classic');
              _load();
            },
            child: Text(mode.toUpperCase(), style: pixText(color: PO.accent, size: 12)),
          ),
        ],
      ),
      body: !OnlineService.ready
          ? Center(child: Text('Онлайн недоступен', style: pixText(color: PO.muted)))
          : loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                  ? Center(child: Text('Пусто — сыграй и займи место\n(+ SQL po_scores)', textAlign: TextAlign.center, style: pixText(color: PO.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: PO.panel,
                            border: Border.all(color: i < 3 ? PO.gold : PO.border, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            SizedBox(width: 28, child: Text('#${i + 1}', style: pixText(color: PO.gold))),
                            Expanded(child: Text('${r['display_name']}', style: pixText(size: 13))),
                            Text('${r['score']}', style: pixText(size: 14, color: PO.accent, weight: FontWeight.w700)),
                          ]),
                        );
                      },
                    ),
    );
  }
}

// ════════════════════ SEASON ════════════════════

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
        title: Text('СЕЗОН', style: pixText(size: 16, color: PO.gold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: PO.panel,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Уровень ${p.seasonLevel} / 20', style: pixText(size: 18)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: p.levelProgress, minHeight: 10, backgroundColor: PO.border, color: PO.accent),
            ),
            const SizedBox(height: 8),
            if (!p.premium)
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: PO.gold, side: const BorderSide(color: PO.gold, width: 2)),
                onPressed: () async {
                  if (p.buyPremium()) {
                    await p.save();
                    setState(() {});
                  }
                },
                child: Text('PREMIUM — 600 💎/🪙', style: pixText(size: 13, color: PO.gold)),
              )
            else
              Text('★ PREMIUM', style: pixText(color: PO.gold)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: seasonRewards.length,
            itemBuilder: (ctx, i) {
              final r = seasonRewards[i];
              final unlocked = r.level <= p.seasonLevel;
              final freeTaken = p.claimedFree.contains(r.level);
              final premTaken = p.claimedPremium.contains(r.level);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PO.panel,
                  border: Border.all(color: unlocked ? PO.accent : PO.border, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  SizedBox(width: 32, child: Text('${r.level}', style: pixText(color: PO.gold, weight: FontWeight.w800))),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('FREE: ${r.freeName}', style: pixText(size: 12)),
                      Text('PREM: ${r.premiumName}', style: pixText(size: 12, color: p.premium ? PO.gold : PO.muted)),
                    ]),
                  ),
                  Column(children: [
                    _btn(freeTaken ? '✓' : 'F', unlocked && !freeTaken, () async {
                      if (p.claimFree(r.level)) {
                        await p.save();
                        setState(() {});
                      }
                    }),
                    const SizedBox(height: 4),
                    _btn(premTaken ? '✓' : 'P', p.premium && unlocked && !premTaken, () async {
                      if (p.claimPremium(r.level)) {
                        await p.save();
                        setState(() {});
                      }
                    }),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _btn(String label, bool enabled, VoidCallback onTap) {
    return SizedBox(
      height: 26,
      width: 36,
      child: Material(
        color: enabled ? PO.accent.withOpacity(0.3) : PO.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(child: Text(label, style: pixText(size: 11, color: enabled ? PO.text : PO.muted))),
        ),
      ),
    );
  }
}
