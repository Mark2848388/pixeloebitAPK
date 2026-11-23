import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content.dart';
import 'game.dart';
import 'online.dart';
import 'pixel.dart';
import 'progress.dart';
import 'sound.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await OnlineService.init();
  } catch (_) {}
  final progress = await PlayerProgress.load();
  await OrbitMusic.init();
  runApp(PixelOrbitApp(progress: progress));
}

class OrbitMusic {
  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;
  static double volume = 0.22;
  static bool sfxEnabled = true;
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('po_music') ?? true;
    sfxEnabled = prefs.getBool('po_sfx') ?? true;
    SfxAudio.enabled = sfxEnabled;
    volume = prefs.getDouble('po_music_volume') ?? 0.22;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(volume);
      if (enabled) await _player.play(AssetSource('music/orbit_loop.wav'));
    } catch (e) { debugPrint('Music init: $e'); }
  }
  static Future<void> toggleMusic() async {
    enabled = !enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('po_music', enabled);
    try { if (enabled) { await _player.setVolume(volume); await _player.play(AssetSource('music/orbit_loop.wav')); } else { await _player.stop(); } } catch (_) {}
  }
  static Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('po_music_volume', volume);
    try { await _player.setVolume(volume); } catch (_) {}
  }
  static Future<void> toggleSfx() async {
    sfxEnabled = !sfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('po_sfx', sfxEnabled);
    SfxAudio.enabled = sfxEnabled;
  }
}


IconData _pilotAvatarIcon(String code) {
  switch (code) {
    case 'a1': return Icons.rocket_launch;
    case 'a2': return Icons.shield;
    case 'a3': return Icons.star;
    case 'a4': return Icons.bolt;
    case 'a5': return Icons.public;
    default: return Icons.person;
  }
}
const _pilotAvatarCodes = ['a0', 'a1', 'a2', 'a3', 'a4', 'a5'];


class PixelOrbitApp extends StatelessWidget {
  final PlayerProgress progress;
  const PixelOrbitApp({super.key, required this.progress});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pixel Orbit', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: PO.bg, useMaterial3: true),
    home: MainMenu(progress: progress),
  );
}


class MainMenu extends StatefulWidget {
  final PlayerProgress progress;
  const MainMenu({super.key, required this.progress});
  @override
  State<MainMenu> createState() => _MainMenuState();
}


