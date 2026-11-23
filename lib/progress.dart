import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'content.dart';

class PlayerProgress {
  int coins;
  int gems;
  int scrap; // upgrade currency from loot
  int seasonXp;
  int seasonLevel;
  bool premium;
  int highScore;
  int endlessHigh;
  int arenaWins;
  int gamesPlayed;
  Set<String> ownedSkins;
  String activeSkin;
  int campaignWorld;
  String activeHero;
  Set<String> ownedHeroes;
  int freeChests;
  Map<String, int> upgradeLv; // dmg, rate, dash, ult, hull
  int baseLevel; // base building 0-10
  int basePower;
  List<String> friends; // local list of names
  String playerName;

  PlayerProgress({
    this.coins = 200,
    this.gems = 30,
    this.scrap = 0,
    this.seasonXp = 0,
    this.seasonLevel = 1,
    this.premium = false,
    this.highScore = 0,
    this.endlessHigh = 0,
    this.arenaWins = 0,
    this.gamesPlayed = 0,
    Set<String>? ownedSkins,
    this.activeSkin = 'default',
    this.campaignWorld = 0,
    this.activeHero = 'rex',
    Set<String>? ownedHeroes,
    this.freeChests = 1,
    Map<String, int>? upgradeLv,
    this.baseLevel = 1,
    this.basePower = 0,
    List<String>? friends,
    this.playerName = 'Pilot',
  })  : ownedSkins = ownedSkins ?? {'default'},
        ownedHeroes = ownedHeroes ?? {'rex'},
        upgradeLv = upgradeLv ?? {'dmg': 0, 'rate': 0, 'dash': 0, 'ult': 0, 'hull': 0},
        friends = friends ?? [];

  static const xpPerLevel = 100;
  int get xpIntoLevel => seasonXp % xpPerLevel;
  double get levelProgress => xpIntoLevel / xpPerLevel;

  bool worldUnlocked(int id) => id <= campaignWorld + 1;
  bool worldCleared(int id) => id <= campaignWorld;

  HeroInfo get hero => heroes.firstWhere((h) => h.id == activeHero, orElse: () => heroes.first);

  double get dmgMul => 1 + (upgradeLv['dmg'] ?? 0) * 0.12;
  double get rateMul => 1 - (upgradeLv['rate'] ?? 0) * 0.05; // lower = faster cooldown
  double get dashCdMul => 1 - (upgradeLv['dash'] ?? 0) * 0.1;
  double get ultCdMul => 1 - (upgradeLv['ult'] ?? 0) * 0.1;
  int get extraHull => upgradeLv['hull'] ?? 0;

  void addSeasonXp(int xp) {
    seasonXp += xp;
    while (seasonLevel < 30 && seasonXp >= seasonLevel * xpPerLevel) {
      seasonLevel++;
    }
  }

  void addScore(int score, {String mode = 'classic', double rewardMul = 1}) {
    if (mode == 'endless') {
      if (score > endlessHigh) endlessHigh = score;
    } else if (score > highScore) {
      highScore = score;
    }
    gamesPlayed++;
    coins += ((score / 10) * rewardMul).floor().clamp(0, 800);
    scrap += (score / 40).floor().clamp(0, 30);
    addSeasonXp(((score / 18) * rewardMul).floor().clamp(1, 100));
  }

  void clearWorld(int worldId) {
    if (worldId > campaignWorld) {
      campaignWorld = worldId;
      freeChests += 1;
      coins += 80 + worldId * 25;
      gems += 2 + (worldId ~/ 3);
      scrap += 10 + worldId * 2;
      for (final h in heroes) {
        if (h.unlockWorld > 0 && h.unlockWorld <= campaignWorld) {
          ownedHeroes.add(h.id);
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
    final u = upgrades.where((e) => e.id == id)?.;
    if (u == null) return false;
    final lv = upgradeLv[id] ?? 0;
    if (lv >= u.maxLevel) return false;
    final cost = u.baseCost * (lv + 1);
    if (scrap < cost && coins < cost * 2) return false;
    if (scrap >= cost) {
      scrap -= cost;
    } else {
      coins -= cost * 2;
    }
    upgradeLv[id] = lv + 1;
    return true;
  }

  bool upgradeBase() {
    if (baseLevel >= 10) return false;
    final cost = 150 * baseLevel;
    if (coins < cost) return false;
    coins -= cost;
    baseLevel++;
    basePower += 10;
    return true;
  }

  void addFriend(String name) {
    final n = name.trim();
    if (n.isEmpty || friends.contains(n)) return;
    friends.add(n);
    if (friends.length > 20) friends.removeAt(0);
  }

  /// Chest open
  Map<String, int>? openFreeChest() {
    if (freeChests <= 0) return null;
    freeChests--;
    final rng = Random();
    final c = 40 + rng.nextInt(100);
    final g = rng.nextInt(100) < 25 ? 1 + rng.nextInt(4) : 0;
    final s = 5 + rng.nextInt(20);
    coins += c;
    gems += g;
    scrap += s;
    return {'coins': c, 'gems': g, 'scrap': s};
  }

  Map<String, int>? buyChest(int price, int minC, int maxC) {
    if (coins < price) return null;
    coins -= price;
    final rng = Random();
    final c = minC + rng.nextInt(maxC - minC + 1);
    final g = rng.nextInt(100) < 20 ? 1 + rng.nextInt(5) : 0;
    final s = 8 + rng.nextInt(25);
    coins += c;
    gems += g;
    scrap += s;
    return {'coins': c, 'gems': g, 'scrap': s};
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', coins);
    await p.setInt('gems', gems);
    await p.setInt('scrap', scrap);
    await p.setInt('sxp', seasonXp);
    await p.setInt('slv', seasonLevel);
    await p.setBool('prem', premium);
    await p.setInt('hi', highScore);
    await p.setInt('eh', endlessHigh);
    await p.setInt('aw', arenaWins);
    await p.setInt('gp', gamesPlayed);
    await p.setStringList('skins', ownedSkins.toList());
    await p.setString('skin', activeSkin);
    await p.setInt('cw', campaignWorld);
    await p.setString('hero', activeHero);
    await p.setStringList('heroes', ownedHeroes.toList());
    await p.setInt('fchest', freeChests);
    await p.setInt('bl', baseLevel);
    await p.setInt('bp', basePower);
    await p.setStringList('friends', friends);
    await p.setString('pname', playerName);
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
    return PlayerProgress(
      coins: p.getInt('coins') ?? 200,
      gems: p.getInt('gems') ?? 30,
      scrap: p.getInt('scrap') ?? 0,
      seasonXp: p.getInt('sxp') ?? 0,
      seasonLevel: p.getInt('slv') ?? 1,
      premium: p.getBool('prem') ?? false,
      highScore: p.getInt('hi') ?? 0,
      endlessHigh: p.getInt('eh') ?? 0,
      arenaWins: p.getInt('aw') ?? 0,
      gamesPlayed: p.getInt('gp') ?? 0,
      ownedSkins: (p.getStringList('skins') ?? ['default']).toSet(),
      activeSkin: p.getString('skin') ?? 'default',
      campaignWorld: p.getInt('cw') ?? 0,
      activeHero: p.getString('hero') ?? 'rex',
      ownedHeroes: (p.getStringList('heroes') ?? ['rex']).toSet(),
      freeChests: p.getInt('fchest') ?? 1,
      upgradeLv: up,
      baseLevel: p.getInt('bl') ?? 1,
      basePower: p.getInt('bp') ?? 0,
      friends: p.getStringList('friends') ?? [],
      playerName: p.getString('pname') ?? 'Pilot',
    );
  }
}
