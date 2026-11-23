import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'online.dart';
import 'content.dart';

class PlayerProgress {
  int coins, gems, scrap, seasonXp, seasonLevel, highScore, endlessHigh, arenaWins, gamesPlayed;
  int campaignWorld, freeChests, baseLevel;
  bool premium;
  String activeHero, playerName, bio;
  Set<String> ownedHeroes, ownedSkins;
  Map<String, int> upgradeLv;
  List<String> friends;
  List<String> notifications; // recent in-app

  PlayerProgress({
    this.coins = 220,
    this.gems = 40,
    this.scrap = 10,
    this.seasonXp = 0,
    this.seasonLevel = 1,
    this.highScore = 0,
    this.endlessHigh = 0,
    this.arenaWins = 0,
    this.gamesPlayed = 0,
    this.campaignWorld = 0,
    this.freeChests = 1,
    this.baseLevel = 1,
    this.premium = false,
    this.activeHero = 'rex',
    this.playerName = 'Pilot',
    this.bio = '',
    Set<String>? ownedHeroes,
    Set<String>? ownedSkins,
    Map<String, int>? upgradeLv,
    List<String>? friends,
    List<String>? notifications,
  })  : ownedHeroes = ownedHeroes ?? {'rex'},
        ownedSkins = ownedSkins ?? {'default'},
        upgradeLv = upgradeLv ?? {for (final u in upgrades) u.id: 0},
        friends = friends ?? [],
        notifications = notifications ?? [];

  HeroInfo get hero => heroes.firstWhere((h) => h.id == activeHero, orElse: () => heroes.first);
  bool worldUnlocked(int id) => id <= campaignWorld + 1;
  bool worldCleared(int id) => id <= campaignWorld;

  double get dmgMul => 1 + (upgradeLv['dmg'] ?? 0) * 0.12;
  double get rateMul => 1 - (upgradeLv['rate'] ?? 0) * 0.05;
  double get dashCdMul => 1 - (upgradeLv['dash'] ?? 0) * 0.1;
  double get ultCdMul => 1 - (upgradeLv['ult'] ?? 0) * 0.1;
  int get extraHull => upgradeLv['hull'] ?? 0;
  double get regenPerSec => (upgradeLv['regen'] ?? 0) * 0.15; // HP units per sec toward max lives display

  void pushNote(String msg) {
    notifications.insert(0, msg);
    if (notifications.length > 30) notifications.removeLast();
  }

  void addScore(int score, {String mode = 'classic'}) {
    if (mode == 'endless') {
      if (score > endlessHigh) endlessHigh = score;
    } else if (score > highScore) highScore = score;
    gamesPlayed++;
    coins += (score / 10).floor().clamp(0, 600).toInt();
    scrap += (score / 35).floor().clamp(0, 40).toInt();
    seasonXp += (score / 18).floor().clamp(1, 100).toInt();
    while (seasonLevel < 30 && seasonXp >= seasonLevel * 100) {
      seasonLevel++;
      pushNote('Сезон: уровень $seasonLevel!');
    }
  }

  void clearWorld(int id) {
    if (id > campaignWorld) {
      campaignWorld = id;
      freeChests++;
      coins += 80 + id * 25;
      gems += 2;
      scrap += 8 + id;
      pushNote('Мир $id пройден! +сундук');
      for (final h in heroes) {
        if (h.unlockWorld > 0 && h.unlockWorld <= campaignWorld) {
          if (ownedHeroes.add(h.id)) pushNote('Герой открыт: ${h.name}');
        }
      }
    }
  }

  bool selectHero(String id) {
    if (!ownedHeroes.contains(id)) return false;
    activeHero = id;
    return true;
  }

  bool buyUpgrade(String id) {
    UpgradeDef? u;
    for (final e in upgrades) {
      if (e.id == id) u = e;
    }
    if (u == null) return false;
    final lv = upgradeLv[id] ?? 0;
    if (lv >= u.maxLevel) return false;
    final cost = u.baseCost * (lv + 1);
    if (scrap >= cost) {
      scrap -= cost;
    } else if (coins >= cost * 2) {
      coins -= cost * 2;
    } else {
      return false;
    }
    upgradeLv[id] = lv + 1;
    pushNote('${u.name} → ${lv + 1}');
    return true;
  }

  bool upgradeBase() {
    if (baseLevel >= 10) return false;
    final cost = 150 * baseLevel;
    if (coins < cost) return false;
    coins -= cost;
    baseLevel++;
    pushNote('База ур. $baseLevel');
    return true;
  }

  Map<String, int>? openFreeChest() {
    if (freeChests <= 0) return null;
    freeChests--;
    final r = Random();
    final c = 50 + r.nextInt(90);
    final g = r.nextInt(100) < 30 ? 1 + r.nextInt(4) : 0;
    final s = 8 + r.nextInt(20);
    coins += c;
    gems += g;
    scrap += s;
    pushNote('Сундук: +$c C, +$s S');
    return {'coins': c, 'gems': g, 'scrap': s};
  }