class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;
  PlayerProgress get p => widget.progress;
  static const _seasonEnd = DateTime(2026, 12, 1);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _time = d.inMilliseconds / 1000))..start();
  }
  @override
  void dispose() { _ticker.dispose(); super.dispose(); }

  void _play(String mode, {int worldId = 0}) => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: p, mode: mode, worldId: worldId))).then((_) { if (mounted) setState(() {}); });
  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) { if (mounted) setState(() {}); });


  String _seasonRemaining() {
    final d = _seasonEnd.difference(DateTime.now());
    if (d.isNegative) return 'СЕЗОН ЗАВЕРШЁН';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    return '$days д  ${hours.toString().padLeft(2, '0')} ч  ${minutes.toString().padLeft(2, '0')} мин';
  }

  Widget _planet({required String title, required String subtitle, required String mode, required IconData icon, required Color color, required int worldId}) {
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => mode == 'campaign'
          ? _open(CampaignScreen(progress: p))
          : mode == 'season'
              ? _open(const SeasonPassScreen())
              : mode == 'raid'
                  ? _open(const RaidScreen())
                  : _play(mode, worldId: worldId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: PO.panel,
          border: Border.all(color: color.withOpacity(.75), width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withOpacity(.95), color.withOpacity(.22), PO.bg]),
              border: Border.all(color: color, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(.22), blurRadius: 12)],
            ),
            child: Icon(icon, color: Colors.white, size: 29),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: pixText(size: 11, color: PO.text, weight: FontWeight.w700)),
          Text(subtitle, textAlign: TextAlign.center, style: pixText(size: 9, color: PO.muted)),
        ]),
      ),
    ));
  }


  Widget _quickButton(String title, IconData icon, Color tint, VoidCallback onTap) {
    return Expanded(child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: PO.panel2, borderRadius: BorderRadius.circular(13), border: Border.all(color: PO.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: 5),
          Text(title, style: pixText(size: 10, color: PO.text)),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(backgroundColor: PO.bg, body: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _StarPainter(_time))),
      SafeArea(child: ListView(padding: EdgeInsets.fromLTRB(14, 10, 14, 14 + bottom), children: [
        Row(children: [
          Expanded(child: InkWell(onTap: () => _open(ProfileScreen(progress: p)), borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: PO.panel.withOpacity(.95), border: Border.all(color: PO.accent), borderRadius: BorderRadius.circular(16)), child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: PO.panel2, border: Border.all(color: PO.gold, width: 2), borderRadius: BorderRadius.circular(12)), child: Icon(_pilotAvatarIcon(OnlineService.avatarCode), color: PO.gold, size: 28)),
            const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: pixText(size: 14, color: PO.text, weight: FontWeight.bold)), Text('Космический пилот · LV.${p.seasonLevel}', style: pixText(size: 10, color: PO.muted)), Text(OnlineService.pilotCode.isNotEmpty ? OnlineService.pilotCode : 'Профиль · нажми чтобы открыть', style: pixText(size: 9, color: PO.accent))]))
          ])))),
          const SizedBox(width: 8),
          Material(color: PO.panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: PO.border)), child: IconButton(onPressed: () => _open(const SettingsScreen()), icon: const Icon(Icons.settings, color: PO.gold), tooltip: 'Настройки')),
        ]),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: PO.panel2, borderRadius: BorderRadius.circular(13), border: Border.all(color: PO.border)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _resource('C', p.coins, PO.gold), _resource('G', p.gems, const Color(0xFF63D5FF)), _resource('S', p.scrap, const Color(0xFF85E5A6)),
        ])),
        const SizedBox(height: 10),
        InkWell(onTap: () => _open(const SeasonPassScreen()), borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF2B214C), PO.panel2]), border: Border.all(color: PO.gold, width: 1.5), borderRadius: BorderRadius.circular(17)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SEASON 01 · ORBITAL RIFT', style: pixText(size: 12, color: PO.gold, weight: FontWeight.bold)), const Icon(Icons.arrow_forward_ios, size: 14, color: PO.gold)]),
          const SizedBox(height: 5), Text(_seasonRemaining(), style: pixText(size: 13, color: PO.text, weight: FontWeight.w700)),
          const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: ((p.seasonXp % 1000) / 1000).clamp(0.0, 1.0).toDouble(), minHeight: 8, backgroundColor: PO.border, color: PO.gold)),
          const SizedBox(height: 4), Text('УРОВЕНЬ ${p.seasonLevel} · ${p.seasonXp % 1000} / 1000 XP', style: pixText(size: 9, color: PO.muted)),
        ]))),
        const SizedBox(height: 16),
        Center(child: Text('ГАЛАКТИКА · ВЫБЕРИ РЕЖИМ', style: pixText(size: 13, color: PO.accent, weight: FontWeight.bold))),
        const SizedBox(height: 10),
        Row(children: [ _planet(title: 'КАМПАНИЯ', subtitle: '10 миров', mode: 'campaign', icon: Icons.public, color: const Color(0xFF59A5FF), worldId: 0), const SizedBox(width: 8), _planet(title: 'ENDLESS', subtitle: 'без конца', mode: 'endless', icon: Icons.all_inclusive, color: const Color(0xFFFF795D), worldId: 0), const SizedBox(width: 8), _planet(title: 'АРЕНА', subtitle: 'AI · практика', mode: 'arena', icon: Icons.sports_martial_arts, color: PO.gold, worldId: 0) ]),
        const SizedBox(height: 10),
        Row(children: [ _planet(title: 'КЛАССИКА', subtitle: 'волны', mode: 'classic', icon: Icons.rocket_launch, color: const Color(0xFF5C83FF), worldId: 0), const SizedBox(width: 8), _planet(title: 'РЕЙД', subtitle: 'общий босс · онлайн', mode: 'raid', icon: Icons.groups, color: const Color(0xFF8F72FF), worldId: 0), const SizedBox(width: 8), _planet(title: 'СЕЗОН', subtitle: 'награды', mode: 'season', icon: Icons.military_tech, color: const Color(0xFFFFD45E), worldId: 0) ]),
        const SizedBox(height: 16),
        Text('КОМАНДА И ПИЛОТ', style: pixText(size: 11, color: PO.muted, weight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [ _quickButton('Друзья', Icons.people_alt, PO.accent, () => _open(FriendsScreen(progress: p))), const SizedBox(width: 8), _quickButton('Рейтинг', Icons.emoji_events, PO.gold, () => _open(const LeaderboardScreen())), const SizedBox(width: 8), _quickButton('Ангар', Icons.build, const Color(0xFF91A5FF), () => _open(HangarScreen(progress: p))), const SizedBox(width: 8), _quickButton('Журнал', Icons.notifications, const Color(0xFFFF8FD3), () => _open(NotesScreen(progress: p))) ]),
        const SizedBox(height: 8),
        Row(children: [ _quickButton('Кланы', Icons.shield, const Color(0xFF84D8B0), () => _open(ClanInfoScreen())), const SizedBox(width: 8), _quickButton('Профиль', Icons.account_circle, PO.gold, () => _open(ProfileScreen(progress: p))), const SizedBox(width: 8), _quickButton('Сундуки', Icons.card_giftcard, const Color(0xFFFFBE59), () => _open(ChestScreen(progress: p))) ]),
        const SizedBox(height: 14),
        Center(child: Text(OnlineService.authenticated ? '● SUPABASE · ONLINE' : OnlineService.ready ? '◐ SUPABASE · AUTH NEEDED' : '○ OFFLINE · LOCAL', style: pixText(size: 9, color: OnlineService.authenticated ? const Color(0xFF75E3A5) : PO.muted))),
      ])), 
    ]));
  }

  Widget _resource(String label, int value, Color color) => Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: pixText(size: 10, color: color, weight: FontWeight.bold)), Text(value.toString(), style: pixText(size: 13, color: PO.text))]);
}


class _StarPainter extends CustomPainter {
  final double t; _StarPainter(this.t);
  @override void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = PO.bg);
    for (int i = 0; i < 80; i++) {
      final x = (i * 67.7 + t * (3 + i % 5)) % s.width;
      final y = (i * 97.3 + t * (2 + i % 3)) % s.height;
      c.drawRect(Rect.fromLTWH(x, y, i % 8 == 0 ? 2.2 : 1.2, i % 8 == 0 ? 2.2 : 1.2), Paint()..color = i % 8 == 0 ? PO.accent.withOpacity(.65) : PO.muted.withOpacity(.28));
    }
  }
  @override bool shouldRepaint(covariant _StarPainter old) => old.t != t;
}


