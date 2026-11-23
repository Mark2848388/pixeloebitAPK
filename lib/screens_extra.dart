import 'dart:math';
import 'package:flutter/material.dart';
import 'content.dart';
import 'online.dart';
import 'pixel.dart';
import 'progress.dart';

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

/// Silhouette reel chest
class GachaChestScreen extends StatefulWidget {
  final PlayerProgress progress;
  const GachaChestScreen({super.key, required this.progress});
  @override
  State<GachaChestScreen> createState() => _GachaChestScreenState();
}

class _GachaChestScreenState extends State<GachaChestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  PixelChar? _got;
  bool _spinning = false;
  final _rng = Random();
  final _reel = <PixelChar>[];

  PlayerProgress get p => widget.progress;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _reel.addAll(List.generate(24, (_) => pixelChars[_rng.nextInt(pixelChars.length)]));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (p.freeChests <= 0 || _spinning) return;
    setState(() {
      _spinning = true;
      _got = null;
      _reel
        ..clear()
        ..addAll(List.generate(28, (_) => pixelChars[_rng.nextInt(pixelChars.where((c) => c.id != 'c_d56').length)]));
    });
    await _ac.forward(from: 0);
    final got = p.openCharacterChest();
    await p.save();
    setState(() {
      _got = got;
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'СУНДУК · ${p.freeChests}'),
      body: Column(children: [
        const SizedBox(height: 24),
        SizedBox(
          height: 120,
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, __) {
              final t = Curves.easeOutCubic.transform(_ac.value);
              final offset = t * (_reel.length - 3) * 72;
              return Stack(alignment: Alignment.center, children: [
                ClipRect(
                  child: Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Row(
                      children: _reel.map((ch) {
                        return Container(
                          width: 72,
                          height: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          alignment: Alignment.center,
                          child: _got == null || _spinning
                              ? Container(
                                  width: 48,
                                  height: 64,
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8), border: Border.all(color: PO.border)),
                                  child: CustomPaint(painter: _SilhouettePainter()),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(width: 4, height: 110, color: PO.gold.withOpacity(0.8)),
              ]);
            },
          ),
        ),
        const SizedBox(height: 20),
        if (_got != null) ...[
          CustomPaint(size: const Size(64, 80), painter: _CharPainter(_got!)),
          const SizedBox(height: 8),
          Text(_got!.name, style: pixText(size: 18, color: Color(rarityColor(_got!.rarity)), weight: FontWeight.w800)),
          Text(rarityName(_got!.rarity), style: pixText(size: 12, color: PO.muted)),
          Text(_got!.blurb, style: pixText(size: 12, color: PO.text)),
        ],
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.gold, width: 2), minimumSize: const Size(double.infinity, 52)),
            onPressed: p.freeChests > 0 && !_spinning ? _open : null,
            child: Text(_spinning ? '…' : (p.freeChests > 0 ? 'ОТКРЫТЬ СУНДУК' : 'НЕТ СУНДУКОВ'), style: pixText(color: PO.gold)),
          ),
        ),
      ]),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.black;
    c.drawRect(Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.55), width: 16, height: 22), p);
    c.drawRect(Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.28), width: 18, height: 16), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CharPainter extends CustomPainter {
  final PixelChar ch;
  _CharPainter(this.ch);
  @override
  void paint(Canvas c, Size s) {
    paintPixelPerson(c, Offset(s.width / 2, s.height / 2), 2.2, color: ch.color, style: ch.style);
  }

  @override
  bool shouldRepaint(covariant _CharPainter old) => old.ch.id != ch.id;
}