  void addFriend(String n) {
    n = n.trim();
    if (n.isEmpty || friends.contains(n)) return;
    friends.add(n);
    pushNote('Друг: $n');
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', coins);
    await p.setInt('gems', gems);
    await p.setInt('scrap', scrap);
    await p.setInt('sxp', seasonXp);
    await p.setInt('slv', seasonLevel);
    await p.setInt('hi', highScore);
    await p.setInt('eh', endlessHigh);
    await p.setInt('aw', arenaWins);
    await p.setInt('gp', gamesPlayed);
    await p.setInt('cw', campaignWorld);
    await p.setInt('fc', freeChests);
    await p.setInt('bl', baseLevel);
    await p.setBool('prem', premium);
    await p.setString('hero', activeHero);
    await p.setString('pname', playerName);
    await p.setString('bio', bio);
    await p.setStringList('heroes', ownedHeroes.toList());
    await p.setStringList('friends', friends);
    await p.setStringList('notes', notifications);
    for (final e in upgradeLv.entries) {
      await p.setInt('up_${e.key}', e.value);
    }
    final savedAt = DateTime.now().toUtc();
    await p.setString('po_local_saved_at', savedAt.toIso8601String());
    OnlineService.queueCloudSave(toJson());
  }

  Map<String, dynamic> toJson() => {
    'coins': coins, 'gems': gems, 'scrap': scrap, 'seasonXp': seasonXp, 'seasonLevel': seasonLevel,
    'highScore': highScore, 'endlessHigh': endlessHigh, 'arenaWins': arenaWins, 'gamesPlayed': gamesPlayed,
    'campaignWorld': campaignWorld, 'freeChests': freeChests, 'baseLevel': baseLevel, 'premium': premium,
    'activeHero': activeHero, 'playerName': playerName, 'bio': bio, 'ownedHeroes': ownedHeroes.toList(),
    'ownedSkins': ownedSkins.toList(), 'upgradeLv': upgradeLv, 'friends': friends, 'notifications': notifications,
  };

  static PlayerProgress fromJson(Map<String, dynamic> j) {
    int n(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    return PlayerProgress(
      coins: n('coins', 220), gems: n('gems', 40), scrap: n('scrap', 10), seasonXp: n('seasonXp', 0), seasonLevel: n('seasonLevel', 1),
      highScore: n('highScore', 0), endlessHigh: n('endlessHigh', 0), arenaWins: n('arenaWins', 0), gamesPlayed: n('gamesPlayed', 0), campaignWorld: n('campaignWorld', 0),
      freeChests: n('freeChests', 1), baseLevel: n('baseLevel', 1), premium: j['premium'] == true, activeHero: j['activeHero']?.toString() ?? 'rex',
      playerName: j['playerName']?.toString() ?? 'Pilot', bio: j['bio']?.toString() ?? '',
      ownedHeroes: (j['ownedHeroes'] as List?)?.map((e) => e.toString()).toSet() ?? {'rex'},
      ownedSkins: (j['ownedSkins'] as List?)?.map((e) => e.toString()).toSet() ?? {'default'},
      upgradeLv: (j['upgradeLv'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {for (final u in upgrades) u.id: 0},
      friends: (j['friends'] as List?)?.map((e) => e.toString()).toList() ?? [],
      notifications: (j['notifications'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static Future<PlayerProgress> load() async {
    final p = await SharedPreferences.getInstance();
    final up = <String, int>{};
    for (final u in upgrades) {
      up[u.id] = p.getInt('up_${u.id}') ?? 0;
    }
    final local = PlayerProgress(
      coins: p.getInt('coins') ?? 220,
      gems: p.getInt('gems') ?? 40,
      scrap: p.getInt('scrap') ?? 10,
      seasonXp: p.getInt('sxp') ?? 0,
      seasonLevel: p.getInt('slv') ?? 1,
      highScore: p.getInt('hi') ?? 0,
      endlessHigh: p.getInt('eh') ?? 0,
      arenaWins: p.getInt('aw') ?? 0,
      gamesPlayed: p.getInt('gp') ?? 0,
      campaignWorld: p.getInt('cw') ?? 0,
      freeChests: p.getInt('fc') ?? 1,
      baseLevel: p.getInt('bl') ?? 1,
      premium: p.getBool('prem') ?? false,
      activeHero: p.getString('hero') ?? 'rex',
      playerName: p.getString('pname') ?? 'Pilot',
      bio: p.getString('bio') ?? '',
      ownedHeroes: (p.getStringList('heroes') ?? ['rex']).toSet(),
      friends: p.getStringList('friends') ?? [],
      notifications: p.getStringList('notes') ?? [],
      upgradeLv: up,
    );
    // Use the cloud copy only when it is newer than this device's local save.
    final cloud = await OnlineService.loadCloudSave();
    if (cloud != null) {
      final cloudTime = DateTime.tryParse(cloud['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      var localTime = DateTime.tryParse(p.getString('po_local_saved_at') ?? '');
      if (localTime == null) {
        // Existing installs from v2.1 have prefs but no timestamp; protect those
        // local saves from an older cloud snapshot on first upgrade.
        final hasLocalData = p.containsKey('coins') || p.containsKey('pname') || p.containsKey('hi');
        localTime = hasLocalData ? DateTime.now().toUtc() : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        if (hasLocalData) await p.setString('po_local_saved_at', localTime.toIso8601String());
      }
      if (cloudTime.isAfter(localTime)) {
        final restored = PlayerProgress.fromJson(Map<String, dynamic>.from(cloud['data'] as Map));
        await restored.save();
        return restored;
      }
    }
    return local;
  }
}