class SettingsScreen extends StatefulWidget { const SettingsScreen({super.key}); @override State<SettingsScreen> createState() => _SettingsScreenState(); }
class _SettingsScreenState extends State<SettingsScreen> {
  @override Widget build(BuildContext context) => Scaffold(appBar: _bar(context, 'НАСТРОЙКИ'), body: ListView(padding: const EdgeInsets.all(16), children: [
    SwitchListTile(title: Text('Музыка', style: pixText()), subtitle: Text('Оригинальный фоновый трек', style: pixText(size: 10, color: PO.muted)), value: OrbitMusic.enabled, activeColor: PO.gold, onChanged: (_) async { await OrbitMusic.toggleMusic(); if (mounted) setState(() {}); }),
    Text('ГРОМКОСТЬ', style: pixText(size: 11, color: PO.muted)), Slider(value: OrbitMusic.volume, onChanged: (v) { setState(() { OrbitMusic.setVolume(v); }); }, min: 0, max: 1, activeColor: PO.gold),
    SwitchListTile(title: Text('Звуковые эффекты', style: pixText()), subtitle: Text('Включает лазер и звуки уничтожения врагов', style: pixText(size: 10, color: PO.muted)), value: OrbitMusic.sfxEnabled, activeColor: PO.accent, onChanged: (_) async { await OrbitMusic.toggleSfx(); if (mounted) setState(() {}); }),
    const Divider(), ListTile(leading: const Icon(Icons.cloud_done, color: PO.accent), title: Text('Supabase', style: pixText()), subtitle: Text(OnlineService.authenticated ? 'Гостевая сессия активна · облачные сохранения' : 'Онлайн-профиль недоступен; локальный прогресс работает', style: pixText(size: 10, color: PO.muted))),
    ListTile(leading: const Icon(Icons.notifications_active, color: PO.accent), title: Text('Серверные события + журнал', style: pixText()), subtitle: Text('Push-уведомления Android / FCM пока не подключены', style: pixText(size: 10, color: PO.muted))),
    ListTile(leading: const Icon(Icons.info_outline, color: PO.gold), title: Text('Pixel Orbit v2.2', style: pixText()), subtitle: Text('Сезон 01 · до 01.12.2026', style: pixText(size: 10, color: PO.muted))),
  ]));
}


class SeasonPassScreen extends StatelessWidget { const SeasonPassScreen({super.key});
  @override Widget build(BuildContext context) { final end = DateTime(2026, 12, 1).difference(DateTime.now()); final rem = end.isNegative ? 'СЕЗОН ЗАВЕРШЁН' : '${end.inDays} дней · ${end.inHours % 24} часов'; return Scaffold(appBar: _bar(context, 'SEASON PASS'), body: ListView(padding: const EdgeInsets.all(14), children: [
    _card(color: PO.gold, child: ListTile(title: Text('SEASON 01 · ORBITAL RIFT', style: pixText(color: PO.gold, weight: FontWeight.bold)), subtitle: Text('Окончание: 1 декабря 2026\n$rem', style: pixText(size: 11, color: PO.muted)))),
    _card(color: PO.accent, child: ListTile(title: Text('Сезонный прогресс', style: pixText()), subtitle: Text('XP начисляется за игровые результаты. Награды pass пока отображаются как превью.', style: pixText(size: 10, color: PO.muted)))),
    ...List.generate(12, (i) => _card(color: i % 3 == 0 ? PO.gold : PO.accent, child: ListTile(leading: Icon(i % 3 == 0 ? Icons.card_giftcard : Icons.star, color: i % 3 == 0 ? PO.gold : PO.accent), title: Text('УРОВЕНЬ ${i + 1}', style: pixText()), subtitle: Text(i % 3 == 0 ? 'Награда: сундук · монеты' : 'Награда: сезонный XP', style: pixText(size: 10, color: PO.muted)), trailing: Text('PREVIEW', style: pixText(size: 9, color: PO.muted))))),
  ])); }
}



class LeaderboardScreen extends StatefulWidget { const LeaderboardScreen({super.key}); @override State<LeaderboardScreen> createState() => _LeaderboardScreenState(); }
class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String mode = 'classic'; Future<List<Map<String, dynamic>>>? scores;
  @override void initState() { super.initState(); scores = OnlineService.topScores(mode: mode); }
  void refresh() => setState(() => scores = OnlineService.topScores(mode: mode));
  @override Widget build(BuildContext context) => Scaffold(
    appBar: _bar(context, 'РЕЙТИНГ'),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'classic', label: Text('CLASSIC')),
          ButtonSegment(value: 'endless', label: Text('ENDLESS')),
          ButtonSegment(value: 'campaign', label: Text('CAMPAIGN')),
          ButtonSegment(value: 'arena', label: Text('ARENA')),
        ],
        selected: {mode},
        onSelectionChanged: (s) { mode = s.first; refresh(); },
      )),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: scores,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final rows = snap.data ?? [];
          if (rows.isEmpty) return Center(child: Text('Пока нет рекордов / офлайн', style: pixText(color: PO.muted)));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return _card(color: i == 0 ? PO.gold : PO.accent, child: ListTile(
              leading: Text('#${i + 1}', style: pixText(color: i == 0 ? PO.gold : PO.muted)),
              title: Text(r['display_name']?.toString() ?? 'Pilot', style: pixText()),
              subtitle: Text('Волна ${r['wave'] ?? 0}', style: pixText(size: 10, color: PO.muted)),
              trailing: Text('${r['score'] ?? 0}', style: pixText(color: PO.gold, weight: FontWeight.bold)),
            ));
          });
        },
      )),
    ]),
  );
}