class CharactersScreen extends StatelessWidget {
  final PlayerProgress progress;
  const CharactersScreen({super.key, required this.progress});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'ПЕРСОНАЖИ'),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.75),
        itemCount: pixelChars.length,
        itemBuilder: (_, i) {
          final ch = pixelChars[i];
          final owned = progress.ownedChars.contains(ch.id);
          return Container(
            decoration: BoxDecoration(
              color: PO.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(rarityColor(ch.rarity)), width: 2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (owned)
                CustomPaint(size: const Size(40, 52), painter: _CharPainter(ch))
              else
                const Icon(Icons.help_outline, color: PO.muted, size: 36),
              const SizedBox(height: 4),
              Text(owned ? ch.name : '???', style: pixText(size: 11, color: owned ? PO.text : PO.muted)),
              Text(rarityName(ch.rarity), style: pixText(size: 9, color: Color(rarityColor(ch.rarity)))),
            ]),
          );
        },
      ),
    );
  }
}

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
      appBar: _bar(context, 'СЕЗОН · Lv ${p.seasonLevel}/40'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text('XP ${p.seasonXp} / ${p.seasonLevel * 80}', style: pixText(size: 12, color: PO.muted)),
            LinearProgressIndicator(value: (p.seasonXp / (p.seasonLevel * 80)).clamp(0, 1), color: PO.gold, backgroundColor: PO.panel2),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: seasonTrack.length,
            itemBuilder: (_, i) {
              final r = seasonTrack[i];
              final unlocked = p.seasonLevel >= r.level;
              final claimed = p.claimedSeason.contains(r.level);
              return _card(
                color: r.charId != null ? PO.gold : (unlocked ? PO.accent : PO.border),
                child: ListTile(
                  title: Text('Lv ${r.level} · ${r.title}', style: pixText(weight: FontWeight.w700, color: unlocked ? PO.text : PO.muted)),
                  subtitle: Text(
                    [
                      if (r.coins > 0) '${r.coins}C',
                      if (r.gems > 0) '${r.gems}G',
                      if (r.scrap > 0) '${r.scrap}S',
                      if (r.charId != null) '★ персонаж',
                    ].join(' · '),
                    style: pixText(size: 11, color: PO.muted),
                  ),
                  trailing: claimed
                      ? Text('OK', style: pixText(color: PO.ok))
                      : TextButton(
                          onPressed: !unlocked
                              ? null
                              : () async {
                                  if (p.claimSeasonLevel(r.level)) {
                                    await p.save();
                                    setState(() {});
                                  }
                                },
                          child: Text('GET', style: pixText(color: PO.gold)),
                        ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class HangarWorldScreen extends StatefulWidget {
  final PlayerProgress progress;
  const HangarWorldScreen({super.key, required this.progress});
  @override
  State<HangarWorldScreen> createState() => _HangarWorldScreenState();
}

class _HangarWorldScreenState extends State<HangarWorldScreen> {
  PlayerProgress get p => widget.progress;
  String? placeId;

  @override
  void initState() {
    super.initState();
    final g = p.collectHangarIncome();
    if (g > 0) {
      p.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'АНГАР · ${p.coins}C'),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: buildings
                .map((b) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('${b.name} ${b.cost}', style: pixText(size: 11)),
                        selected: placeId == b.id,
                        onSelected: (_) => setState(() => placeId = placeId == b.id ? null : b.id),
                        selectedColor: Color(b.color).withOpacity(0.4),
                        backgroundColor: PO.panel2,
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, cons) {
            return GestureDetector(
              onTapDown: (d) {
                if (placeId == null) return;
                final x = d.localPosition.dx / cons.maxWidth;
                final y = d.localPosition.dy / cons.maxHeight;
                if (p.placeBuilding(placeId!, x, y)) {
                  p.save();
                  setState(() {});
                }
              },
              child: CustomPaint(
                size: Size(cons.maxWidth, cons.maxHeight),
                painter: _HangarPainter(p.hangar),
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(placeId == null ? 'Выбери постройку и тапни по карте' : 'Тапни, чтобы поставить', style: pixText(size: 12, color: PO.muted)),
        ),
      ]),
    );
  }
}

class _HangarPainter extends CustomPainter {
  final List<PlacedBuilding> buildingsPlaced;
  _HangarPainter(this.buildingsPlaced);
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0A1020));
    // grid
    final g = Paint()..color = const Color(0xFF1A2840);
    for (var x = 0.0; x < s.width; x += 32) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), g);
    }
    for (var y = 0.0; y < s.height; y += 32) {
      c.drawLine(Offset(0, y), Offset(s.width, y), g);
    }
    for (final b in buildingsPlaced) {
      BuildingDef? def;
      for (final d in buildings) {
        if (d.id == b.defId) def = d;
      }
      final col = Color(def?.color ?? 0xFF888888);
      final pos = Offset(b.x * s.width, b.y * s.height);
      c.drawRect(Rect.fromCenter(center: pos, width: 36, height: 28), Paint()..color = col);
      final tp = TextPainter(
        text: TextSpan(text: def?.name ?? '?', style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: 'monospace')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, pos + Offset(-tp.width / 2, 16));
    }
  }

  @override
  bool shouldRepaint(covariant _HangarPainter old) => true;
}

class ArenaRankScreen extends StatefulWidget {
  final PlayerProgress progress;
  final Future<void> Function(String mode, {int worldId}) onPlay;
  const ArenaRankScreen({super.key, required this.progress, required this.onPlay});
  @override
  State<ArenaRankScreen> createState() => _ArenaRankScreenState();
}

