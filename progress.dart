import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'content.dart';

class SeasonReward {
  final int level;
  final String freeName;
  final String premiumName;
  final int freeCoins;
  final int premiumCoins;
  final bool freeSkin;
  final bool premiumSkin;
  const SeasonReward({
    required this.level,
    required this.freeName,
    required this.premiumName,
    this.freeCoins = 0,
    this.premiumCoins = 0,
    this.freeSkin = false,
    this.premiumSkin = false,
  });
}

const seasonRewards = <SeasonReward>[
  SeasonReward(level: 1, freeName: '50 монет', premiumName: '120 монет', freeCoins: 50, premiumCoins: 120),
  SeasonReward(level: 2, freeName: '30 монет', premiumName: '80 монет', freeCoins: 30, premiumCoins: 80),
  SeasonReward(level: 3, freeName: '70 монет', premiumName: 'Скин Neon', freeCoins: 70, premiumSkin: true),
  SeasonReward(level: 4, freeName: '40 монет', premiumName: '100 монет', freeCoins: 40, premiumCoins: 100),
  SeasonReward(level: 5, freeName: 'Скин Ember', premiumName: '200 монет', freeSkin: true, premiumCoins: 200),
  SeasonReward(level: 6, freeName: '60 монет', premiumName: '150 монет', freeCoins: 60, premiumCoins: 150),
  SeasonReward(level: 7, freeName: '80 монет', premiumName: '180 монет', freeCoins: 80, premiumCoins: 180),
  SeasonReward(level: 8, freeName: '50 монет', premiumName: 'Скин Void', freeCoins: 50, premiumSkin: true),
  SeasonReward(level: 9, freeName: '90 монет', premiumName: '220 монет', freeCoins: 90, premiumCoins: 220),
  SeasonReward(level: 10, freeName: '100 монет', premiumName: '300 монет', freeCoins: 100, premiumCoins: 300),
  SeasonReward(level: 11, freeName: '70 монет', premiumName: '160 монет', freeCoins: 70, premiumCoins: 160),
  SeasonReward(level: 12, freeName: '80 монет', premiumName: 'Скин Solar', freeCoins: 80, premiumSkin: true),
  SeasonReward(level: 13, freeName: '90 монет', premiumName: '200 монет', freeCoins: 90, premiumCoins: 200),
  SeasonReward(level: 14, freeName: '100 монет', premiumName: '240 монет', freeCoins: 100, premiumCoins: 240),
  SeasonReward(level: 15, freeName: 'Скин Nova', premiumName: '400 монет', freeSkin: true, premiumCoins: 400),
  SeasonReward(level: 16, freeName: '110 монет', premiumName: '260 монет', freeCoins: 110, premiumCoins: 260),
  SeasonReward(level: 17, freeName: '120 монет', premiumName: '280 монет', freeCoins: 120, premiumCoins: 280),
  SeasonReward(level: 18, freeName: '130 монет', premiumName: 'Скин Legend', freeCoins: 130, premiumSkin: true),
  SeasonReward(level: 19, freeName: '150 монет', premiumName: '350 монет', freeCoins: 150, premiumCoins: 350),
  SeasonReward(level: 20, freeName: '200 монет', premiumName: '500 + титул', freeCoins: 200, premiumCoins: 500),
];

class ShipSkin {
  final String id;
  final String name;
  final int price;
  final int color;
  const ShipSkin(this.id, this.name, this.price, this.color);
}

const shopSkins = <ShipSkin>[
  ShipSkin('default', 'Орбита', 0, 0xFF4A7AFF),
  ShipSkin('crimson', 'Багровый', 250, 0xFFFF3A4A),
  ShipSkin('void', 'Теневой', 400, 0xFF9B4DFF),
  ShipSkin('ember', 'Эмбер', 350, 0xFFFF8A3A),
  ShipSkin('neon', 'Неон', 500, 0xFF40FFC0),
  ShipSkin('solar', 'Солар', 600, 0xFFFFD34A),
  ShipSkin('nova', 'Нова', 800, 0xFFFF80D0),
];

class ChestResult {
  final int coins;
  final int gems;
  final String? skinId;
  ChestResult({required this.coins, this.gems = 0, this.skinId});
}

class PlayerProgress {
  int coins;
  int gems;
  int seasonXp;
  int seasonLevel;
  bool premium;
  int highScore;
  int endlessHigh;
  int gamesPlayed;
  Set<String> ownedSkins;
  String activeSkin;
  Set<int> claimedFree;
  Set<int> claimedPremium;
  /// Highest world cleared (0 = none)
  int campaignWorld;
  String activeHero;
  Set<String> ownedHeroes;
  int freeChests; // earned from campaign

  PlayerProgress({
    this.coins = 150,
    this.gems = 50,
    this.seasonXp = 0,
    this.seasonLevel = 1,
    this.premium = false,
    this.highScore = 0,
    this.endlessHigh = 0,
    this.gamesPlayed = 0,
    Set<String>? ownedSkins,
    this.activeSkin = 'default',
    Set<int>? claimedFree,
    Set<int>? claimedPremium,
    this.campaignWorld = 0,
    this.activeHero = 'rex',
    Set<String>? ownedHeroes,
    this.freeChests = 1,
  })  : ownedSkins = ownedSkins ?? {'default'},
        claimedFree = claimedFree ?? {},
        claimedPremium = claimedPremium ?? {},
        ownedHeroes = ownedHeroes ?? {'rex'};

  static const xpPerLevel = 100;
  int get xpIntoLevel => seasonXp % xpPerLevel;
  double get levelProgress => xpIntoLevel / xpPerLevel;

  bool worldUnlocked(int id) => id <= campaignWorld + 1;
  bool worldCleared(int id) => id <= campaignWorld;