class RaidScreen extends StatefulWidget { const RaidScreen({super.key}); @override State<RaidScreen> createState() => _RaidScreenState(); }
class _RaidScreenState extends State<RaidScreen> {
  Map<String, dynamic> state = {};
  List<Map<String, dynamic>> top = [];
  bool loading = true, attacking = false, joined = false;
  String message = '';
  Timer? timer;
  @override void initState() { super.initState(); _joinAndRefresh(); timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh()); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  Future<void> _joinAndRefresh() async {
    final c = OnlineService.client;
    if (c == null || OnlineService.authUserId == null) { if (mounted) setState(() { loading = false; message = 'Нужен гостевой вход в Supabase Auth.'; }); return; }
    try { await c.rpc('join_coop_raid'); joined = true; await _refresh(); }
    catch (e) { if (mounted) setState(() { loading = false; message = 'Не удалось подключиться к рейду. Проверь Supabase Auth.'; }); debugPrint('raid join: $e'); }
  }
  Future<void> _refresh() async {
    final c = OnlineService.client;
    if (c == null || OnlineService.authUserId == null) return;
    try {
      var row = await c.from('coop_raid_state').select('id,boss_name,hp,max_hp,phase,total_damage,updated_at,defeated_at').eq('id', 'global').maybeSingle();
      if (row == null) return;
      final defeatedAt = DateTime.tryParse(row['defeated_at']?.toString() ?? '');
      if (defeatedAt != null && DateTime.now().toUtc().difference(defeatedAt).inSeconds >= 30) {
        await c.rpc('join_coop_raid');
        row = await c.from('coop_raid_state').select('id,boss_name,hp,max_hp,phase,total_damage,updated_at,defeated_at').eq('id', 'global').maybeSingle();
        if (row == null) return;
      }
      final next = Map<String, dynamic>.from(row);
      final phase = (next['phase'] as num).toInt();
      final raw = await c.from('coop_raid_contributions').select('user_id,damage,attacks').eq('phase', phase).order('damage', ascending: false).limit(10);
      final contributions = List<Map<String, dynamic>>.from(raw);
      final ids = contributions.map((r) => r['user_id'].toString()).toList();
      final profiles = ids.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(await c.from('pilot_profiles').select('user_id,display_name,pilot_code').inFilter('user_id', ids));
      final profileById = {for (final profile in profiles) profile['user_id'].toString(): profile};
      final mapped = contributions.map((r) => {...r, 'profile': profileById[r['user_id'].toString()] ?? {}}).toList();
      if (mounted) setState(() { state = next; top = mapped; loading = false; });
    } catch (e) { if (mounted && state.isEmpty) setState(() { loading = false; message = 'Не удалось загрузить рейд.'; }); debugPrint('raid refresh: $e'); }
  }
  Future<void> _attack() async {
    final c = OnlineService.client;
    if (c == null || OnlineService.authUserId == null || attacking) return;
    setState(() { attacking = true; message = ''; });
    try {
      final response = await c.rpc('attack_coop_boss');
      final result = Map<String, dynamic>.from(response as Map);
      final damage = result['damage'] ?? 0;
      final tokens = result['raid_tokens'] ?? 0;
      if (mounted) setState(() { message = '+$damage УРОНА · ТВОИ РЕЙД-ТОКЕНЫ: $tokens'; });
      await _refresh();
    } catch (e) {
      final err = e.toString();
      if (mounted) setState(() { message = err.contains('attack_cooldown') ? 'Оружие перегревается — подожди секунду.' : 'Атака не прошла. Повтори позже.'; });
      debugPrint('raid attack: $e');
    }
    if (mounted) setState(() => attacking = false);
  }
  @override Widget build(BuildContext context) {
    final hp = (state['hp'] as num?)?.toDouble() ?? 0.0;
    final maxHp = (state['max_hp'] as num?)?.toDouble() ?? 1.0;
    final ratio = (hp / maxHp).clamp(0.0, 1.0).toDouble();
    final defeated = state['defeated_at'] != null;
    return Scaffold(appBar: _bar(context, 'CO-OP RAID'), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(12), children: [
      _card(color: PO.gold, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        Text(state['boss_name']?.toString() ?? 'НЕБУЛОН', style: pixText(size: 18, color: PO.gold, weight: FontWeight.bold)),
        Text('PHASE ${state['phase'] ?? 1}', style: pixText(size: 11, color: PO.accent)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: ratio, minHeight: 14, backgroundColor: PO.border, color: PO.danger),
        const SizedBox(height: 6),
        Text('${hp.toInt()} / ${maxHp.toInt()} HP', style: pixText(size: 12)),
        Text('ОБЩИЙ УРОН: ${state['total_damage'] ?? 0}', style: pixText(size: 10, color: PO.muted)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: attacking || defeated ? null : _attack, child: Text(defeated ? 'БОСС ПОБЕЖДЁН' : attacking ? 'АТАКА...' : 'АТАКОВАТЬ БОССА', style: pixText(size: 11, color: PO.bg)))),
      ]))),
      if (message.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(message, textAlign: TextAlign.center, style: pixText(size: 10, color: PO.accent))),
      Text('ЛУЧШИЕ УЧАСТНИКИ ФАЗЫ', style: pixText(size: 11, color: PO.gold, weight: FontWeight.bold)),
      if (top.isEmpty) Text('Пока никто не наносил урон этой фазе', style: pixText(size: 10, color: PO.muted))
      else ...top.asMap().entries.map((entry) {
        final profile = Map<String, dynamic>.from(entry.value['profile'] as Map? ?? {});
        final name = profile['display_name']?.toString() ?? 'Пилот';
        final dmg = entry.value['damage'] ?? 0;
        return _card(color: entry.key == 0 ? PO.gold : PO.accent, child: ListTile(
          leading: Text('#${entry.key + 1}', style: pixText(color: entry.key == 0 ? PO.gold : PO.muted)),
          title: Text(name, style: pixText(size: 11)),
          subtitle: Text('${profile['pilot_code'] ?? ''} · ${entry.value['attacks'] ?? 0} атак', style: pixText(size: 9, color: PO.muted)),
          trailing: Text('$dmg', style: pixText(color: PO.gold, weight: FontWeight.bold)),
        ));
      }),
      const SizedBox(height: 8), Text('Рейд использует серверные RPC с проверкой входа и кулдауном атаки. Состояние и вклад обновляются с сервера каждые 3 секунды.', style: pixText(size: 9, color: PO.muted)),
    ]));
  }
}


