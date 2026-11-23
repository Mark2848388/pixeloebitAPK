import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'content.dart';
import 'game.dart';
import 'online.dart';
import 'pixel.dart';
import 'progress.dart';
import 'screens_extra.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await OnlineService.init();
  } catch (_) {}
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
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: PO.bg, useMaterial3: true),
      home: MainMenu(progress: progress),
    );
  }
}

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

  static const items = [
    ('КАМПАНИЯ', '10 миров', 0xFF5B8CFF),
    ('КЛАССИКА', 'волны', 0xFF4A7AFF),
    ('ENDLESS', 'без конца', 0xFFFF6A4A),
    ('АРЕНА MMR', 'ранг', 0xFFFFB040),
    ('РЕЙД', 'босс', 0xFFFF4A6A),
    ('ГЕРОИ', 'корабли', 0xFF40C070),
    ('ПЕРСОНАЖИ', 'коллекция', 0xFFFF80D0),
    ('АНГАР', 'мир', 0xFF9B4DFF),
    ('СЕЗОН 40', 'пропуск', 0xFFFFD34A),
    ('СУНДУКИ', 'гача', 0xFF40FFA0),
    ('ПРОФИЛЬ', 'фото', 0xFF8BB4FF),
    ('ДРУЗЬЯ', 'дуэли', 0xFF8A96B0),
    ('БАЗА', 'уровень', 0xFF40C0A0),
    ('ПРОКАЧКА', 'апгрейды', 0xFF5B8CFF),
    ('УВЕДОМЛ.', 'журнал', 0xFF8A96B0),
    ('ПОМОЩНИКИ', 'дрон', 0xFF40FFA0),
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


  void _go(int i) {
    HapticFeedback.selectionClick();
    setState(() => _sel = i);
    Future<void> play(String mode, {int worldId = 0}) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: mode, worldId: worldId)));
      setState(() {});
    }
    switch (i) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignScreen(progress: p))).then((_) => setState(() {}));
      case 1:
        _play('classic');
      case 2:
        _play('endless');
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ArenaRankScreen(progress: p, onPlay: play))).then((_) => setState(() {}));
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => RaidScreen(progress: p, onPlay: play))).then((_) => setState(() {}));
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HeroesScreen(progress: p))).then((_) => setState(() {}));
      case 6:
        Navigator.push(context, MaterialPageRoute(builder: (_) => CharactersScreen(progress: p))).then((_) => setState(() {}));
      case 7:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HangarWorldScreen(progress: p))).then((_) => setState(() {}));
      case 8:
        Navigator.push(context, MaterialPageRoute(builder: (_) => SeasonScreen(progress: p))).then((_) => setState(() {}));
      case 9:
        Navigator.push(context, MaterialPageRoute(builder: (_) => GachaChestScreen(progress: p))).then((_) => setState(() {}));
      case 10:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(progress: p))).then((_) => setState(() {}));
      case 11:
        Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineFriendsScreen(progress: p, onPlay: play))).then((_) => setState(() {}));
      case 12:
        Navigator.push(context, MaterialPageRoute(builder: (_) => BaseScreen(progress: p))).then((_) => setState(() {}));
      case 13:
        Navigator.push(context, MaterialPageRoute(builder: (_) => HangarScreen(progress: p))).then((_) => setState(() {}));
      case 14:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(progress: p))).then((_) => setState(() {}));
      case 15:
        Navigator.push(context, MaterialPageRoute(builder: (_) => CompanionsScreen(progress: p))).then((_) => setState(() {}));
    }
  }

  void _play(String mode, {int worldId = 0}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: mode, worldId: worldId))).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomPaint(
          painter: _MenuPainter(t: _t, sel: _sel, items: items, p: p),
          child: Column(children: [
            const SizedBox(height: 150),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.15,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _go(i),
                    onHighlightChanged: (h) { if (h) setState(() => _sel = i); },
                    borderRadius: BorderRadius.circular(8),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MenuPainter extends CustomPainter {
  final double t;
  final int sel;
  final List<(String, String, int)> items;
  final PlayerProgress p;
  _MenuPainter({required this.t, required this.sel, required this.items, required this.p});

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = PO.bg);
    final sp = Paint()..color = const Color(0xFF6A7A9A);
    for (var i = 0; i < 50; i++) {
      final x = (i * 71 + t * (5 + i % 4)) % (size.width + 6);
      final y = (i * 89 + t * (2 + i % 3)) % size.height;
      c.drawRect(Rect.fromLTWH(x, y, 2, 2), sp);
    }
    drawPanel(c, Rect.fromLTWH(12, 8, size.width - 24, 48), border: PO.gold);
    _t(c, 'PIXEL ORBIT', size.width / 2 - 52, 16, 18, PO.gold);
    _t(c, '${p.playerName}  ·  W${p.campaignWorld}  ·  ★${p.highScore}', size.width / 2 - 70, 38, 10, PO.muted);

    final hx = size.width / 2;
    final hy = 95.0 + 3 * ((t * 1.2) % 1 - 0.5).abs();
    heroSprite(p.activeHero).paint(c, Offset(hx, hy), 3.6);
    enemySprite.paint(c, Offset(hx - 72, hy), 2.2);
    bossP1.paint(c, Offset(hx + 74, hy), 1.6);

    drawPanel(c, Rect.fromLTWH(12, 128, size.width - 24, 26), fill: PO.panel2);
    _t(c, 'C ${p.coins}   G ${p.gems}   S ${p.scrap}', 24, 134, 12, PO.text);

    // visual tiles
    const top = 162.0;
    final tileW = (size.width - 14 * 2 - 8) / 2;
    const tileH = 48.0;
    for (var i = 0; i < items.length; i++) {
      final col = i % 2, row = i ~/ 2;
      final r = Rect.fromLTWH(14 + col * (tileW + 8), top + row * (tileH + 8), tileW, tileH);
      if (r.bottom > size.height - 4) continue;
      final hot = i == sel;
      final colr = Color(items[i].$3);
      drawPanel(c, r, fill: hot ? colr.withOpacity(0.3) : PO.panel, border: hot ? colr : PO.border, thick: hot ? 2.5 : 2);
      c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 6, 4, r.height - 12), Paint()..color = colr);
      _t(c, items[i].$1, r.left + 14, r.top + 10, 12, hot ? PO.gold : PO.text);
      _t(c, items[i].$2, r.left + 14, r.top + 28, 10, PO.muted);
    }
  }

  void _t(Canvas c, String s, double x, double y, double size, Color col) {
    final tp = TextPainter(text: TextSpan(text: s, style: pixText(size: size, color: col)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _MenuPainter old) => true;
}

// ───── GAME ─────
class GameScreen extends StatefulWidget {
  final PlayerProgress progress;
  final String mode;
  final int worldId;
  final int levelId;
  const GameScreen({super.key, required this.progress, this.mode = 'classic', this.worldId = 0, this.levelId = 1});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameWorld world;
  late Ticker ticker;
  Duration _last = Duration.zero;
  bool _saved = false;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    final h = widget.progress.hero;
    WorldInfo? wi;
    if (widget.mode == 'campaign' && widget.worldId > 0) {
      wi = worlds.firstWhere((w) => w.id == widget.worldId);
    }
    // campaign: one combat wave; bosses injected on L5/L10
    final goal = widget.mode == 'campaign' ? 1 : (wi?.wavesToClear ?? 0);
    world = GameWorld(
      w: 360,
      h: 640,
      mode: widget.mode,
      worldId: widget.worldId,
      levelId: widget.levelId,
      wavesGoal: goal,
      bossHpBonus: (wi?.bossHp ?? 0).toDouble(),
      fireRateMul: h.fireRateMul,
      damageMul: h.damageMul * widget.progress.dmgMul,
      speedMul: h.speedMul,
      heroId: h.id,
      weapon: h.weapon,
      dmgUp: widget.progress.dmgMul,
      rateUp: widget.progress.rateMul,
      dashMul: widget.progress.dashCdMul,
      ultMul: widget.progress.ultCdMul,
      regenPerSec: widget.progress.regenPerSec,
      bonusLives: h.bonusLives + widget.progress.extraHull,
      companionId: widget.progress.activeCompanion,
    );
    ticker = createTicker(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ticker.start();
    });
  }

  void _tick(Duration e) {
    try {
      var dt = _last == Duration.zero ? 1 / 60 : (e - _last).inMicroseconds / 1e6;
      _last = e;
      if (dt <= 0 || dt > 1) dt = 1 / 60;
      world.update(dt);
      if (world.gameOver && !_saved) {
        _saved = true;
        widget.progress.addScore(world.score, mode: widget.mode);
        if (world.victory && widget.mode == 'campaign') {
          widget.progress.clearCampaignLevel(widget.worldId, widget.levelId);
        }
        if (world.victory && widget.mode == 'arena') widget.progress.arenaWins++;
        widget.progress.save();
        try {
          OnlineService.submitScore(score: world.score, wave: world.wave, mode: widget.mode);
        } catch (_) {}
      }
    } catch (err, st) {
      debugPrint('$err\n$st');
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
    world.tx = (l.dx / box.size.width * world.w).clamp(24.0, world.w - 24.0);
    world.ty = (l.dy / box.size.height * world.h).clamp(48.0, world.h - 48.0);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: PO.bg,
      body: LayoutBuilder(builder: (_, cons) {
        world.resize(cons.maxHeight / (cons.maxWidth / 360.0));
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
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
          ),
          Positioned(
            right: 10,
            bottom: 16 + pad.bottom,
            child: Column(children: [
              _btn('УЛЬТА', () => world.tryUlt()),
              const SizedBox(height: 8),
              _btn('РЫВОК', () => world.tryDash()),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _btn(String t, VoidCallback fn) => Material(
        color: PO.panel2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: PO.accent, width: 2)),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            fn();
          },
          child: SizedBox(width: 76, height: 42, child: Center(child: Text(t, style: pixText(size: 12, color: PO.gold)))),
        ),
      );
}

class _GP extends CustomPainter {
  final GameWorld world;
  _GP(this.world) : super(repaint: world);
  @override
  void paint(Canvas c, Size s) {
    try {
      world.paint(c, s);
    } catch (e, st) {
      debugPrint('$e\n$st');
    }
  }
  @override
  bool shouldRepaint(covariant _GP old) => true;
}

// ───── SCREENS ─────
PreferredSizeWidget _bar(BuildContext c, String t) => AppBar(
      backgroundColor: PO.panel,
      title: Text(t, style: pixText(size: 15, color: PO.gold)),
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: PO.text), onPressed: () => Navigator.pop(c)),
    );