  void addSeasonXp(int xp) {
    seasonXp += xp;
    while (seasonLevel < 20 && seasonXp >= seasonLevel * xpPerLevel) {
      seasonLevel++;
    }
    if (seasonLevel > 20) seasonLevel = 20;
  }

  void addScore(int score, {String mode = 'classic'}) {
    if (mode == 'endless') {
      if (score > endlessHigh) endlessHigh = score;
    } else if (mode != 'campaign') {
      if (score > highScore) highScore = score;
    }
    if (score > highScore) highScore = score;
    gamesPlayed++;
    coins += (score / 10).floor().clamp(0, 500);
    addSeasonXp((score / 20).floor().clamp(1, 80));
  }

  /// Called when campaign world boss is beaten.
  void clearWorld(int worldId) {
    if (worldId > campaignWorld) {
      campaignWorld = worldId;
      freeChests += 1;
      coins += 50 + worldId * 20;
      gems += worldId >= 5 ? 5 : 2;
      // unlock heroes tied to world
      for (final h in heroes) {
        if (h.unlockWorld > 0 && h.unlockWorld <= campaignWorld) {
          ownedHeroes.add(h.id);
        }
      }
    }
  }

  bool claimFree(int level) {
    if (level > seasonLevel || claimedFree.contains(level)) return false;
    final r = seasonRewards.firstWhere((e) => e.level == level);
    coins += r.freeCoins;
    if (r.freeSkin) ownedSkins.add('free_$level');
    claimedFree.add(level);
    return true;
  }

  bool claimPremium(int level) {
    if (!premium || level > seasonLevel || claimedPremium.contains(level)) return false;
    final r = seasonRewards.firstWhere((e) => e.level == level);
    coins += r.premiumCoins;
    if (r.premiumSkin) ownedSkins.add('prem_$level');
    claimedPremium.add(level);
    return true;
  }

  bool buyPremium() {
    if (premium) return false;
    if (gems >= 600) {
      gems -= 600;
    } else if (coins >= 600) {
      coins -= 600;
    } else {
      return false;
    }
    premium = true;
    return true;
  }

  bool buySkin(String id) {
    final skin = shopSkins.where((s) => s.id == id).firstOrNull;
    if (skin == null) return false;
    if (ownedSkins.contains(id)) {
      activeSkin = id;
      return true;
    }
    if (coins < skin.price) return false;
    coins -= skin.price;
    ownedSkins.add(id);
    activeSkin = id;
    return true;
  }

  bool selectHero(String id) {
    if (!ownedHeroes.contains(id)) return false;
    activeHero = id;
    return true;
  }

  HeroInfo get hero =>
      heroes.firstWhere((h) => h.id == activeHero, orElse: () => heroes.first);

  /// Open a chest. [free] uses freeChests counter.
  ChestResult? openChest(ChestDef def, {bool free = false}) {
    final rng = Random();
    if (free) {
      if (freeChests <= 0) return null;
      freeChests -= 1;
    } else {
      if (coins < def.priceCoins) return null;
      coins -= def.priceCoins;
    }
    final c = def.minCoins + rng.nextInt(def.maxCoins - def.minCoins + 1);
    coins += c;
    var g = 0;
    if (rng.nextInt(100) < def.gemChance) {
      g = 1 + rng.nextInt(5);
      gems += g;
    }
    String? skin;
    if (rng.nextInt(100) < def.skinChance) {
      final locked = shopSkins.where((s) => !ownedSkins.contains(s.id)).toList();
      if (locked.isNotEmpty) {
        skin = locked[rng.nextInt(locked.length)].id;
        ownedSkins.add(skin);
      }
    }
    return ChestResult(coins: c, gems: g, skinId: skin);
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', coins);
    await p.setInt('gems', gems);
    await p.setInt('sxp', seasonXp);
    await p.setInt('slv', seasonLevel);
    await p.setBool('prem', premium);
    await p.setInt('hi', highScore);
    await p.setInt('eh', endlessHigh);
    await p.setInt('gp', gamesPlayed);
    await p.setStringList('skins', ownedSkins.toList());
    await p.setString('skin', activeSkin);
    await p.setStringList('cf', claimedFree.map((e) => '$e').toList());
    await p.setStringList('cp', claimedPremium.map((e) => '$e').toList());
    await p.setInt('cw', campaignWorld);
    await p.setString('hero', activeHero);
    await p.setStringList('heroes', ownedHeroes.toList());
    await p.setInt('fchest', freeChests);
  }

  static Future<PlayerProgress> load() async {
    final p = await SharedPreferences.getInstance();
    return PlayerProgress(
      coins: p.getInt('coins') ?? 150,
      gems: p.getInt('gems') ?? 50,
      seasonXp: p.getInt('sxp') ?? 0,
      seasonLevel: p.getInt('slv') ?? 1,
      premium: p.getBool('prem') ?? false,
      highScore: p.getInt('hi') ?? 0,
      endlessHigh: p.getInt('eh') ?? 0,
      gamesPlayed: p.getInt('gp') ?? 0,
      ownedSkins: (p.getStringList('skins') ?? ['default']).toSet(),
      activeSkin: p.getString('skin') ?? 'default',
      claimedFree: (p.getStringList('cf') ?? []).map(int.parse).toSet(),
      claimedPremium: (p.getStringList('cp') ?? []).map(int.parse).toSet(),
      campaignWorld: p.getInt('cw') ?? 0,
      activeHero: p.getString('hero') ?? 'rex',
      ownedHeroes: (p.getStringList('heroes') ?? ['rex']).toSet(),
      freeChests: p.getInt('fchest') ?? 1,
    );
  }
}