class ClanInfoScreen extends StatefulWidget { const ClanInfoScreen({super.key}); @override State<ClanInfoScreen> createState() => _ClanInfoScreenState(); }
class _ClanInfoScreenState extends State<ClanInfoScreen> {
  final nameCtrl = TextEditingController(); final codeCtrl = TextEditingController(); String? myCode; String? myRole; bool busy = false;
  @override void initState() { super.initState(); _loadClan(); }
  @override void dispose() { nameCtrl.dispose(); codeCtrl.dispose(); super.dispose(); }
  Future<void> _loadClan() async { final c = OnlineService.client; final uid = OnlineService.authUserId; if (c == null || uid == null) return; try { final rows = await c.from('clan_members').select('clan_code,role').eq('user_id', uid).limit(1); if (rows.isNotEmpty) { final code = rows.first['clan_code'].toString(); final clan = await c.from('clans').select('code,name').eq('code', code).maybeSingle(); if (mounted) setState(() { myCode = code; myRole = rows.first['role']?.toString(); }); } } catch (e) { debugPrint('clan fetch: $e'); } }
  void _msg(String m) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: pixText(size: 11)), backgroundColor: PO.panel)); }
  Future<void> _create() async { final c = OnlineService.client; final uid = OnlineService.authUserId; final n = nameCtrl.text.trim(); if (c == null || uid == null) { _msg('Для создания клана нужен вход на сервер.'); return; } if (n.length < 3 || n.length > 24) { _msg('Название: от 3 до 24 символов.'); return; } setState(() => busy = true); final code = DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 6); try { await c.from('clans').insert({'code': code, 'name': n, 'owner_id': uid}); await c.from('clan_members').insert({'clan_code': code, 'user_id': uid, 'role': 'leader'}); if (mounted) { _msg('Клан создан: $code'); nameCtrl.clear(); } await _loadClan(); } catch (e) { _msg('Не удалось создать клан. Возможно, вы уже состоите в клане.'); debugPrint('clan create: $e'); } if (mounted) setState(() => busy = false); }
  Future<void> _join() async { final c = OnlineService.client; final uid = OnlineService.authUserId; final code = codeCtrl.text.trim().toUpperCase(); if (c == null || uid == null) { _msg('Нужен вход на сервер.'); return; } if (code.isEmpty) return; setState(() => busy = true); try { final clan = await c.from('clans').select('code,name').eq('code', code).maybeSingle(); if (clan == null) { _msg('Клан по этому коду не найден.'); } else { await c.from('clan_members').insert({'clan_code': code, 'user_id': uid, 'role': 'member'}); if (mounted) { setState(() { myCode = code; myRole = 'member'; }); _msg('Ты вступил в ${clan['name'] ?? code}!'); } } } catch (e) { _msg('Не удалось вступить. Возможно, ты уже в клане.'); debugPrint('clan join: $e'); } if (mounted) setState(() => busy = false); }
  Future<void> _leave() async { final c = OnlineService.client; final uid = OnlineService.authUserId; if (c == null || uid == null || myCode == null) return; try { await c.from('clan_members').delete().eq('clan_code', myCode!).eq('user_id', uid); if (mounted) setState(() { myCode = null; myRole = null; }); _msg('Ты покинул клан.'); } catch (e) { _msg('Не удалось выйти из клана.'); debugPrint('clan leave: $e'); } }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: _bar(context, 'КЛАНЫ'),
    body: ListView(padding: const EdgeInsets.all(12), children: [
      if (myCode != null) ...[
        _card(color: PO.gold, child: ListTile(
          leading: const Icon(Icons.shield, color: PO.gold),
          title: Text('Клан $myCode', style: pixText(color: PO.gold, weight: FontWeight.bold)),
          subtitle: Text(myRole == 'leader' ? 'Лидер клана' : 'Участник', style: pixText(size: 10, color: PO.muted)),
          trailing: IconButton(icon: const Icon(Icons.exit_to_app, color: PO.accent), tooltip: 'Выйти', onPressed: _leave),
        )),
        _card(color: PO.accent, child: ListTile(
          leading: const Icon(Icons.forum, color: PO.accent),
          title: Text('Клановый чат', style: pixText()),
          subtitle: Text('Общий чат участников', style: pixText(size: 10, color: PO.muted)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClanChatScreen(code: myCode!))),
        )),
      ] else ...[
        if (!OnlineService.authenticated) _card(color: PO.border, child: ListTile(
          title: Text('Серверная сессия не активна', style: pixText()),
          subtitle: Text('Включи Anonymous Sign-in в Supabase Auth.', style: pixText(size: 10, color: PO.muted)),
        )),
        _card(color: PO.accent, child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Создать клан', style: pixText(color: PO.accent, weight: FontWeight.bold)),
            TextField(controller: nameCtrl, maxLength: 24, style: pixText(size: 12), decoration: const InputDecoration(hintText: 'Название клана')),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: busy ? null : _create, child: Text('CREATE CLAN', style: pixText(size: 10, color: PO.bg)))),
          ],
        ))),
        _card(color: PO.gold, child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Вступить по коду', style: pixText(color: PO.gold, weight: FontWeight.bold)),
            TextField(controller: codeCtrl, maxLength: 6, textCapitalization: TextCapitalization.characters, style: pixText(size: 12), decoration: const InputDecoration(hintText: 'CLAN CODE')),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: busy ? null : _join, child: Text('JOIN', style: pixText(size: 10, color: PO.gold)))),
          ],
        ))),
      ],
      ]), 
  );
}
class ClanChatScreen extends StatefulWidget {
  final String code;
  const ClanChatScreen({super.key, required this.code});
  @override State<ClanChatScreen> createState() => _ClanChatScreenState();
}
class _ClanChatScreenState extends State<ClanChatScreen> {
  final msgCtrl = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  Timer? refreshTimer;
  @override void initState() { super.initState(); _load(); refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load()); }
  @override void dispose() { refreshTimer?.cancel(); msgCtrl.dispose(); super.dispose(); }
  Future<void> _load() async {
    final c = OnlineService.client;
    if (c == null) return;
    try {
      final data = await c.from('clan_chat').select('display_name,message,user_id,created_at').eq('clan_code', widget.code).order('created_at').limit(100);
      if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('clan chat fetch: $e'); }
  }
  Future<void> _send() async {
    final c = OnlineService.client;
    final uid = OnlineService.authUserId;
    final m = msgCtrl.text.trim();
    if (c == null || uid == null || m.isEmpty) return;
    msgCtrl.clear();
    try {
      await c.from('clan_chat').insert({'clan_code': widget.code, 'user_id': uid, 'display_name': OnlineService.displayName, 'message': m});
      await _load();
    } catch (_) { msgCtrl.text = m; }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: _bar(context, 'CLAN CHAT'),
    body: Column(children: [
      Expanded(child: ListView.builder(
        itemCount: rows.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (_, i) => _card(color: PO.border, child: ListTile(
          title: Text(rows[i]['display_name']?.toString() ?? 'Pilot', style: pixText(size: 10, color: PO.accent)),
          subtitle: Text(rows[i]['message']?.toString() ?? '', style: pixText(size: 11)),
        )),
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: TextField(controller: msgCtrl, maxLength: 240, style: pixText(size: 11), decoration: const InputDecoration(hintText: 'Сообщение в клан...', counterText: ''))),
        IconButton(onPressed: _send, icon: const Icon(Icons.send, color: PO.accent)),
      ]))),
    ]),
  );
}



