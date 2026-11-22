import 'package:shared_preferences/shared_preferences.dart';

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
  SeasonReward(level: 20, freeName: '200 монет', premiumName: '500 монет + титул', freeCoins: 200, premiumCoins: 500),
];

class PlayerProgress {
  int coins;
  int gems;
  int seasonXp;
  int seasonLevel;
  bool premium;
  int highScore;
  int gamesPlayed;
  Set<String> ownedSkins;
  String activeSkin;
  Set<int> claimedFree;
  Set<int> claimedPremium;

  PlayerProgress({
    this.coins = 100,
    this.gems = 0,
    this.seasonXp = 0,
    this.seasonLevel = 1,
    this.premium = false,
    this.highScore = 0,
    this.gamesPlayed = 0,
    Set<String>? ownedSkins,
    this.activeSkin = 'default',
    Set<int>? claimedFree,
    Set<int>? claimedPremium,
  })  : ownedSkins = ownedSkins ?? {'default'},
        claimedFree = claimedFree ?? {},
        claimedPremium = claimedPremium ?? {};

  static const xpPerLevel = 100;

  int get xpIntoLevel => seasonXp % xpPerLevel;
  double get levelProgress => xpIntoLevel / xpPerLevel;

  void addSeasonXp(int xp) {
    seasonXp += xp;
    while (seasonLevel < 20 && seasonXp >= seasonLevel * xpPerLevel) {
      seasonLevel++;
    }
    if (seasonLevel > 20) seasonLevel = 20;
  }

  void addScore(int score) {
    if (score > highScore) highScore = score;
    gamesPlayed++;
    coins += (score / 10).floor().clamp(0, 500);
    addSeasonXp((score / 20).floor().clamp(1, 80));
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
    if (gems < 600 && coins < 600) return false;
    if (gems >= 600) {
      gems -= 600;
    } else {
      coins -= 600;
    }
    premium = true;
    return true;
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('coins', coins);
    await p.setInt('gems', gems);
    await p.setInt('sxp', seasonXp);
    await p.setInt('slv', seasonLevel);
    await p.setBool('prem', premium);
    await p.setInt('hi', highScore);
    await p.setInt('gp', gamesPlayed);
    await p.setStringList('skins', ownedSkins.toList());
    await p.setString('skin', activeSkin);
    await p.setStringList('cf', claimedFree.map((e) => '$e').toList());
    await p.setStringList('cp', claimedPremium.map((e) => '$e').toList());
  }

  static Future<PlayerProgress> load() async {
    final p = await SharedPreferences.getInstance();
    return PlayerProgress(
      coins: p.getInt('coins') ?? 100,
      gems: p.getInt('gems') ?? 50,
      seasonXp: p.getInt('sxp') ?? 0,
      seasonLevel: p.getInt('slv') ?? 1,
      premium: p.getBool('prem') ?? false,
      highScore: p.getInt('hi') ?? 0,
      gamesPlayed: p.getInt('gp') ?? 0,
      ownedSkins: (p.getStringList('skins') ?? ['default']).toSet(),
      activeSkin: p.getString('skin') ?? 'default',
      claimedFree: (p.getStringList('cf') ?? []).map(int.parse).toSet(),
      claimedPremium: (p.getStringList('cp') ?? []).map(int.parse).toSet(),
    );
  }
}