Widget _card({required Color color, required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: PO.panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: color, width: 2)),
      child: child,
    );

class CampaignScreen extends StatelessWidget {
  final PlayerProgress progress;
  const CampaignScreen({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'КАМПАНИЯ · ${progress.campaignStages}/100'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: worlds.length,
        itemBuilder: (_, i) {
          final w = worlds[i];
          final ok = progress.worldUnlocked(w.id);
          final done = progress.worldCleared(w.id);
          return _card(
            color: ok ? Color(w.color) : PO.border,
            child: ExpansionTile(
              enabled: ok,
              title: Text(w.name, style: pixText(size: 14, color: ok ? PO.text : PO.muted, weight: FontWeight.w700)),
              subtitle: Text(ok ? (done ? 'Мир пройден' : 'Ур. ${progress.unlockedLevelInWorld(w.id)}/10') : 'Закрыто', style: pixText(size: 11, color: PO.muted)),
              children: !ok
                  ? []
                  : List.generate(10, (li) {
                      final level = li + 1;
                      final unlocked = progress.levelUnlocked(w.id, level);
                      final cleared = progress.campaignStages >= (w.id - 1) * 10 + level;
                      String tag = level == 5 ? 'БОСС' : level == 10 ? 'БОЛЬШОЙ БОСС' : 'бой';
                      return ListTile(
                        enabled: unlocked,
                        dense: true,
                        title: Text('Уровень $level · $tag', style: pixText(size: 13, color: unlocked ? PO.text : PO.muted)),
                        trailing: Text(cleared ? 'OK' : unlocked ? 'PLAY' : 'LOCK', style: pixText(size: 11, color: PO.gold)),
                        onTap: !unlocked
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(progress: progress, mode: 'campaign', worldId: w.id, levelId: level),
                                  ),
                                ).then((_) {}),
                      );
                    }),
            ),
          );
        },
      ),
    );
  }
}

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
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                SizedBox(width: 52, height: 52, child: CustomPaint(painter: _HeroPaint(h.id))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${h.name} · ${h.role}', style: pixText(size: 13, weight: FontWeight.w700, color: owned ? PO.text : PO.muted)),
                    Text(h.desc, style: pixText(size: 11, color: PO.muted)),
                    Text('${h.ultName} / ${h.dashName}', style: pixText(size: 10, color: Color(h.color))),
                  ]),
                ),
                if (owned)
                  TextButton(
                    onPressed: () async {
                      p.selectHero(h.id);
                      await p.save();
                      setState(() {});
                    },
                    child: Text(active ? 'ON' : 'SET', style: pixText(size: 11, color: PO.gold)),
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

class _HeroPaint extends CustomPainter {
  final String id;
  _HeroPaint(this.id);
  @override
  void paint(Canvas c, Size s) {
    drawPanel(c, Offset.zero & s, fill: PO.panel2);
    heroSprite(id).paint(c, Offset(s.width / 2, s.height / 2), 2.4);
  }
  @override
  bool shouldRepaint(covariant _HeroPaint old) => old.id != id;
}

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
            child: ListTile(
              title: Text('${u.name}  Lv$lv/${u.maxLevel}', style: pixText(size: 14, weight: FontWeight.w700)),
              subtitle: Text('$cost scrap (или x2 монет)', style: pixText(size: 11, color: PO.muted)),
              trailing: TextButton(
                onPressed: lv >= u.maxLevel
                    ? null
                    : () async {
                        if (p.buyUpgrade(u.id)) {
                          await p.save();
                          setState(() {});
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

class BaseScreen extends StatefulWidget {
  final PlayerProgress progress;
  const BaseScreen({super.key, required this.progress});
  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'БАЗА'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Уровень ${p.baseLevel}/10', style: pixText(size: 18, color: PO.gold)),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(painter: _BasePaint(p.baseLevel), size: Size.infinite),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.gold, width: 2)),
              onPressed: () async {
                if (p.upgradeBase()) {
                  await p.save();
                  setState(() {});
                }
              },
              child: Text('УЛУЧШИТЬ · ${150 * p.baseLevel} C', style: pixText(color: PO.gold)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BasePaint extends CustomPainter {
  final int level;
  _BasePaint(this.level);
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = PO.bg);
    final cx = s.width / 2, cy = s.height * 0.55;
    for (var i = 0; i < level + 1; i++) {
      drawPanel(c, Rect.fromCenter(center: Offset(cx, cy - i * 16.0), width: 100.0 + i * 10, height: 14), border: PO.accent);
    }
    heroSprite('rex').paint(c, Offset(cx, cy - level * 8), 2.8);
  }
  @override
  bool shouldRepaint(covariant _BasePaint old) => old.level != level;
}


class ProfileScreen extends StatefulWidget {
  final PlayerProgress progress;
  const ProfileScreen({super.key, required this.progress});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController bio;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.progress.playerName);
    bio = TextEditingController(text: widget.progress.bio);
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/profile.jpg');
      await File(x.path).copy(dest.path);
      widget.progress.profilePhotoPath = dest.path;
      await widget.progress.save();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Фото: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final photo = p.profilePhotoPath.isNotEmpty ? File(p.profilePhotoPath) : null;
    return Scaffold(
      appBar: _bar(context, 'ПРОФИЛЬ'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: PO.panel2,
                backgroundImage: photo != null && photo.existsSync() ? FileImage(photo) : null,
                child: photo == null || !photo.existsSync()
                    ? const Icon(Icons.add_a_photo, color: PO.accent, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('Нажми — выбрать фото', style: pixText(size: 11, color: PO.muted))),
          const SizedBox(height: 16),
          Text('Имя пилота', style: pixText(size: 12, color: PO.muted)),
          TextField(controller: name, maxLength: 16, style: pixText(), decoration: const InputDecoration(border: OutlineInputBorder())),
          Text('Био', style: pixText(size: 12, color: PO.muted)),
          TextField(controller: bio, maxLines: 3, maxLength: 80, style: pixText(), decoration: const InputDecoration(border: OutlineInputBorder())),
          Text('Игр: ${p.gamesPlayed} · Арена: ${p.arenaWins} · Сезон ${p.seasonLevel}', style: pixText(size: 12, color: PO.muted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.accent, width: 2)),
              onPressed: () async {
                p.playerName = name.text.trim().isEmpty ? p.playerName : name.text.trim();
                p.bio = bio.text.trim();
                try { await OnlineService.setName(p.playerName); } catch (_) {}
                p.pushNote('Профиль сохранён');
                await p.save();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сохранено', style: pixText(size: 12)), backgroundColor: PO.panel));
                  setState(() {});
                }
              },
              child: Text('СОХРАНИТЬ', style: pixText(color: PO.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class CompanionsScreen extends StatefulWidget {
  final PlayerProgress progress;
  const CompanionsScreen({super.key, required this.progress});
  @override
  State<CompanionsScreen> createState() => _CompanionsScreenState();
}

class _CompanionsScreenState extends State<CompanionsScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ПОМОЩНИКИ'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _card(
            color: PO.border,
            child: ListTile(
              title: Text('Без помощника', style: pixText()),
              trailing: p.activeCompanion.isEmpty ? Text('ON', style: pixText(color: PO.gold)) : null,
              onTap: () async {
                p.activeCompanion = '';
                await p.save();
                setState(() {});
              },
            ),
          ),
          ...companions.map((c) {
            final owned = p.scrap >= 0; // always allow buy with coins
            final active = p.activeCompanion == c.id;
            return _card(
              color: Color(c.color),
              child: ListTile(
                title: Text(c.name, style: pixText(weight: FontWeight.w700)),
                subtitle: Text('${c.desc} · ${c.cost} C', style: pixText(size: 11, color: PO.muted)),
                trailing: TextButton(
                  onPressed: () async {
                    if (active) {
                      p.activeCompanion = '';
                    } else {
                      final bought = p.notifications.any((n) => n.contains('Куплен ${c.id}'));
                      if (!bought) {
                        if (p.coins < c.cost) return;
                        p.coins -= c.cost;
                        p.pushNote('Куплен ${c.id}');
                      }
                      p.activeCompanion = c.id;
                    }
                    await p.save();
                    setState(() {});
                  },
                  child: Text(active ? 'ON' : 'SET', style: pixText(color: PO.gold)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class NotesScreen extends StatelessWidget {
  final PlayerProgress progress;
  const NotesScreen({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    final notes = progress.notifications;
    return Scaffold(
      appBar: _bar(context, 'УВЕДОМЛЕНИЯ'),
      body: notes.isEmpty
          ? Center(child: Text('Пока пусто', style: pixText(color: PO.muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (_, i) => _card(
                color: PO.accent,
                child: ListTile(title: Text(notes[i], style: pixText(size: 13))),
              ),
            ),
    );
  }
}

class FriendsScreen extends StatefulWidget {
  final PlayerProgress progress;
  const FriendsScreen({super.key, required this.progress});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final ctrl = TextEditingController();
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ДРУЗЬЯ'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: ctrl, style: pixText(), decoration: InputDecoration(hintText: 'Имя', hintStyle: pixText(color: PO.muted)))),
            TextButton(
              onPressed: () async {
                p.addFriend(ctrl.text);
                ctrl.clear();
                await p.save();
                setState(() {});
              },
              child: Text('ADD', style: pixText(color: PO.gold)),
            ),
          ]),
          const SizedBox(height: 8),
          ...p.friends.map((f) => _card(
                color: PO.accent,
                child: ListTile(
                  title: Text(f, style: pixText()),
                  trailing: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: 'arena'))),
                    child: Text('ДУЭЛЬ', style: pixText(size: 11, color: PO.gold)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