// ───── GAME ─────
class GameScreen extends StatefulWidget {
  final PlayerProgress progress;
  final String mode;
  final int worldId;
  const GameScreen({super.key, required this.progress, this.mode = 'classic', this.worldId = 0});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameWorld world;
  late Ticker ticker;
  Duration _last = Duration.zero;
  bool _saved = false;
  bool _paused = false;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    final h = widget.progress.hero;
    WorldInfo? wi;
    if (widget.mode == 'campaign' && widget.worldId > 0) {
      wi = worlds.firstWhere((w) => w.id == widget.worldId);
    }
    world = GameWorld(
      w: 360,
      h: 640,
      mode: widget.mode,
      worldId: widget.worldId,
      wavesGoal: wi?.wavesToClear ?? 0,
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
    );
    ticker = createTicker(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ticker.start();
    });
  }

  void _tick(Duration e) {
    if (_paused) return;
    try {
      var dt = _last == Duration.zero ? 1 / 60 : (e - _last).inMicroseconds / 1e6;
      _last = e;
      if (dt <= 0 || dt > 1) dt = 1 / 60;
      world.update(dt);
      if (world.gameOver && !_saved) {
        _saved = true;
        widget.progress.addScore(world.score, mode: widget.mode);
        if (world.victory && widget.mode == 'campaign') widget.progress.clearWorld(widget.worldId);
        if (world.victory && widget.mode == 'arena') widget.progress.arenaWins++;
        widget.progress.save();
        OnlineService.syncProfileLevel(widget.progress.seasonLevel);
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
    world.tx = (l.dx / box.size.width * world.w).clamp(24.0, world.w - 24.0).toDouble();
    world.ty = (l.dy / box.size.height * world.h).clamp(48.0, world.h - 48.0).toDouble();
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
            left: 10, top: 10 + pad.top,
            child: _btn(_paused ? 'ПРОДОЛЖИТЬ' : 'ПАУЗА', () { setState(() { _paused = !_paused; _last = Duration.zero; }); }),
          ),
          Positioned(
            right: 10,
            bottom: 16 + pad.bottom,
            child: Column(children: [
              _btn('УЛЬТА', () => world.tryUlt()),
              const SizedBox(height: 8),
              _btn('РЫВОК', () => world.tryDash()),
            ])),
          if (_paused) Positioned.fill(child: Container(color: PO.bg.withOpacity(.84), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('ПАУЗА', style: pixText(size: 24, color: PO.gold, weight: FontWeight.bold)),
            const SizedBox(height: 18),
            _btn('ПРОДОЛЖИТЬ', () { setState(() { _paused = false; _last = Duration.zero; }); }),
            const SizedBox(height: 10),
            _btn('ВЫЙТИ', () async { await OnlineService.flushCloudSave(); if (context.mounted) Navigator.pop(context); }),
          ])))),
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
          child: SizedBox(width: t.length > 6 ? 136 : 76, height: 42, child: Center(child: Text(t, style: pixText(size: 12, color: PO.gold)))),
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
      appBar: _bar(context, 'КАМПАНИЯ'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: worlds.length,
        itemBuilder: (_, i) {
          final w = worlds[i];
          final ok = progress.worldUnlocked(w.id);
          final done = progress.worldCleared(w.id);
          return _card(
            color: ok ? Color(w.color) : PO.border,
            child: ListTile(
              enabled: ok,
              title: Text(w.name, style: pixText(size: 14, color: ok ? PO.text : PO.muted, weight: FontWeight.w700)),
              subtitle: Text(ok ? '${w.blurb} · ${w.wavesToClear} волн' : 'Закрыто', style: pixText(size: 11, color: PO.muted)),
              trailing: Text(done ? 'CLEAR' : ok ? 'PLAY' : 'LOCK', style: pixText(size: 11, color: PO.gold)),
              onTap: !ok
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(progress: progress, mode: 'campaign', worldId: w.id))),
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

class ChestScreen extends StatefulWidget {
  final PlayerProgress progress;
  const ChestScreen({super.key, required this.progress});
  @override
  State<ChestScreen> createState() => _ChestScreenState();
}

class _ChestScreenState extends State<ChestScreen> {
  PlayerProgress get p => widget.progress;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'СУНДУКИ · ${p.freeChests} free'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p.freeChests > 0)
            _card(
              color: PO.gold,
              child: ListTile(
                title: Text('ТРОФЕЙНЫЙ', style: pixText(color: PO.gold, weight: FontWeight.w700)),
                trailing: TextButton(
                  onPressed: () async {
                    final r = p.openFreeChest();
                    if (r != null) {
                      await p.save();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('+${r['coins']}C +${r['scrap']}S', style: pixText(size: 12)),
                          backgroundColor: PO.panel,
                        ));
                      }
                    }
                  },
                  child: Text('OPEN', style: pixText(color: PO.gold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
  String _avatar = 'a0';
  @override
  void initState() {
    super.initState();
    _avatar = OnlineService.avatarCode;
    name = TextEditingController(text: widget.progress.playerName);
    bio = TextEditingController(text: widget.progress.bio);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    return Scaffold(
      appBar: _bar(context, 'ПРОФИЛЬ'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(color: PO.gold, child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: PO.panel2, border: Border.all(color: PO.gold, width: 2), borderRadius: BorderRadius.circular(14)), child: Icon(_pilotAvatarIcon(_avatar), size: 34, color: PO.gold)),
            const SizedBox(height: 10),
            Text('ВЫБЕРИ АВАТАР', style: pixText(size: 10, color: PO.muted, weight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _pilotAvatarCodes.map((code) {
                return InkWell(
                  onTap: () async { setState(() => _avatar = code); await OnlineService.setAvatar(code); },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: PO.panel2, border: Border.all(color: _avatar == code ? PO.gold : PO.border, width: _avatar == code ? 2 : 1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_pilotAvatarIcon(code), color: _avatar == code ? PO.gold : PO.muted, size: 22),
                  ),
                );
              }).toList(),
            ),
          ]))),
          Text('Имя пилота', style: pixText(size: 12, color: PO.muted)),
          TextField(controller: name, maxLength: 16, style: pixText(), decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Text('Био', style: pixText(size: 12, color: PO.muted)),
          TextField(controller: bio, maxLines: 3, maxLength: 80, style: pixText(), decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (OnlineService.pilotCode.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Expanded(child: Text('PILOT ID  ${OnlineService.pilotCode}', style: pixText(size: 12, color: PO.accent))), IconButton(icon: const Icon(Icons.copy, size: 18, color: PO.accent), onPressed: () { Clipboard.setData(ClipboardData(text: OnlineService.pilotCode)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID скопирован'))); })])),
          Text('Игр: ${p.gamesPlayed}  ·  Арена тренировок: ${p.arenaWins}  ·  Сезон ${p.seasonLevel}', style: pixText(size: 12, color: PO.muted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: PO.accent, width: 2)),
              onPressed: () async {
                p.playerName = name.text.trim().isEmpty ? p.playerName : name.text.trim();
                p.bio = bio.text.trim();
                try {
                  await OnlineService.setName(p.playerName);
                } catch (_) {}
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

class NotesScreen extends StatefulWidget {
  final PlayerProgress progress;
  const NotesScreen({super.key, required this.progress});
  @override State<NotesScreen> createState() => _NotesScreenState();
}
class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> events = [];
  bool loading = false;
  @override void initState() { super.initState(); _loadEvents(); }
  Future<void> _loadEvents() async { setState(() => loading = true); final data = await OnlineService.loadActiveEvents(); if (mounted) setState(() { events = data; loading = false; }); }
  @override Widget build(BuildContext context) {
    final notes = widget.progress.notifications;
    return Scaffold(appBar: _bar(context, 'УВЕДОМЛЕНИЯ'), body: RefreshIndicator(onRefresh: _loadEvents, child: ListView(padding: const EdgeInsets.all(12), children: [
      Text('СЕРВЕРНЫЕ СОБЫТИЯ', style: pixText(size: 11, color: PO.gold, weight: FontWeight.bold)),
      if (loading) const Padding(padding: EdgeInsets.all(10), child: Center(child: CircularProgressIndicator()))
      else if (events.isEmpty) Text('Нет активных серверных событий', style: pixText(size: 10, color: PO.muted))
      else ...events.map((e) => _card(color: PO.gold, child: ListTile(
        title: Text(e['title']?.toString() ?? 'Event', style: pixText(color: PO.gold)),
        subtitle: Text('${e['description'] ?? ''}\nНаграды: ${e['reward_coins'] ?? 0} C · ${e['reward_parts'] ?? 0} деталей', style: pixText(size: 10, color: PO.muted)),
      ))), 
      const SizedBox(height: 12), Text('ЛИЧНЫЙ ЖУРНАЛ', style: pixText(size: 11, color: PO.accent, weight: FontWeight.bold)),
      if (notes.isEmpty) Text('Локальных уведомлений пока нет', style: pixText(size: 10, color: PO.muted))
      else ...notes.map((n) => _card(color: PO.accent, child: ListTile(title: Text(n, style: pixText(size: 11))))),
    ])));
  }
}

class FriendsScreen extends StatefulWidget {
  final PlayerProgress progress;
  const FriendsScreen({super.key, required this.progress});
  @override State<FriendsScreen> createState() => _FriendsScreenState();
}
class _FriendsScreenState extends State<FriendsScreen> {
  final codeCtrl = TextEditingController();
  bool busy = false;
  List<Map<String, dynamic>> rows = [];
  PlayerProgress get p => widget.progress;
  @override void initState() { super.initState(); _reload(); }
  @override void dispose() { codeCtrl.dispose(); super.dispose(); }
  Future<void> _reload() async {
    if (mounted) setState(() => busy = true);
    final data = await OnlineService.loadFriendRows();
    if (mounted) setState(() { rows = data; busy = false; });
  }
  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: pixText(size: 11)), backgroundColor: PO.panel));
  }
  Widget _friendTile(Map<String, dynamic> r) {
    final other = Map<String, dynamic>.from(r['other'] as Map? ?? {});
    final display = other['display_name']?.toString() ?? 'Пилот';
    final code = other['pilot_code']?.toString() ?? '---';
    final incoming = r['status'] == 'pending' && r['outgoing'] != true;
    final outgoing = r['status'] == 'pending' && r['outgoing'] == true;
    final accepted = r['status'] == 'accepted';
    final requestId = (r['id'] as num).toInt();
    Widget? trailing;
    if (incoming) {
      trailing = Wrap(children: [
        IconButton(icon: const Icon(Icons.check, color: Colors.green), tooltip: 'Принять', onPressed: () async { final ok = await OnlineService.respondFriendRequest(requestId, true); _toast(ok ? 'Добавлен в друзья!' : 'Не получилось принять'); await _reload(); }),
        IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), tooltip: 'Отклонить', onPressed: () async { await OnlineService.respondFriendRequest(requestId, false); await _reload(); }),
      ]);
    } else if (outgoing) {
      trailing = const Icon(Icons.hourglass_bottom, color: PO.gold);
    } else if (accepted) {
      trailing = IconButton(icon: const Icon(Icons.chat, color: PO.accent), tooltip: 'Чат', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PilotChatScreen(userId: other['user_id'].toString(), displayName: display))));
    }
    return _card(color: accepted ? const Color(0xFF66DDAA) : PO.accent, child: ListTile(
      leading: const CircleAvatar(backgroundColor: PO.panel2, child: Icon(Icons.person, color: PO.accent)),
      title: Text(display, style: pixText(size: 12, color: PO.text, weight: FontWeight.bold)),
      subtitle: Text('$code · ${incoming ? 'Входящий запрос' : outgoing ? 'Ожидает ответа' : 'В друзьях'}', style: pixText(size: 10, color: PO.muted)),
      trailing: trailing,
      onLongPress: accepted ? () async { final ok = await OnlineService.removeFriend(requestId); _toast(ok ? 'Удалён из друзей' : 'Не удалось удалить'); await _reload(); } : null,
    ));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: _bar(context, 'ДРУЗЬЯ · ONLINE'),
    body: !OnlineService.authenticated
      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Вход на сервер недоступен. Проверь, включён ли Anonymous Sign-in в Supabase Auth. Пока работает локальный прогресс.', textAlign: TextAlign.center, style: pixText(color: PO.muted))))
      : RefreshIndicator(onRefresh: _reload, child: ListView(padding: const EdgeInsets.all(12), children: [
        _card(color: PO.accent, child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Добавить пилота', style: pixText(color: PO.accent, weight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Введи Pilot ID, например PO-1A2B3C4D', style: pixText(size: 10, color: PO.muted)),
            Row(children: [
              Expanded(child: TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters, maxLength: 11, style: pixText(size: 12), decoration: const InputDecoration(hintText: 'PO-XXXXXXXX', counterText: '', isDense: true))),
              const SizedBox(width: 6),
              ElevatedButton(onPressed: busy ? null : () async { final code = codeCtrl.text; codeCtrl.clear(); final msg = await OnlineService.sendFriendRequest(code); _toast(msg); await _reload(); }, child: Text('SEND', style: pixText(size: 10, color: PO.bg))),
            ]),
          ],
        ))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ЗАПРОСЫ И ДРУЗЬЯ', style: pixText(size: 11, color: PO.gold, weight: FontWeight.bold)), IconButton(onPressed: _reload, icon: const Icon(Icons.refresh, color: PO.accent))]),
        if (busy) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (rows.where((r) => r['status'] != 'declined').isEmpty) Text('Пока пусто. Добавь друга по Pilot ID.', style: pixText(size: 11, color: PO.muted))
        else ...rows.where((r) => r['status'] != 'declined').map(_friendTile),
        Padding(padding: const EdgeInsets.only(top: 4), child: Text('Удаление друга: удерживай карточку. Арена сейчас — тренировка против AI, не сетевое PvP.', style: pixText(size: 9, color: PO.muted))),
      ])),
  );
}