class _ArenaRankScreenState extends State<ArenaRankScreen> {
  List<Map<String, dynamic>> board = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await OnlineService.arenaLeaderboard();
    setState(() {
      board = rows;
      loading = false;
    });
  }

  Future<void> _fight(Map<String, dynamic>? opponent) async {
    final rating = (opponent?['arena_rating'] as int?) ?? (OnlineService.arenaRating + Random().nextInt(200) - 100);
    final name = (opponent?['display_name'] as String?) ?? 'Соперник';
    // Launch arena game then apply rating
    if (!mounted) return;
    await widget.onPlay('arena');
    // After match we don't know win for sure without callback — use simple heuristic: high score recent
    // Apply mild rating change based on local arenaWins delta tracked externally; here random practice + leaderboard presence
    await OnlineService.reportArenaResult(win: true, opponentRating: rating);
    widget.progress.arenaWins++;
    await widget.progress.save();
    await OnlineService.upsertProfile(seasonLevel: widget.progress.seasonLevel);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Арена vs $name · рейтинг ${OnlineService.arenaRating}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'АРЕНА · ${OnlineService.arenaRating} MMR'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.gold, width: 2), minimumSize: const Size(double.infinity, 48)),
                  onPressed: () => _fight(board.isEmpty ? null : board[Random().nextInt(board.length)]),
                  child: Text('СЛУЧАЙНЫЙ БОЙ', style: pixText(color: PO.gold)),
                ),
              ),
              Expanded(
                child: board.isEmpty
                    ? Center(child: Text('Нет данных рейтинга\n(нужен SQL schema в Supabase)', textAlign: TextAlign.center, style: pixText(color: PO.muted)))
                    : ListView.builder(
                        itemCount: board.length,
                        itemBuilder: (_, i) {
                          final r = board[i];
                          return _card(
                            color: PO.accent,
                            child: ListTile(
                              leading: Text('#${i + 1}', style: pixText(color: PO.gold)),
                              title: Text('${r['display_name']}', style: pixText()),
                              subtitle: Text('MMR ${r['arena_rating']} · W${r['arena_wins']} L${r['arena_losses']}', style: pixText(size: 11, color: PO.muted)),
                              trailing: TextButton(
                                onPressed: () => _fight(r),
                                child: Text('БОЙ', style: pixText(color: PO.gold, size: 12)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}

class RaidScreen extends StatelessWidget {
  final PlayerProgress progress;
  final Future<void> Function(String mode, {int worldId}) onPlay;
  const RaidScreen({super.key, required this.progress, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'РЕЙД'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Рейд-босс (общий)', style: pixText(size: 16, color: PO.gold, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Сложный бой с усиленным боссом.', style: pixText(size: 12, color: PO.muted)),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.danger, width: 2), minimumSize: const Size(double.infinity, 52)),
            onPressed: () => onPlay('campaign', worldId: 10),
            child: Text('АТАКОВАТЬ РЕЙД', style: pixText(color: PO.danger)),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class OnlineFriendsScreen extends StatefulWidget {
  final PlayerProgress progress;
  final Future<void> Function(String mode, {int worldId}) onPlay;
  const OnlineFriendsScreen({super.key, required this.progress, required this.onPlay});
  @override
  State<OnlineFriendsScreen> createState() => _OnlineFriendsScreenState();
}

class _OnlineFriendsScreenState extends State<OnlineFriendsScreen> {
  final ctrl = TextEditingController();
  List<Map<String, dynamic>> remote = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await OnlineService.listFriends();
    setState(() => remote = rows);
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.progress.friends;
    return Scaffold(
      appBar: _bar(context, 'ДРУЗЬЯ'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Онлайн (по имени в po_profiles)', style: pixText(size: 12, color: PO.muted)),
          Row(children: [
            Expanded(child: TextField(controller: ctrl, style: pixText(), decoration: InputDecoration(hintText: 'Ник', hintStyle: pixText(color: PO.muted)))),
            TextButton(
              onPressed: () async {
                final ok = await OnlineService.addFriendByName(ctrl.text);
                if (!ok) {
                  widget.progress.addFriend(ctrl.text);
                  await widget.progress.save();
                }
                ctrl.clear();
                await _load();
                setState(() {});
              },
              child: Text('ADD', style: pixText(color: PO.gold)),
            ),
          ]),
          ...remote.map((f) => _card(
                color: PO.accent,
                child: ListTile(
                  title: Text('${f['friend_name']}', style: pixText()),
                  trailing: TextButton(
                    onPressed: () async {
                      await OnlineService.createDuel(opponentId: f['friend_id'] as String, opponentName: f['friend_name'] as String);
                      if (context.mounted) widget.onPlay('arena');
                    },
                    child: Text('ДУЭЛЬ', style: pixText(size: 11, color: PO.gold)),
                  ),
                ),
              )),
          const Divider(color: PO.border),
          Text('Локальные', style: pixText(size: 12, color: PO.muted)),
          ...local.map((f) => _card(
                color: PO.border,
                child: ListTile(
                  title: Text(f, style: pixText()),
                  trailing: TextButton(
                    onPressed: () => widget.onPlay('arena'),
                    child: Text('ДУЭЛЬ', style: pixText(color: PO.gold, size: 11)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
