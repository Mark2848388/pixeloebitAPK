import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'content.dart';

class PlacedBuilding {
  final String id;
  final String defId;
  double x, y; // 0..1 normalized hangar
  int level;
  PlacedBuilding({required this.id, required this.defId, required this.x, required this.y, this.level = 1});

  Map<String, dynamic> toJson() => {'id': id, 'defId': defId, 'x': x, 'y': y, 'level': level};
  factory PlacedBuilding.fromJson(Map<String, dynamic> j) => PlacedBuilding(
        id: j['id'] as String,
        defId: j['defId'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        level: (j['level'] as int?) ?? 1,
      );
}

class PlayerProgress {
  int coins, gems, scrap, seasonXp, seasonLevel, highScore, endlessHigh, arenaWins, gamesPlayed;
  int campaignWorld, campaignStages, freeChests, baseLevel;
  bool premium;
  String activeHero, playerName, bio, activeCompanion, profilePhotoPath;
  Set<String> ownedHeroes, ownedSkins, ownedChars;
  Map<String, int> upgradeLv;
  List<String> friends;
  List<String> notifications;
  List<PlacedBuilding> hangar;
  Set<int> claimedSeason;
  DateTime? lastCollect;

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
    this.campaignStages = 0,
    this.freeChests = 2,
    this.baseLevel = 1,
    this.premium = false,
    this.activeHero = 'rex',
    this.playerName = 'Pilot',
    this.bio = '',
    this.activeCompanion = '',
    this.profilePhotoPath = '',
    Set<String>? ownedHeroes,
    Set<String>? ownedSkins,
    Set<String>? ownedChars,
    Map<String, int>? upgradeLv,
    List<String>? friends,
    List<String>? notifications,
    List<PlacedBuilding>? hangar,
    Set<int>? claimedSeason,
    this.lastCollect,
  })  : ownedHeroes = ownedHeroes ?? {'rex'},
        ownedSkins = ownedSkins ?? {'default'},
        ownedChars = ownedChars ?? {'c_pio'},
        upgradeLv = upgradeLv ?? {for (final u in upgrades) u.id: 0},
        friends = friends ?? [],
        notifications = notifications ?? [],
        hangar = hangar ?? [],
        claimedSeason = claimedSeason ?? {};

  HeroInfo get hero => heroes.firstWhere((h) => h.id == activeHero, orElse: () => heroes.first);
  bool worldUnlocked(int id) => id <= (campaignStages ~/ 10) + 1;
  bool worldCleared(int id) => id <= (campaignStages ~/ 10);
  /// Highest unlocked level in world (1..10). World must be unlocked.
  int unlockedLevelInWorld(int worldId) {
    final fully = campaignStages ~/ 10;
    if (worldId <= fully) return 10;
    if (worldId == fully + 1) return (campaignStages % 10) + 1;
    return 0;
  }
  bool levelUnlocked(int worldId, int level) {
    if (!worldUnlocked(worldId)) return false;
    return level <= unlockedLevelInWorld(worldId);
  }

  double get dmgMul {
    var m = 1 + (upgradeLv['dmg'] ?? 0) * 0.12;
    if (hangar.any((b) => b.defId == 'turret')) m += 0.08;
    return m;
  }

  double get rateMul => 1 - (upgradeLv['rate'] ?? 0) * 0.05;
  double get dashCdMul => 1 - (upgradeLv['dash'] ?? 0) * 0.1;
  double get ultCdMul => 1 - (upgradeLv['ult'] ?? 0) * 0.1;
  int get extraHull => upgradeLv['hull'] ?? 0;
  double get regenPerSec => (upgradeLv['regen'] ?? 0) * 0.15;

  void pushNote(String msg) {
    notifications.insert(0, msg);
    if (notifications.length > 40) notifications.removeLast();
  }

  void addScore(int score, {String mode = 'classic'}) {
    if (mode == 'endless') {
      if (score > endlessHigh) endlessHigh = score;
    } else if (score > highScore) {
      highScore = score;
    }
    gamesPlayed++;
    coins += (score / 10).floor().clamp(0, 600);
    scrap += (score / 35).floor().clamp(0, 40);
    addSeasonXp((score / 15).floor().clamp(1, 120));
  }

  void addSeasonXp(int xp) {
    seasonXp += xp;
    while (seasonLevel < 40 && seasonXp >= seasonLevel * 80) {
      seasonXp -= seasonLevel * 80;
      seasonLevel++;
      pushNote('Сезон: уровень $seasonLevel!');
    }
    if (seasonLevel > 40) seasonLevel = 40;
  }

  bool claimSeasonLevel(int lv) {
    if (lv > seasonLevel || claimedSeason.contains(lv)) return false;
    final reward = seasonTrack.firstWhere((r) => r.level == lv, orElse: () => SeasonReward(lv, '?'));
    coins += reward.coins;
    gems += reward.gems;
    scrap += reward.scrap;
    if (reward.charId != null) {
      ownedChars.add(reward.charId!);
      pushNote('Персонаж: ${reward.charId}');
    }
    claimedSeason.add(lv);
    pushNote('Сезон Lv$lv получен');
    return true;
  }

  void clearWorld(int id) {
    // legacy: treat as clearing full world
    final target = id * 10;
    if (campaignStages < target) {
      campaignStages = target;
      campaignWorld = id;
      freeChests += 2;
      coins += 80 + id * 25;
      gems += 2;
      scrap += 8 + id;
      pushNote('Мир $id пройден!');
      _unlockHeroes();
    }
  }

  void clearCampaignLevel(int worldId, int level) {
    final stageIndex = (worldId - 1) * 10 + level; // 1..100 when cleared
    if (stageIndex <= campaignStages) return;
    if (stageIndex > campaignStages + 1) return; // must be sequential
    campaignStages = stageIndex;
    campaignWorld = campaignStages ~/ 10;
    coins += 25 + worldId * 3 + level * 2;
    scrap += 3 + level ~/ 2;
    addSeasonXp(8 + level);
    if (level == 5) {
      freeChests++;
      pushNote('Мир $worldId ур.5 — босс!');
    }
    if (level == 10) {
      freeChests += 2;
      gems += 1;
      pushNote('Мир $worldId пройден!');
      _unlockHeroes();
    } else {
      pushNote('Мир $worldId — уровень $level');
    }
  }

  void _unlockHeroes() {
    final w = campaignStages ~/ 10;
    for (final h in heroes) {
      if (h.unlockWorld > 0 && h.unlockWorld <= w) {
        if (ownedHeroes.add(h.id)) pushNote('Герой: ${h.name}');
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

  /// Chest: roll character by rarity weights
  PixelChar? openCharacterChest() {
    if (freeChests <= 0) return null;
    freeChests--;
    final r = Random();
    final roll = r.nextDouble();
    CharRarity rarity;
    if (roll < 0.02) {
      rarity = CharRarity.legendary;
    } else if (roll < 0.12) {
      rarity = CharRarity.epic;
    } else if (roll < 0.40) {
      rarity = CharRarity.rare;
    } else {
      rarity = CharRarity.common;
    }
    final pool = pixelChars.where((c) => c.rarity == rarity && c.id != 'c_d56').toList();
    // D-56 only from season or tiny chance if legendary
    final use = pool.isEmpty ? pixelChars.where((c) => c.rarity == CharRarity.common).toList() : pool;
    final got = use[r.nextInt(use.length)];
    ownedChars.add(got.id);
    coins += 40 + r.nextInt(60);
    scrap += 5 + r.nextInt(15);
    pushNote('Сундук: ${got.name} (${rarityName(got.rarity)})');
    return got;
  }

  Map<String, int>? openFreeChest() {
    final ch = openCharacterChest();
    if (ch == null) return null;
    return {'coins': 40, 'gems': 0, 'scrap': 8};
  }

  bool placeBuilding(String defId, double x, double y) {
    BuildingDef? def;
    for (final b in buildings) {
      if (b.id == defId) def = b;
    }
    if (def == null) return false;
    if (coins < def.cost) return false;
    if (hangar.length >= 12) return false;
    coins -= def.cost;
    hangar.add(PlacedBuilding(id: 'b${DateTime.now().millisecondsSinceEpoch}', defId: defId, x: x.clamp(0.08, 0.92), y: y.clamp(0.15, 0.88)));
    pushNote('Постройка: ${def.name}');
    return true;
  }

  int collectHangarIncome() {
    final now = DateTime.now();
    final last = lastCollect ?? now.subtract(const Duration(minutes: 30));
    final hours = now.difference(last).inMinutes / 60.0;
    if (hours < 0.05) return 0;
    var gain = 0;
    for (final b in hangar) {
      BuildingDef? def;
      for (final d in buildings) {
        if (d.id == b.defId) def = d;
      }
      if (def == null) continue;
      gain += (def.coinsPerHour * hours * b.level).round();
    }
    gain = gain.clamp(0, 5000);
    coins += gain;
    lastCollect = now;
    if (gain > 0) pushNote('Ангар: +$gain C');
    return gain;
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
    await p.setInt('cstages', campaignStages);
    await p.setInt('fc', freeChests);
    await p.setInt('bl', baseLevel);
    await p.setBool('prem', premium);
    await p.setString('hero', activeHero);
    await p.setString('comp', activeCompanion);
    await p.setString('photo', profilePhotoPath);
    await p.setString('pname', playerName);
    await p.setString('bio', bio);
    await p.setStringList('heroes', ownedHeroes.toList());
    await p.setStringList('chars', ownedChars.toList());
    await p.setStringList('friends', friends);
    await p.setStringList('notes', notifications);
    await p.setStringList('season_claim', claimedSeason.map((e) => '$e').toList());
    await p.setString('hangar', jsonEncode(hangar.map((e) => e.toJson()).toList()));
    if (lastCollect != null) await p.setString('lastCollect', lastCollect!.toIso8601String());
    for (final e in upgradeLv.entries) {
      await p.setInt('up_${e.key}', e.value);
    }
  }

  static Future<PlayerProgress> load() async {
    final p = await SharedPreferences.getInstance();
    final up = <String, int>{};
    for (final u in upgrades) {
      up[u.id] = p.getInt('up_${u.id}') ?? 0;
    }
    List<PlacedBuilding> hangar = [];
    try {
      final raw = p.getString('hangar');
      if (raw != null) {
        hangar = (jsonDecode(raw) as List).map((e) => PlacedBuilding.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    final claimed = (p.getStringList('season_claim') ?? []).map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
    DateTime? last;
    final lc = p.getString('lastCollect');
    if (lc != null) last = DateTime.tryParse(lc);

    return PlayerProgress(
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
      campaignStages: p.getInt('cstages') ?? 0,
      freeChests: p.getInt('fc') ?? 2,
      baseLevel: p.getInt('bl') ?? 1,
      premium: p.getBool('prem') ?? false,
      activeHero: p.getString('hero') ?? 'rex',
      activeCompanion: p.getString('comp') ?? '',
      profilePhotoPath: p.getString('photo') ?? '',
      playerName: p.getString('pname') ?? 'Pilot',
      bio: p.getString('bio') ?? '',
      ownedHeroes: (p.getStringList('heroes') ?? ['rex']).toSet(),
      ownedChars: (p.getStringList('chars') ?? ['c_pio']).toSet(),
      friends: p.getStringList('friends') ?? [],
      notifications: p.getStringList('notes') ?? [],
      upgradeLv: up,
      hangar: hangar,
      claimedSeason: claimed,
      lastCollect: last,
    );
  }
}