class PilotChatScreen extends StatefulWidget { final String userId, displayName; const PilotChatScreen({super.key, required this.userId, required this.displayName}); @override State<PilotChatScreen> createState() => _PilotChatScreenState(); }
class _PilotChatScreenState extends State<PilotChatScreen> {
  final textCtrl = TextEditingController(); List<Map<String, dynamic>> messages = []; Timer? poll; bool sending = false;
  @override void initState() { super.initState(); _load(); poll = Timer.periodic(const Duration(seconds: 4), (_) => _load()); }
  @override void dispose() { poll?.cancel(); textCtrl.dispose(); super.dispose(); }
  Future<void> _load() async { final c = OnlineService.client; final uid = OnlineService.authUserId; if (c == null || uid == null) return; try { final raw = await c.from('pilot_messages').select('id,sender_id,receiver_id,body,created_at').or('and(sender_id.eq.$uid,receiver_id.eq.${widget.userId}),and(sender_id.eq.${widget.userId},receiver_id.eq.$uid)').order('created_at'); if (mounted) setState(() => messages = List<Map<String, dynamic>>.from(raw)); } catch (e) { debugPrint('Chat poll error: $e'); } }
  Future<void> _send() async { final c = OnlineService.client; final uid = OnlineService.authUserId; final body = textCtrl.text.trim(); if (c == null || uid == null || body.isEmpty || sending) return; setState(() => sending = true); textCtrl.clear(); try { await c.from('pilot_messages').insert({'sender_id': uid, 'receiver_id': widget.userId, 'body': body}); await _load(); } catch (_) { if (mounted) textCtrl.text = body; } if (mounted) setState(() => sending = false); }
  @override Widget build(BuildContext context) => Scaffold(appBar: _bar(context, 'ЧАТ · ${widget.displayName}'), body: Column(children: [Expanded(child: ListView.builder(reverse: false, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (_, i) { final mine = messages[i]['sender_id'] == OnlineService.authUserId; return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.all(10), constraints: const BoxConstraints(maxWidth: 280), decoration: BoxDecoration(color: mine ? PO.panel2 : PO.panel, border: Border.all(color: mine ? PO.accent : PO.border), borderRadius: BorderRadius.circular(12)), child: Text(messages[i]['body']?.toString() ?? '', style: pixText(size: 11, color: PO.text)))); })), SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: textCtrl, maxLength: 280, style: pixText(size: 12), decoration: const InputDecoration(hintText: 'Сообщение...', counterText: '', border: OutlineInputBorder()))), IconButton(onPressed: sending ? null : _send, icon: const Icon(Icons.send, color: PO.accent))]))) ]));
}
